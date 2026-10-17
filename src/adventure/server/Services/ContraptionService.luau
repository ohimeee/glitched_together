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
--   SiegeRide (Model: `Cart` Model with a PrimaryPart and welded walls incl. `CartRear` / `CartFront`, a `Track` folder
--             of parts named 1, 2, 3... at cart-centre height, a `Barricades` folder of Burnable parts): the castle set
--             piece (mechanics.md §4). Once both players stand in the cart it rolls along the track at `Speed`; Kai
--             burns the barricades ahead (Ignite), Miko blocks the archers' arrows. Reaching an unburned barricade, or
--             a player leaving the cart, crashes it: after a beat the cart, the barricades and the duo go back to the
--             start. At the end it stops and drops its front wall. `Stations` ("600,..." track distances): the cart
--             pauses there for a breather, and a crash after a station restarts the ride from it, not the dock.
--   Scanner   (part, usually a Driven mover on Kai's terminal Station): lights a flat cone along its LookVector,
--             `Range` studs, `Angle` degrees either side (Tuning ScanRange / ScanAngle).
--   Unloaded  (part): floor that isn't loaded: solid and drawn only while a Scanner's cone covers it, then for
--             `ScanLinger` s more (Glitched Core 3-3 Unloaded Chunk: Kai sweeps the cone, Miko runs what it shows).
--   Scale     (Model with movers `PanA` and `PanB`, both Driven with ReturnRate 0; PanA's waypoints run high → low,
--             PanB's low → high): a two-pan balance (Glitched Core Counterweight). Each pan weighs what rests on it
--             (players `PlayerWeight`, parts with a `Weight` attribute: pastes keep their source's; a Code Layer
--             piece counts only once pulled out) and both pans seek progress Rest + (A − B) × `Gain`, so A sinking
--             lifts B. Anchored weights ride their pan. Freezing either pan holds the whole scale.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local HealthService = require(script.Parent.HealthService)
local MoverService = require(script.Parent.MoverService)
local CheckpointService = require(script.Parent.CheckpointService)

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
		block.Anchored = true -- moved below; a freeze just sets the Frozen attribute (MoverService.Pause)
		CollectionService:AddTag(block, "Freezable")
		block.Parent = folder
		Audio.play("Dropper", dropper, 0.6)
		task.spawn(function()
			-- falls slow, then faster; gone at the end of its life, or once it falls past the kill floor (missed
			-- blocks fell for their whole lifetime and hung as orange specks far below the level)
			local killY = ((workspace:GetAttribute("KillY") or -60) :: number) - 10
			local speed = T.DropSpeed
			local age = 0
			while block.Parent do
				local dt = RunService.Heartbeat:Wait()
				if frozen(block) or workspace:GetAttribute("Paused") then
					continue -- never pull a block out from under a grapple; its life waits too
				end
				age += dt
				if age >= life or block.Position.Y < killY then
					break
				end
				block.CFrame -= Vector3.new(0, speed * dt, 0)
				speed = math.min(speed + T.DropAccel * dt, T.DropMaxSpeed)
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
local badRolls: { [BasePart]: number } = {} -- sabotage rolls in a row per block (the pity counter)
local rng = Random.new()

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
	local fall = (bonk:GetAttribute("FallDistance") or T.CoinFall) :: number
	local speed = (bonk:GetAttribute("FallSpeed") or T.CoinFallSpeed) :: number

	-- What pops out (user, Oct 17: "different items, some sabotage some help"): a step, a big gold step (easier), a
	-- cracked step that crumbles under you, or a Glitch blob that hurts. Two bad rolls in a row and the next is a step.
	local kind = "Step"
	if (badRolls[bonk] or 0) < T.Bonk.PityAfter then
		local total = 0
		for _, w in T.Bonk.Weights do
			total += w
		end
		local roll = rng:NextNumber() * total
		for _, name in { "Step", "Big", "Crumble", "Glitch" } do
			roll -= T.Bonk.Weights[name]
			if roll <= 0 then
				kind = name
				break
			end
		end
	end
	badRolls[bonk] = if kind == "Crumble" or kind == "Glitch" then (badRolls[bonk] or 0) + 1 else 0

	local coin = Instance.new("Part")
	coin.Name = if kind == "Step" then "CoinStep" else "Bonk" .. kind -- CoinStep wears its skin (ArtService by name)
	coin.Anchored = true
	coin.TopSurface = Enum.SurfaceType.Smooth
	coin.BottomSurface = Enum.SurfaceType.Smooth
	coin.Material = Enum.Material.SmoothPlastic
	coin.Color = Color3.fromRGB(150, 98, 52) -- a spent block's brown; Kai's orange highlight shows it's freezable
	if kind == "Big" then
		size = Vector3.new(size.X * T.Bonk.BigScale, size.Y, size.Z * T.Bonk.BigScale)
		speed *= T.Bonk.BigFallScale
		coin.Color = Palette.PixelPlains.Gold
		coin.Material = Enum.Material.Metal
	elseif kind == "Crumble" then
		coin.Color = Color3.fromRGB(176, 150, 112) -- pale, cracked sandstone: reads as weak
		coin.Material = Enum.Material.Cobblestone
	elseif kind == "Glitch" then
		size = Vector3.one * 3
		speed *= T.Bonk.GlitchFallScale
		coin.Color = Palette.Glitch
		coin.Material = Enum.Material.Neon
		coin.CanCollide = false
		coin:SetAttribute("Damage", 1)
	end
	coin.Size = size
	coin.CFrame = (home :: CFrame) * CFrame.new(0, -(bonk.Size.Y + size.Y) / 2 - 0.3, 0)
	if kind == "Glitch" then
		CollectionService:AddTag(coin, "Hazard") -- touch = a heart (HealthService); can't be frozen into a step
		Audio.play("GlitchCrackle", coin, 1.4)
	else
		CollectionService:AddTag(coin, "Freezable")
	end
	if kind == "Crumble" then
		-- crumbles a beat after someone stands on it, frozen or not
		local crumbling = false
		coin.Touched:Connect(function(hit)
			local character = hit:FindFirstAncestorOfClass("Model")
			if crumbling or not (character and Players:GetPlayerFromCharacter(character)) then
				return
			end
			crumbling = true
			Audio.play("PoundDebris", coin, 1.6)
			local home2 = coin.CFrame
			for i = 1, 6 do
				task.delay(i * T.Bonk.CrumbleDelay / 6, function()
					if coin.Parent then
						coin.CFrame = home2 * CFrame.new((i % 2 * 2 - 1) * 0.15, 0, 0)
					end
				end)
			end
			task.delay(T.Bonk.CrumbleDelay, function()
				if coin.Parent then
					sinking[coin] = nil
					coin.CanCollide = false
					TweenService:Create(coin, TweenInfo.new(0.25), { Transparency = 1 }):Play()
					task.delay(0.3, coin.Destroy, coin)
				end
			end)
		end)
	end
	coin.Parent = bonk.Parent
	lastCoin[bonk] = coin
	sinking[coin] = { left = fall, speed = speed }
end

-- Siege Cart ----------------------------------------------------------------------------------
type Ride = {
	model: Model,
	cart: Model,
	root: BasePart,
	path: { Vector3 },
	length: number,
	speed: number,
	s: number,
	state: string, -- "Wait" | "Warmup" | "Run" | "Crash" | "Done"
	goAt: number,
	template: Folder?,
	stations: { number },
	home: number, -- where a crash restarts from (0 = the dock, else the last station passed)
	alignPos: AlignPosition,
	alignRot: AlignOrientation,
}
local rides: { [Model]: Ride } = {}

local function trackPoint(r: Ride, s: number): Vector3
	local d = math.clamp(s, 0, r.length)
	for i = 1, #r.path - 1 do
		local a, b = r.path[i], r.path[i + 1]
		local seg = (b - a).Magnitude
		if d <= seg or i == #r.path - 1 then
			return a + (b - a).Unit * math.min(d, seg)
		end
		d -= seg
	end
	return r.path[1]
end

-- the cart's pose at distance s; it faces along a short chord so corners turn smoothly
local function trackPose(r: Ride, s: number): CFrame
	local p = trackPoint(r, s)
	local dir = trackPoint(r, s + 3) - trackPoint(r, s - 3)
	if dir.Magnitude < 0.01 then
		dir = r.path[2] - r.path[1]
	end
	return CFrame.lookAt(p, p + dir.Unit)
end

local function setCartWall(r: Ride, name: string, solid: boolean)
	local wall = r.cart:FindFirstChild(name)
	if wall and wall:IsA("BasePart") then
		wall.CanCollide = solid
		-- ArtHidden: the cart mesh draws the walls (ArtService), so the grey-box wall stays invisible
		wall.Transparency = if wall:GetAttribute("ArtHidden") then 1 elseif solid then 0 else 0.7
	end
end

local function aboard(r: Ride, p: Player): boolean
	local root = rootOf(p)
	if not root then
		return false
	end
	local lp = r.root.CFrame:PointToObjectSpace(root.Position)
	local half = r.root.Size / 2
	return math.abs(lp.X) <= half.X + 0.5 and math.abs(lp.Z) <= half.Z + 0.5 and lp.Y > 0 and lp.Y < 8
end

local function placeCart(r: Ride, cf: CFrame)
	r.cart:PivotTo(cf * r.root.CFrame:ToObjectSpace(r.cart:GetPivot()))
	r.alignPos.Position = cf.Position
	r.alignRot.CFrame = cf.Rotation
end

local function resetRide(r: Ride)
	r.s = r.home
	r.state = "Wait"
	r.model:SetAttribute("Running", nil)
	local start = trackPose(r, r.home)
	placeCart(r, start)
	setCartWall(r, "CartRear", false)
	setCartWall(r, "CartFront", true)
	local old = r.model:FindFirstChild("Barricades")
	if old and r.template then
		old:Destroy()
		local fresh = r.template:Clone()
		for _, b in fresh:GetChildren() do
			if ((b:GetAttribute("S") or math.huge) :: number) < r.home then
				b:Destroy() -- already passed before the station
			end
		end
		fresh.Parent = r.model
	end
	for _, p in Players:GetPlayers() do
		if not p:GetAttribute("Downed") and p.Character then
			local side = if p:GetAttribute("Role") == "Miko" then 2 else -2
			p.Character:PivotTo(start * CFrame.new(side, 3.5, 0))
		end
	end
end

local function crashed(r: Ride): boolean
	local front = r.root.Size.Z / 2
	local barricades = r.model:FindFirstChild("Barricades")
	for _, b in if barricades then barricades:GetChildren() else {} do
		if b:IsA("BasePart") and not b:GetAttribute("Burning") then
			local lp = r.root.CFrame:PointToObjectSpace(b.Position)
			if lp.Z < 0 and lp.Z > -(front + 1.5 + b.Size.Z / 2) and math.abs(lp.X) < r.root.Size.X / 2 + 1 then
				return true
			end
		end
	end
	for _, p in Players:GetPlayers() do
		local root = rootOf(p)
		if root and not p:GetAttribute("Downed") and (root.Position - r.root.Position).Magnitude > 14 then
			return true -- stay in the cart (Kai's Blink can take him out of it)
		end
	end
	return false
end

local function stepRide(r: Ride, dt: number)
	local now = os.clock()
	local players = Players:GetPlayers()
	if r.state == "Wait" or r.state == "Warmup" then
		local all = #players > 0
		for _, p in players do
			if not aboard(r, p) then
				all = false
			end
		end
		if r.state == "Wait" and all then
			r.state = "Warmup"
			r.goAt = now + 1.5
			setCartWall(r, "CartRear", true) -- shut the back: you're riding now
		elseif r.state == "Warmup" and not all then
			r.state = "Wait"
			setCartWall(r, "CartRear", false)
		elseif r.state == "Warmup" and now >= r.goAt then
			r.state = "Run"
			r.model:SetAttribute("Running", true)
		end
	elseif r.state == "Stop" then
		if now >= r.goAt then
			r.state = "Run"
			r.model:SetAttribute("Running", true)
		end
	elseif r.state == "Run" then
		r.s = math.min(r.s + r.speed * dt, r.length)
		for _, station in r.stations do
			if r.home < station and r.s >= station then
				r.s = station
				r.home = station -- crashes from here on restart at the station
				r.state = "Stop"
				r.goAt = now + T.CartStationPause
				r.model:SetAttribute("Running", nil)
				Audio.play("Checkpoint", r.root)
				for _, p in Players:GetPlayers() do -- a breather: patch up for the last leg
					if not p:GetAttribute("Downed") then
						HealthService.Restore(p, ((p:GetAttribute("Health") or 0) :: number) + T.CartStationHeal)
					end
				end
				break
			end
		end
		local cf = trackPose(r, r.s)
		r.alignPos.Position = cf.Position
		r.alignRot.CFrame = cf.Rotation
		if crashed(r) then
			r.state = "Crash"
			r.goAt = now + 1.2
			r.model:SetAttribute("Running", nil)
			Audio.play("PoundImpact", r.root)
		elseif r.s >= r.length then
			r.state = "Done"
			r.model:SetAttribute("Running", nil)
			r.model:SetAttribute("Done", true)
			setCartWall(r, "CartFront", false)
		end
	elseif r.state == "Crash" and now >= r.goAt then
		resetRide(r)
	end
end

local function registerRide(model: Instance)
	if not model:IsA("Model") or rides[model] then
		return
	end
	local cart = model:FindFirstChild("Cart")
	local track = model:FindFirstChild("Track")
	if not (cart and cart:IsA("Model") and cart.PrimaryPart and track) then
		warn(
			"[ContraptionService] SiegeRide needs a Cart model with a PrimaryPart and a Track folder:",
			model:GetFullName()
		)
		return
	end
	local list = track:GetChildren()
	table.sort(list, function(a, b)
		return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
	end)
	local path = {}
	for _, wp in list do
		if wp:IsA("BasePart") then
			table.insert(path, wp.Position)
			wp.Transparency = 1
			wp.CanCollide = false
			wp.CanQuery = false
			wp.CanTouch = false
		end
	end
	local length = 0
	for i = 1, #path - 1 do
		length += (path[i + 1] - path[i]).Magnitude
	end
	local root = cart.PrimaryPart :: BasePart
	local attachment = Instance.new("Attachment")
	attachment.Parent = root
	local alignPos = Instance.new("AlignPosition")
	alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPos.Attachment0 = attachment
	alignPos.RigidityEnabled = true
	alignPos.Parent = root
	local alignRot = Instance.new("AlignOrientation")
	alignRot.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignRot.Attachment0 = attachment
	alignRot.RigidityEnabled = true
	alignRot.Parent = root
	local barricades = model:FindFirstChild("Barricades")
	local stations = {}
	for _, v in string.split(tostring(model:GetAttribute("Stations") or ""), ",") do
		local n = tonumber(v)
		if n then
			table.insert(stations, n)
		end
	end
	table.sort(stations)
	local r: Ride = {
		model = model,
		cart = cart,
		root = root,
		path = path,
		length = length,
		speed = (model:GetAttribute("Speed") or T.CartSpeed) :: number,
		s = 0,
		state = "Wait",
		goAt = 0,
		template = if barricades and barricades:IsA("Folder") then barricades:Clone() else nil,
		stations = stations,
		home = 0,
		alignPos = alignPos,
		alignRot = alignRot,
	}
	rides[model] = r
	placeCart(r, trackPose(r, 0))
	for _, part in cart:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
	setCartWall(r, "CartRear", false)
	task.defer(function()
		if root:IsDescendantOf(workspace) and root:CanSetNetworkOwnership() then
			root:SetNetworkOwner(nil)
		end
	end)
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
	path: { Vector3 }?, -- world points the wall follows (its "Path" folder), else straight along its LookVector
}
local chases: { [BasePart]: Chase } = {}

-- Where a path-following wall stands after `travelled` studs, facing along the path (level).
local function alongPath(path: { Vector3 }, travelled: number): CFrame
	local left = travelled
	for i = 2, #path do
		local a, b = path[i - 1], path[i]
		local leg = (b - a).Magnitude
		if left <= leg or i == #path then
			local flatDir = (b - a) * Vector3.new(1, 0, 1)
			local at = a:Lerp(b, if leg > 0 then math.clamp(left / leg, 0, 1) else 1)
			return CFrame.lookAt(at, at + (if flatDir.Magnitude > 0.01 then flatDir.Unit else Vector3.zAxis))
		end
		left -= leg
	end
	return CFrame.new(path[#path])
end

local function resetChase(c: Chase)
	c.running = false
	c.travelled = 0
	c.wall.CFrame = c.start
	c.cooldown = os.clock() + T.ChaseRetryDelay
end

-- A failed run (someone caught by the wall or fallen off a rail): the whole duo goes back to the chase's start
-- (the checkpoint before it) and the wall resets (playtest Oct 4: "if i die i should spawn in the rail start").
-- `caught`: the player the wall touched goes down (user, Oct 17: "if it tags me I should die"), and mashes back at
-- the start; everyone else just falls back there.
local function failChase(c: Chase, caught: Player?)
	c.wall:SetAttribute("Running", nil)
	resetChase(c)
	for _, p in Players:GetPlayers() do
		HealthService.SetSafe(p, CheckpointService.SpawnCFrame(p))
		if p == caught then
			HealthService.Down(p) -- no history after SetSafe: the respawn lands on the chase checkpoint
		else
			HealthService.Fall(p) -- the usual fall: a beat, then put back (now at the start)
		end
	end
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
		wall.CFrame = if c.path then alongPath(c.path, c.travelled) else c.start + c.start.LookVector * c.travelled
	end
	-- anyone the front face reaches (a body's depth in front of it, or behind it, within its width/height) is caught
	local front = wall.CFrame * CFrame.new(0, 0, -wall.Size.Z / 2)
	for _, p in Players:GetPlayers() do
		local root = rootOf(p)
		if root and not p:GetAttribute("Downed") and not p:GetAttribute("Falling") then
			local lp = front:PointToObjectSpace(root.Position)
			if lp.Z > -T.ChaseTouch and math.abs(lp.X) <= wall.Size.X / 2 and math.abs(lp.Y) <= wall.Size.Y / 2 then
				failChase(c, p)
				return
			end
		end
	end
	for _, p in Players:GetPlayers() do
		if p:GetAttribute("Falling") or p:GetAttribute("Downed") then
			failChase(c) -- fell off a rail mid-run
			return
		end
	end
	if c.travelled >= distance then
		wall:SetAttribute("Running", nil)
	end
end

-- Scales ------------------------------------------------------------------------------------------
type Scale = { model: Model, a: BasePart, b: BasePart, last: { [BasePart]: CFrame } }
local scales: { [Model]: Scale } = {}
local scaleOverlap = OverlapParams.new() -- players (the Default group sees every character group)
scaleOverlap.FilterType = Enum.RaycastFilterType.Exclude
local weightOverlap = OverlapParams.new() -- weights, incl. a Code Layer one (only MikoShifted collides with those)
weightOverlap.FilterType = Enum.RaycastFilterType.Exclude
weightOverlap.CollisionGroup = "MikoShifted"

-- what rests on a pan: its weight, and the anchored weights that should ride along with it
local function onPan(pan: BasePart): (number, { BasePart })
	scaleOverlap.FilterDescendantsInstances = { pan }
	weightOverlap.FilterDescendantsInstances = { pan }
	local box = pan.CFrame * CFrame.new(0, pan.Size.Y / 2 + 3, 0)
	local size = Vector3.new(pan.Size.X, 6, pan.Size.Z)
	local weight, riders, seen = 0, {}, {}
	for _, part in workspace:GetPartBoundsInBox(box, size, scaleOverlap) do
		local model = part:FindFirstAncestorOfClass("Model")
		local p = model and Players:GetPlayerFromCharacter(model)
		if p and not seen[p] and not p:GetAttribute("Downed") then
			seen[p] = true
			weight += T.PlayerWeight
		end
	end
	for _, part in workspace:GetPartBoundsInBox(box, size, weightOverlap) do
		if part:GetAttribute("Weight") and not seen[part] then
			seen[part] = true
			if part.Anchored then
				table.insert(riders, part)
			end
			if not CollectionService:HasTag(part, "CodeLayer") or part:GetAttribute("PulledOut") then
				weight += part:GetAttribute("Weight") :: number
			end
		end
	end
	return weight, riders
end

local function stepScale(sc: Scale)
	local wa, ridersA = onPan(sc.a)
	local wb, ridersB = onPan(sc.b)
	local rest = (sc.model:GetAttribute("Rest") or 0.5) :: number
	local gain = (sc.model:GetAttribute("Gain") or T.ScaleGain) :: number
	local target = math.clamp(rest + (wa - wb) * gain, 0, 1)
	local held = frozen(sc.a) or frozen(sc.b)
	for _, pan in { sc.a, sc.b } do
		local axis = 0
		if not held then
			local diff = target - MoverService.Progress(pan)
			axis = if math.abs(diff) < 0.01 then 0 else math.clamp(diff * 6, -1, 1)
		end
		MoverService.Drive(pan, axis)
	end
	sc.model:SetAttribute("WeightA", wa) -- read by the pan labels
	sc.model:SetAttribute("WeightB", wb)
	for pan, riders in { [sc.a] = ridersA, [sc.b] = ridersB } do
		local before = sc.last[pan]
		if before then
			local delta = pan.CFrame * before:Inverse()
			if delta.Position.Magnitude > 1e-3 then
				for _, part in riders do
					part.CFrame = delta * part.CFrame
				end
			end
		end
		sc.last[pan] = pan.CFrame
	end
end

-- Unloaded Chunk ---------------------------------------------------------------------------------
local function setLoaded(part: BasePart, on: boolean)
	if part:GetAttribute("Loaded") == on then
		return
	end
	part:SetAttribute("Loaded", on)
	part.CanCollide = on
	part.CanQuery = on
	TweenService:Create(part, TweenInfo.new(if on then 0.12 else 0.35), { Transparency = if on then 0 else 1 }):Play()
end

local function lit(part: BasePart, scanners: { Instance }): boolean
	for _, scanner in scanners do
		if not scanner:IsA("BasePart") then
			continue
		end
		local range = (scanner:GetAttribute("Range") or T.ScanRange) :: number
		local angle = (scanner:GetAttribute("Angle") or T.ScanAngle) :: number
		local to = part.Position - scanner.Position
		local flatTo = Vector3.new(to.X, 0, to.Z)
		local look = scanner.CFrame.LookVector
		local flatLook = Vector3.new(look.X, 0, look.Z)
		if flatTo.Magnitude > range or flatLook.Magnitude < 1e-3 then
			continue
		end
		-- the tile counts once any of it is in the cone: widen the angle by the tile's own half width
		local slack = math.deg(math.atan2(math.max(part.Size.X, part.Size.Z) / 2, math.max(flatTo.Magnitude, 1)))
		if
			flatTo.Magnitude < 1
			or math.deg(math.acos(math.clamp(flatTo.Unit:Dot(flatLook.Unit), -1, 1))) <= angle + slack
		then
			return true
		end
	end
	return false
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

	Tags.each("Scale", function(inst)
		local a, b = inst:FindFirstChild("PanA"), inst:FindFirstChild("PanB")
		if inst:IsA("Model") and a and b and a:IsA("BasePart") and b:IsA("BasePart") then
			scales[inst] = { model = inst, a = a, b = b, last = {} }
		end
	end, function(inst)
		scales[inst :: Model] = nil
	end)

	local unloaded: { [BasePart]: number } = {} -- tile → last time a cone covered it
	Tags.each("Unloaded", function(inst)
		if inst:IsA("BasePart") then
			unloaded[inst] = -math.huge
			inst.Transparency = 1
			inst.CanCollide = false
			inst.CanQuery = false
			inst:SetAttribute("Loaded", false)
		end
	end, function(inst)
		unloaded[inst :: BasePart] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(0.05)
			if next(unloaded) == nil then
				continue
			end
			local scanners = Tags.list("Scanner")
			local now = os.clock()
			for part, seen in unloaded do
				if not part.Parent then
					unloaded[part] = nil
					continue
				end
				if lit(part, scanners) then
					unloaded[part] = now
					setLoaded(part, true)
				elseif now - seen > T.ScanLinger then
					setLoaded(part, false)
				end
			end
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

	Tags.each("SiegeRide", registerRide, function(inst)
		rides[inst :: Model] = nil
	end)

	Tags.each("Respawn", function(inst)
		if inst:IsA("BasePart") then
			homes[inst] = inst.CFrame
		end
	end, function(inst)
		homes[inst :: BasePart] = nil
	end)

	-- A slamming crusher (Coin Press) smashes a crate caught in the space it lands in: the crate cracks and is back at
	-- its start, so it only gets through under a crusher Kai froze (user, Oct 17: it was skippable).
	local smashOverlap = OverlapParams.new()
	MoverService.Slammed:Connect(function(crusher: Instance, landIn: number, landing: CFrame)
		local head = if crusher:IsA("BasePart") then crusher else nil
		if not head then
			return
		end
		task.delay(landIn * 0.7, function()
			smashOverlap.FilterType = Enum.RaycastFilterType.Exclude
			smashOverlap.FilterDescendantsInstances = { head }
			for _, part in workspace:GetPartBoundsInBox(landing, head.Size * 0.9, smashOverlap) do
				local home = homes[part]
				if home and CollectionService:HasTag(part, "Pullable") and not part.Anchored then
					Audio.play("PoundDebris", part.Position, 1.3)
					part.AssemblyLinearVelocity = Vector3.zero
					part.AssemblyAngularVelocity = Vector3.zero
					part.CFrame = home
				end
			end
		end)
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
			local folder = inst:FindFirstChild("Path")
			local path: { Vector3 }? = nil
			if folder then
				local points = {}
				for i = 1, #folder:GetChildren() do
					local value = folder:FindFirstChild(tostring(i)) :: Vector3Value?
					if value then
						table.insert(points, inst.CFrame:PointToWorldSpace(value.Value))
					end
				end
				path = points
			end
			chases[inst] = {
				path = path,
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
		if workspace:GetAttribute("Paused") then
			-- a level-up picker is open: everything holds (the cart's timers move on with the clock)
			for _, r in rides do
				r.goAt += dt
			end
			return
		end
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
		for model, r in rides do
			if not model.Parent then
				rides[model] = nil
			else
				stepRide(r, dt)
			end
		end
		for model, sc in scales do
			if not model.Parent then
				scales[model] = nil
			else
				stepScale(sc)
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
