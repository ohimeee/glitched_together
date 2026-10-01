-- Level contraptions (mechanics.md §4 World 1, Story Line 1-3 Coin Factory, Glitch Chase set piece):
--   Conveyor  (anchored part): carries whoever stands on it along its LookVector at `Speed`; stops while Frozen.
--   Dropper   (invisible part): drops a Freezable block every `Every` s (Kai freezes it mid-air, Miko grapples it).
--   Respawn   (loose part, e.g. a Pullable crate): put back where it started if it falls out of the world.
--   GlitchWall (part, child ObjectValue `Trigger` → a zone part): once the whole duo is in the zone, sweeps along its
--             LookVector at `Speed` for `Distance` studs; anyone behind its front face falls (HealthService.Fall)
--             and the wall resets so the duo can retry. Pause Beam freezes are read from the Frozen attribute.
--   Blinker   (part): solid only on its `Frames` ("1,2") of a shared clock (Tuning FrameTime x FrameCount), with an
--             `On` attribute for the look; a Freeze holds it as it is. Glitched Core phantom steps are Blinkers that
--             are also CodeVisual (drawn only in Miko's Code Layer), so only she sees which step is solid.
--   FrameSign (part with sign SurfaceGuis): shows the current frame ("FRAME 3"); CodeVisual = only Miko reads it.
--   BonkBlock (teal "?" block, also Pullable): Miko's Pull bonks it (GrappleLine → ContraptionService.Bonk) and it pops
--             out a coin step that sinks at `FallSpeed` for `FallDistance` studs, then vanishes. The step is Freezable
--             and stops while Frozen, so Kai freezes it at the height they need (Coin Bonk Stairs). A new bonk
--             replaces that block's last step unless it's frozen.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)
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
		Audio.play("Dropper", dropper, 0.6)
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
		-- while Kai holds a block frozen, the dropper waits: no new blocks raining past the one being used
		-- (playtest Oct 1)
		local function anyFrozen(): boolean
			for _, b in folder:GetChildren() do
				if frozen(b) then
					return true
				end
			end
			return false
		end
		while dropper:IsDescendantOf(workspace) and anyFrozen() do
			task.wait(0.2)
		end
	end
end

-- Coin Bonk Stairs ----------------------------------------------------------------------------
local lastCoin: { [BasePart]: BasePart } = {}
local sinking: { [BasePart]: { left: number, speed: number } } = {}

function ContraptionService.Bonk(inst: Instance)
	if not inst:IsA("BasePart") then
		return
	end
	local bonk = inst :: BasePart
	local home = bonk:GetAttribute("HomeCFrame") :: CFrame?
	if not home then
		home = bonk.CFrame
		bonk:SetAttribute("HomeCFrame", home)
	end
	-- the block hops up a stud and back, like being hit from below
	bonk.CFrame = home :: CFrame
	TweenService:Create(bonk, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true), {
		CFrame = (home :: CFrame) + Vector3.new(0, 1, 0),
	}):Play()
	Audio.play("PoundImpact", bonk, 0.5)

	local old = lastCoin[bonk]
	if old and old.Parent and not frozen(old) then
		old:Destroy()
	end
	local size = (bonk:GetAttribute("CoinSize") or T.CoinSize) :: Vector3
	local coin = Instance.new("Part")
	coin.Name = "CoinStep"
	coin.Size = size
	coin.CFrame = (home :: CFrame) * CFrame.new(0, -(bonk.Size.Y + size.Y) / 2 - 0.3, 0)
	coin.Anchored = true
	coin.Color = Color3.fromRGB(150, 98, 52) -- a spent block's brown; Kai's orange highlight shows it's freezable
	coin.Material = Enum.Material.SmoothPlastic
	coin.TopSurface = Enum.SurfaceType.Smooth
	coin.BottomSurface = Enum.SurfaceType.Smooth
	CollectionService:AddTag(coin, "Freezable")
	coin.Parent = bonk.Parent
	lastCoin[bonk] = coin
	sinking[coin] = {
		left = (bonk:GetAttribute("FallDistance") or T.CoinFall) :: number,
		speed = (bonk:GetAttribute("FallSpeed") or T.CoinFallSpeed) :: number,
	}
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

local function currentFrame(): number
	return math.floor(workspace:GetServerTimeNow() / T.FrameTime) % T.FrameCount + 1
end

local function setBlinker(part: BasePart, on: boolean)
	if part:GetAttribute("On") == on then
		return
	end
	part:SetAttribute("On", on)
	part.CanCollide = on
	if not CollectionService:HasTag(part, "CodeVisual") then
		part.Transparency = if on then 0 else 0.85
	end
end

function ContraptionService.Init()
	local blinkers: { [BasePart]: { [number]: boolean } } = {}
	local frameSigns: { [BasePart]: boolean } = {}
	Tags.each("Blinker", function(inst)
		if inst:IsA("BasePart") then
			local frames = {}
			for _, f in string.split(tostring(inst:GetAttribute("Frames") or "1"), ",") do
				local n = tonumber(f)
				if n then
					frames[n] = true
				end
			end
			blinkers[inst] = frames
		end
	end, function(inst)
		blinkers[inst :: BasePart] = nil
	end)
	Tags.each("FrameSign", function(inst)
		if inst:IsA("BasePart") then
			frameSigns[inst] = true
		end
	end, function(inst)
		frameSigns[inst :: BasePart] = nil
	end)
	task.spawn(function()
		local shown = 0
		while true do
			local frame = currentFrame()
			for part, frames in blinkers do
				if not part.Parent then
					blinkers[part] = nil
				elseif not frozen(part) then
					setBlinker(part, frames[frame] == true)
				end
			end
			if frame ~= shown then
				shown = frame
				for sign in frameSigns do
					for _, label in sign:GetDescendants() do
						if label:IsA("TextLabel") then
							label.Text = `FRAME {frame}`
						end
					end
				end
			end
			task.wait(0.05)
		end
	end)

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
			-- the Glitch is heard before it's seen (art-direction.md §7): a crackle, then a buzzing hum while it runs
			local hum: Sound? = nil
			-- hidden until the chase starts (playtest Oct 1: a frozen magenta wall standing in the level from afar
			-- read as a mystery); it glitches in when it wakes and out again when the chase resets or ends
			local shown = inst.Transparency
			inst.Transparency = 1
			local function fade(to: number)
				TweenService:Create(inst, TweenInfo.new(0.4), { Transparency = to }):Play()
			end
			inst:GetAttributeChangedSignal("Running"):Connect(function()
				if hum then
					hum:Destroy()
					hum = nil
				end
				fade(if inst:GetAttribute("Running") then shown else 1)
				if inst:GetAttribute("Running") then
					Audio.play("GlitchCrackle", inst, 1.5)
					hum = Audio.play("GlitchHum", inst)
				end
			end)
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
		for coin, s in sinking do
			if not coin.Parent then
				sinking[coin] = nil
			elseif not frozen(coin) then
				local step = math.min(s.speed * dt, s.left)
				coin.CFrame -= Vector3.new(0, step, 0)
				s.left -= step
				if s.left <= 0 then
					sinking[coin] = nil
					coin:Destroy()
				end
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
