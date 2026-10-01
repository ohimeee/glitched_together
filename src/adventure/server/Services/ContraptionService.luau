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
		wall.Transparency = if solid then 0 else 0.7
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
