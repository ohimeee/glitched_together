-- Level contraptions (mechanics.md §4 World 1, Story Line 1-3 Coin Factory, Glitch Chase set piece):
--   Conveyor  (anchored part): carries whoever stands on it along its LookVector at `Speed`; stops while Frozen.
--   Dropper   (invisible part): drops a Freezable block every `Every` s (Kai freezes it mid-air, Miko grapples it).
--   Respawn   (loose part, e.g. a Pullable crate): put back where it started if it falls out of the world.
--   GlitchWall (part, child ObjectValue `Trigger` → a zone part): once the whole duo is in the zone, sweeps along its
--             LookVector at `Speed` for `Distance` studs; anyone behind its front face falls (HealthService.Fall)
--             and the wall resets so the duo can retry. Pause Beam freezes are read from the Frozen attribute.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local HealthService = require(script.Parent.HealthService)

local T = Tuning.Contraptions

local ContraptionService = {}

local function frozen(inst: Instance): boolean
	return inst:GetAttribute("Frozen") == true
end

local function rootOf(p: Player): BasePart?
	local character = p.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function inside(part: BasePart, pos: Vector3): boolean
	local lp = part.CFrame:PointToObjectSpace(pos)
	local h = part.Size / 2
	return math.abs(lp.X) <= h.X and math.abs(lp.Y) <= h.Y and math.abs(lp.Z) <= h.Z
end

-- Conveyors -----------------------------------------------------------------------------------
local conveyors: { [BasePart]: boolean } = {}

-- Droppers ------------------------------------------------------------------------------------
local function runDropper(dropper: BasePart)
	local every = (dropper:GetAttribute("Every") or T.DropEvery) :: number
	local size = (dropper:GetAttribute("BlockSize") or T.DropSize) :: Vector3
	local life = (dropper:GetAttribute("Lifetime") or T.DropLifetime) :: number
	local folder = Instance.new("Folder")
	folder.Name = "Drops"
	folder.Parent = dropper
	while dropper:IsDescendantOf(workspace) do
		local block = Instance.new("Part")
		block.Name = "FallBlock"
		block.Size = size
		block.CFrame = dropper.CFrame
		block.Color = Color3.fromRGB(232, 228, 216)
		block.Material = Enum.Material.SmoothPlastic
		block.TopSurface = Enum.SurfaceType.Smooth
		block.BottomSurface = Enum.SurfaceType.Smooth
		block.CanCollide = true
		CollectionService:AddTag(block, "Freezable")
		block.Parent = folder
		if block:CanSetNetworkOwnership() then
			block:SetNetworkOwner(nil)
		end
		task.spawn(function()
			task.wait(life)
			while block.Parent and frozen(block) do
				task.wait(0.25) -- never pull a block out from under a grapple
			end
			block:Destroy()
		end)
		task.wait(every)
	end
end

-- Respawning loose parts ----------------------------------------------------------------------
local homes: { [BasePart]: CFrame } = {}

-- Glitch Chase --------------------------------------------------------------------------------
type Chase = {
	wall: BasePart,
	trigger: BasePart?,
	start: CFrame,
	travelled: number,
	running: boolean,
	cooldown: number,
	goAt: number,
}
local chases: { [BasePart]: Chase } = {}

local function resetChase(c: Chase)
	c.running = false
	c.travelled = 0
	c.wall.CFrame = c.start
	c.cooldown = os.clock() + T.ChaseRetryDelay
end

local function stepChase(c: Chase, dt: number)
	local wall = c.wall
	if not c.running then
		if os.clock() < c.cooldown or not c.trigger then
			return
		end
		-- starts only once the whole duo stands in the trigger zone (a sync point: nobody gets left behind)
		local players = Players:GetPlayers()
		for _, p in players do
			local root = rootOf(p)
			if not (root and inside(c.trigger :: BasePart, root.Position)) then
				return
			end
		end
		if #players > 0 then
			c.running = true
			c.goAt = os.clock() + T.ChaseWarmup -- a beat to see it coming (clients rumble on Running)
			wall:SetAttribute("Running", true)
		end
		return
	end
	local distance = (wall:GetAttribute("Distance") or 300) :: number
	if os.clock() < c.goAt then
		return
	end
	if c.travelled < distance and not frozen(wall) then
		local move = math.min(((wall:GetAttribute("Speed") or T.ChaseSpeed) :: number) * dt, distance - c.travelled)
		c.travelled += move
		wall.CFrame = c.start + c.start.LookVector * c.travelled
	end
	-- anyone behind the front face (and within its width/height) is caught
	local front = wall.CFrame * CFrame.new(0, 0, -wall.Size.Z / 2)
	for _, p in Players:GetPlayers() do
		local root = rootOf(p)
		if root and not p:GetAttribute("Downed") and not p:GetAttribute("Falling") then
			local lp = front:PointToObjectSpace(root.Position)
			if lp.Z > 0 and math.abs(lp.X) <= wall.Size.X / 2 and math.abs(lp.Y) <= wall.Size.Y / 2 then
				HealthService.Fall(p)
				wall:SetAttribute("Running", nil)
				resetChase(c)
				return
			end
		end
	end
	if c.travelled >= distance then
		wall:SetAttribute("Running", nil)
	end
end

function ContraptionService.Init()
	Tags.each("Conveyor", function(inst)
		if inst:IsA("BasePart") then
			conveyors[inst] = true
		end
	end, function(inst)
		conveyors[inst :: BasePart] = nil
	end)

	Tags.each("Dropper", function(inst)
		if inst:IsA("BasePart") then
			task.spawn(runDropper, inst)
		end
	end)

	Tags.each("Respawn", function(inst)
		if inst:IsA("BasePart") then
			homes[inst] = inst.CFrame
		end
	end, function(inst)
		homes[inst :: BasePart] = nil
	end)

	Tags.each("GlitchWall", function(inst)
		if inst:IsA("BasePart") then
			local link = inst:FindFirstChild("Trigger") :: ObjectValue?
			chases[inst] = {
				wall = inst,
				trigger = link and link.Value :: BasePart?,
				start = inst.CFrame,
				travelled = 0,
				running = false,
				cooldown = 0,
				goAt = 0,
			}
		end
	end, function(inst)
		chases[inst :: BasePart] = nil
	end)

	RunService.Heartbeat:Connect(function(dt)
		for part in conveyors do
			if not part.Parent then
				conveyors[part] = nil
				continue
			end
			local speed = (part:GetAttribute("Speed") or T.ConveyorSpeed) :: number
			part.AssemblyLinearVelocity = if frozen(part) then Vector3.zero else part.CFrame.LookVector * speed
		end
		for _, c in chases do
			if c.wall.Parent then
				stepChase(c, dt)
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			local killY = (workspace:GetAttribute("KillY") or -150) :: number
			for part, home in homes do
				if not part.Parent then
					homes[part] = nil
				elseif part.Position.Y < killY + 20 then
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
					part.CFrame = home
				end
			end
		end
	end)
end

return ContraptionService
