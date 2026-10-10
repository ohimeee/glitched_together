-- Floppy-disk save points (ArtService/GlitchedCore savePoints tags the holder "SaveDisk"; Prologue + Glitched Core).
-- The checkpoint pad is a big disk lying face-up in the floor (holder local -Z = up, +X = along the shutter's slide).
-- Under its metal shutter sits a drive window, dark until the first save. When its checkpoint saves (the server
-- stamps `SavedAt`) the shutter slides open on the window lighting green, "SAVED!" pops, and the shutter springs
-- back; the window stays green. Purely visual and local.
-- Parts are tracked as they arrive (StreamingEnabled can deliver the holder before its meshes).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)

local SaveDiskController = {}

local SHUTTER = { ShutterL = true, ShutterR = true, ShutterB = true, ShutterT = true }
local LIGHT_OFF = Color3.fromRGB(28, 32, 40)
local LIGHT_ON = Color3.fromRGB(90, 255, 120)
local KIT_WIDTH = 5.8 -- the kit's design width (GlitchedCore KIT.SavePoint): scale = holder width / this
local SLIDE = 1.1 -- kit studs the shutter slides open (stays on the disk)
local OPEN, HOLD, CLOSE = 0.22, 0.9, 0.3 -- s

type Disk = {
	parts: { [BasePart]: CFrame }, -- shutter pieces, relative to the holder
	savedAt: number, -- os.clock() of the last save, -inf before
	window: Part?,
	conns: { RBXScriptConnection },
}
local disks: { [BasePart]: Disk } = {}

local function popText(holder: BasePart)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(150, 44)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Adornee = holder
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = LIGHT_ON
	label.TextStrokeColor3 = Color3.fromRGB(20, 24, 30)
	label.TextStrokeTransparency = 0
	label.Text = "SAVED!"
	label.Parent = gui
	local scale = Instance.new("UIScale")
	scale.Scale = 0.3
	scale.Parent = label
	gui.Parent = holder
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(gui, TweenInfo.new(1.6, Enum.EasingStyle.Quad), {
		StudsOffsetWorldSpace = gui.StudsOffsetWorldSpace + Vector3.new(0, 1.5, 0),
	}):Play()
	task.delay(1.2, function()
		TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
	task.delay(1.7, function()
		gui:Destroy()
	end)
end

-- the drive window under the shutter: a flat neon pane on the disk's face, covered while the shutter is shut
local function makeWindow(holder: BasePart, shutter: BasePart): Part
	local window = Instance.new("Part")
	window.Name = "DriveWindow"
	window.Anchored = true
	window.CanCollide = false
	window.CanQuery = false
	window.CanTouch = false
	window.Material = Enum.Material.Neon
	window.Color = LIGHT_OFF
	local local_ = holder.CFrame:ToObjectSpace(shutter.CFrame)
	window.Size = Vector3.new(shutter.Size.X * 0.7, shutter.Size.Y * 0.8, 0.02)
	-- on the body's face (kit: body 0.35 thick, shutter 0.39), under the shutter that stands proud of it
	local body = shutter.Size.Z * 0.35 / 0.39
	window.CFrame = holder.CFrame * local_ * CFrame.new(0, 0, -body / 2 - 0.012)
	window.Parent = holder
	return window
end

local function track(holder: BasePart)
	local disk: Disk = { parts = {}, savedAt = -math.huge, conns = {} }
	local function add(p: Instance)
		if not p:IsA("BasePart") or not SHUTTER[p.Name] then
			return
		end
		disk.parts[p] = holder.CFrame:ToObjectSpace(p.CFrame)
		if p.Name == "ShutterL" and not disk.window then
			local window = makeWindow(holder, p)
			disk.window = window
			if disk.savedAt > -math.huge then
				window.Color = LIGHT_ON
			end
		end
	end
	for _, p in holder:GetChildren() do
		add(p)
	end
	table.insert(disk.conns, holder.ChildAdded:Connect(add))
	table.insert(
		disk.conns,
		holder.ChildRemoved:Connect(function(p)
			disk.parts[p :: BasePart] = nil
		end)
	)
	local function onSaved(animate: boolean)
		if not holder:GetAttribute("SavedAt") then
			return
		end
		disk.savedAt = if animate then os.clock() else os.clock() - (OPEN + HOLD + CLOSE)
		if animate then
			popText(holder)
		end
		if disk.window then
			disk.window.Color = LIGHT_ON
		end
	end
	table.insert(
		disk.conns,
		holder:GetAttributeChangedSignal("SavedAt"):Connect(function()
			onSaved(true)
		end)
	)
	onSaved(false)
	disks[holder] = disk
end

local function untrack(holder: BasePart)
	local disk = disks[holder]
	if disk then
		for _, c in disk.conns do
			c:Disconnect()
		end
		if disk.window then
			disk.window:Destroy()
		end
		disks[holder] = nil
	end
end

-- 0 = shut, 1 = open: snaps open, holds, springs back with a small overshoot
local function shutterOpen(t: number): number
	if t < 0 then
		return 0
	elseif t < OPEN then
		return math.sin(t / OPEN * math.pi / 2)
	elseif t < OPEN + HOLD then
		return 1
	elseif t < OPEN + HOLD + CLOSE then
		local u = (t - OPEN - HOLD) / CLOSE
		return math.cos(u * math.pi / 2) - 0.08 * math.sin(u * math.pi)
	end
	return 0
end

function SaveDiskController.Init()
	Tags.each("SaveDisk", function(inst)
		if inst:IsA("BasePart") then
			track(inst)
		end
	end, function(inst)
		untrack(inst :: BasePart)
	end)

	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		for holder, disk in disks do
			local t = now - disk.savedAt
			if t > OPEN + HOLD + CLOSE + 0.1 then
				continue -- shut and still: nothing to move
			end
			local slide = shutterOpen(t) * SLIDE * holder.Size.X / KIT_WIDTH
			local cf = holder.CFrame * CFrame.new(slide, 0, 0)
			for p, offset in disk.parts do
				if p.Parent then
					p.CFrame = cf * offset
				end
			end
		end
	end)
end

return SaveDiskController
