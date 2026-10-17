-- It Takes Two respawn (user, Oct 11: "exactly It Takes Two, just spam revive"): while Downed, a radial meter
-- fills on its own and every mash press (SPACE / A / click / tap) fills it faster. Your meter sits mid-screen with
-- the key to mash pulsing in the middle; the partner sees the same meter over your ghost. A pop when you're back.
-- The timer itself lives on the server (HealthService: RespawnAt / RespawnTotal / MashCount attributes).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Net = require(ReplicatedStorage.Shared.Net)
local Roles = require(ReplicatedStorage.Shared.Config.Roles)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Glyphs = require(ReplicatedStorage.Shared.Util.Glyphs)
local UiFit = require(ReplicatedStorage.Shared.Util.UiFit)
local UiSkin = require(ReplicatedStorage.Shared.Util.UiSkin)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)

local player = Players.LocalPlayer
local T = Tuning.ReviveMeter

local ReviveController = {}

local UNLIT = Color3.fromRGB(30, 30, 45)

local function new(className: string, props: { [string]: any }, parent: Instance?): any
	local inst = Instance.new(className)
	for k, v in props do
		(inst :: any)[k] = v
	end
	inst.Parent = parent
	return inst
end

local function roleColor(p: Player): Color3
	local info = (Roles :: any)[p:GetAttribute("Role") or ""]
	return if info then info.Color else Palette.Duo
end

-- 0 → 1 as the respawn timer runs out (the server pushes RespawnAt every 0.1 s, mashing pulls it closer)
local function progressOf(p: Player): number
	local at = p:GetAttribute("RespawnAt") :: number?
	local total = p:GetAttribute("RespawnTotal") :: number?
	if not (at and total and total > 0) then
		return 0
	end
	return math.clamp(1 - (at - workspace:GetServerTimeNow()) / total, 0, 1)
end

type Ring = { frame: Frame, segs: { Frame }, shown: number }

-- A ring of rounded segments (reads as a radial meter without an image asset; works in a BillboardGui too).
local function makeRing(parent: Instance, zIndex: number): Ring
	local frame = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = zIndex,
	}, parent)
	local segs = {}
	for i = 1, T.Segments do
		local a = (i - 0.5) / T.Segments * math.pi * 2
		local seg = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + 0.42 * math.sin(a), 0.5 - 0.42 * math.cos(a)),
			Size = UDim2.fromScale(0.07, 0.16),
			Rotation = math.deg(a),
			BackgroundColor3 = UNLIT,
			BorderSizePixel = 0,
			ZIndex = zIndex,
		}, frame)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, seg)
		segs[i] = seg
	end
	return { frame = frame, segs = segs, shown = 0 }
end

-- Eases the shown fill toward the real progress (the server value steps in 0.1 s ticks and mash jumps).
local function paintRing(ring: Ring, progress: number, color: Color3, dt: number)
	ring.shown += (progress - ring.shown) * math.min(1, dt * 14)
	if progress < ring.shown then
		ring.shown = progress -- a fresh downing starts from empty
	end
	local lit = ring.shown * T.Segments
	for i, seg in ring.segs do
		local f = math.clamp(lit - (i - 1), 0, 1)
		seg.BackgroundColor3 = UNLIT:Lerp(color, f)
		seg.BackgroundTransparency = 0.35 * (1 - f)
	end
end

local function pulse(scale: UIScale)
	scale.Scale = T.PulseScale
	TweenService:Create(scale, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1 })
		:Play()
end

local function mashKey(): string
	return Glyphs.key("Mash") -- SPACE / A / TAP
end

-- Your own meter, mid-screen --------------------------------------------------------------------------------
local function buildOwn(gui: ScreenGui)
	local root = new("Frame", {
		Name = "Respawn",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.62),
		Size = UDim2.fromOffset(T.ScreenSize, T.ScreenSize),
		BackgroundTransparency = 1,
		Visible = false,
		ZIndex = 9,
	}, gui)
	local rootScale = new("UIScale", {}, root)
	local ring = makeRing(root, 10)

	local key = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.5, 0.26),
		TextScaled = true,
		ZIndex = 11,
	}, root)
	UiSkin.Panel(key, { NoShadow = true })
	UiSkin.Text(key, "Title")
	new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, key)
	local keyScale = new("UIScale", {}, key)

	local label = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 6),
		Size = UDim2.fromOffset(360, 34),
		BackgroundTransparency = 1,
		TextScaled = true,
		Text = "MASH TO RESPAWN",
		ZIndex = 11,
	}, root)
	UiSkin.Text(label, "Float")

	local mashEvent = Net.event("RespawnMash")
	local function onMash()
		if not player:GetAttribute("Downed") or workspace:GetAttribute("GameOver") then
			return
		end
		mashEvent:FireServer()
		pulse(keyScale)
		Audio.play("Click")
	end
	UserInputService.InputBegan:Connect(function(input, processed)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.Touch then
			onMash() -- the jump button counts too (processed by the touch UI)
		elseif processed or UserInputService:GetFocusedTextBox() then
			return
		elseif
			input.KeyCode == Enum.KeyCode.Space
			or input.KeyCode == Enum.KeyCode.ButtonA
			or kind == Enum.UserInputType.MouseButton1
		then
			onMash()
		end
	end)

	local wasDowned = false
	RunService.RenderStepped:Connect(function(dt)
		-- game over (both down): no meter, the GAME OVER screen restarts you (user, Oct 17)
		if workspace:GetAttribute("GameOver") then
			root.Visible = false
			wasDowned = false
			return
		end
		local downed = player:GetAttribute("Downed") == true
		if downed then
			if not wasDowned then
				ring.shown = 0
				rootScale.Scale = 1
				root.Visible = true
			end
			key.Text = mashKey()
			paintRing(ring, progressOf(player), roleColor(player), dt)
		elseif wasDowned then
			-- back: the ring fills, pops outward and vanishes
			paintRing(ring, 1, roleColor(player), 1) -- the Revive sound comes from the server (3D, both hear it)
			local pop = TweenService:Create(
				rootScale,
				TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = T.PopScale }
			)
			pop:Play()
			task.delay(0.28, function()
				if not player:GetAttribute("Downed") then
					root.Visible = false
				end
			end)
		end
		wasDowned = downed
	end)
end

-- The same meter over every other downed player's ghost (studs-sized, like the HP bars) --------------------------
local function buildOverhead(gui: ScreenGui)
	local bills: { [Player]: { bill: BillboardGui, ring: Ring, scale: UIScale } } = {}
	local function watch(p: Player)
		if p == player then
			return
		end
		local bill = new("BillboardGui", {
			Name = "RespawnOver",
			Size = UDim2.fromScale(T.OverheadSize, T.OverheadSize),
			StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0),
			AlwaysOnTop = true,
			LightInfluence = 0,
			Enabled = false,
		}, gui)
		local holder = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, bill)
		local scale = new("UIScale", {}, holder)
		local entry = { bill = bill, ring = makeRing(holder, 1), scale = scale }
		bills[p] = entry
		p:GetAttributeChangedSignal("MashCount"):Connect(function()
			if bill.Enabled then
				pulse(scale)
			end
		end)
	end
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(function(p)
		local entry = bills[p]
		if entry then
			entry.bill:Destroy()
			bills[p] = nil
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		for p, entry in bills do
			local head = p.Character and p.Character:FindFirstChild("Head")
			local downed = p:GetAttribute("Downed") == true and head ~= nil and not workspace:GetAttribute("GameOver")
			if downed and not entry.bill.Enabled then
				entry.ring.shown = 0
			end
			entry.bill.Enabled = downed
			if downed then
				entry.bill.Adornee = head :: BasePart
				paintRing(entry.ring, progressOf(p), roleColor(p), dt)
			end
		end
	end)
end

function ReviveController.Init()
	local gui = new("ScreenGui", {
		Name = "Respawn",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
	}, player:WaitForChild("PlayerGui"))
	UiFit.attach(gui) -- the meter shrinks on phones, grows on a TV
	buildOwn(gui)
	buildOverhead(gui)
end

return ReviveController
