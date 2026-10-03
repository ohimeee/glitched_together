-- Floppy-disk save points (ArtService/GlitchedCore savePoints tags the holder "SaveDisk"; Prologue + Glitched Core).
-- Idle: the disk bobs and tilts gently in its clip stand. When its checkpoint saves (the server stamps `SavedAt`) the
-- disk sinks into the stand like a drive taking it, pops back up with a little overshoot, a drive light on the stand
-- turns green and "SAVED!" pops over it. Purely visual and local; the stand and clips never move.
-- Parts are tracked as they arrive (StreamingEnabled can deliver the holder before its meshes).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)

local SaveDiskController = {}

local STATIC = { Stand = true, ClipF = true, ClipB = true }
local LIGHT_OFF = Color3.fromRGB(60, 64, 70)
local LIGHT_ON = Color3.fromRGB(90, 255, 120)
local SAVE_TIME = 1.1 -- s for the sink + pop back

type Disk = {
	home: CFrame,
	parts: { [BasePart]: CFrame },
	phase: number,
	savedAt: number, -- os.clock() of the last save, -inf before
	light: Part?,
	conns: { RBXScriptConnection },
}
local disks: { [BasePart]: Disk } = {}

local function popText(holder: BasePart)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(150, 44)
	gui.StudsOffsetWorldSpace = Vector3.new(0, holder.Size.Y / 2 + 1.5, 0)
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

-- a small drive light on the front of the stand (local), dark until the first save
local function makeLight(holder: BasePart, stand: BasePart): Part
	local light = Instance.new("Part")
	light.Name = "DriveLight"
	light.Anchored = true
	light.CanCollide = false
	light.CanQuery = false
	light.CanTouch = false
	light.Material = Enum.Material.Neon
	light.Color = LIGHT_OFF
	light.Shape = Enum.PartType.Ball
	local d = math.max(0.3, stand.Size.Y * 0.9)
	light.Size = Vector3.new(d, d, d)
	-- front (-Z) right corner of the stand
	light.CFrame = stand.CFrame * CFrame.new(stand.Size.X * 0.4, 0, -stand.Size.Z / 2 - d * 0.2)
	light.Parent = holder
	return light
end

local function track(holder: BasePart)
	local disk: Disk = {
		home = holder.CFrame,
		parts = {},
		phase = (holder.Position.X + holder.Position.Z) * 0.07,
		savedAt = -math.huge,
		light = nil,
		conns = {},
	}
	local function add(p: Instance)
		if not p:IsA("BasePart") or p.Name == "DriveLight" then
			return
		end
		if STATIC[p.Name] then
			if p.Name == "Stand" and not disk.light then
				disk.light = makeLight(holder, p)
				if disk.savedAt > -math.huge then
					disk.light.Color = LIGHT_ON
				end
			end
			return
		end
		disk.parts[p] = holder.CFrame:ToObjectSpace(p.CFrame)
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
		local at = holder:GetAttribute("SavedAt")
		if not at then
			return
		end
		if animate then
			disk.savedAt = os.clock()
			popText(holder)
		else
			disk.savedAt = os.clock() - SAVE_TIME -- already saved before we saw it: just light up
		end
		if disk.light then
			disk.light.Color = LIGHT_ON
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
		if disk.light then
			disk.light:Destroy()
		end
		disks[holder] = nil
	end
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
		local t = os.clock()
		for holder, disk in disks do
			local h = holder.Size.Y
			-- idle: a slow bob and a slight rock, like it's waiting to be read
			local s = (t * 0.45 + disk.phase) * math.pi * 2
			local bob = math.sin(s) * h * 0.025
			local tilt = math.sin(s * 0.5) * math.rad(2.5)
			-- save: sink a third of its height into the stand, then spring back up past home and settle
			local k = (t - disk.savedAt) / SAVE_TIME
			if k >= 0 and k < 1 then
				local dip
				if k < 0.35 then
					dip = -math.sin(k / 0.35 * math.pi / 2) * h * 0.33
				else
					local u = (k - 0.35) / 0.65
					dip = (-0.33 * math.cos(u * math.pi / 2) + 0.08 * math.sin(u * math.pi)) * h
				end
				bob += dip
				tilt *= 0.2
			end
			-- rock about the bottom edge of the disk (in the clip), not its middle
			local foot = CFrame.new(0, -h / 2, 0)
			local cf = disk.home * CFrame.new(0, bob, 0) * foot * CFrame.Angles(0, 0, tilt) * foot:Inverse()
			for p, offset in disk.parts do
				if p.Parent then
					p.CFrame = cf * offset
				end
			end
		end
	end)
end

return SaveDiskController
