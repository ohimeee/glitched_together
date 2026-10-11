-- The Crusher King (mechanics.md §5, Story Line World 1): a giant pixel king of stacked blocks, infected by the
-- Glitch. The arena and his body are built by Greybox (buildPixelPlains, BOSS ARENA); this runs the fight.
--   1. Fists slam one at a time, targets alternate Kai / Miko. Kai freezes a fist (on the floor its top is
--      double-jump high), Miko jumps on and ground-pounds its wrist crystal. 3 hits.
--   2. The rows in front of him drop away and he throws blocks; the safe rows crumble one tile at a time. Kai
--      freezes a block mid-flight, Miko grapples it and swings over the gap to his lap, climbs the belt to his
--      shoulders and pounds both shoulder crystals.
--   3. A Glitch shield covers his head. Kai freezes the whole king (shield drops, the crown can be pulled), Miko
--      grapples up onto his lap and pulls the crown off.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)
local Net = require(ReplicatedStorage.Shared.Net)
local Services = script.Parent.Parent.Services
local HealthService = require(Services.HealthService)
local InteractableService = require(Services.InteractableService)
local MoverService = require(Services.MoverService)
local DuoService = require(Services.DuoService)

local T = Tuning.CrusherKing
local TOTAL_HITS = T.CrystalHits + 2 + 1 -- wrist crystals, shoulder crystals, crown: the boss bar

type Fist = {
	part: BasePart,
	crystal: BasePart,
	home: CFrame,
	state: string, -- Idle | Track | Slam | Rest | Rise
	t: number,
	from: CFrame,
	target: Player?,
	mark: BasePart?,
	hit: boolean, -- a crystal hit this cycle (it shakes free, no second hit)
}
type Thrown = { part: BasePart, from: Vector3, to: Vector3, t: number }

local Boss = {}

local function rootOf(p: Player): BasePart?
	return p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function setHealth(self: any)
	workspace:SetAttribute("BossHealth", math.max(0, 1 - self.hits / TOTAL_HITS))
end

local function flash(part: BasePart)
	local color = part.Color
	part.Color = Color3.new(1, 1, 1)
	task.delay(Tuning.BossHitFlash, function()
		part.Color = color
	end)
end

-- a pound landing on top of `part` (feet anywhere over its top face, a little above it)
local function poundOn(part: BasePart, pos: Vector3, slack: number): boolean
	local lp = part.CFrame:PointToObjectSpace(pos)
	local h = part.Size / 2
	return math.abs(lp.X) <= h.X + slack and math.abs(lp.Z) <= h.Z + slack and lp.Y >= h.Y - 3 and lp.Y <= h.Y + 8
end

-- Miko's job (mechanics.md §5); a solo tester in Studio may do it too
local function mayPound(p: Player): boolean
	return p:GetAttribute("Role") == "Miko" or #DuoService.Players() < 2
end

-- Targets alternate between the two players (design.md §6); Downed players and the ones `skip` rejects sit out.
local function nextTarget(self: any, skip: ((Player) -> boolean)?): Player?
	local duo = DuoService.Players()
	for _ = 1, #duo do
		self.turn = self.turn % math.max(#duo, 1) + 1
		local p = duo[self.turn]
		if p and rootOf(p) and not p:GetAttribute("Downed") and not (skip and skip(p)) then
			return p
		end
	end
	return nil
end

-- Floor --------------------------------------------------------------------------------------------------------

local function tileHome(tile: BasePart): CFrame
	return tile:GetAttribute("Home") :: CFrame
end

local function dropTile(self: any, tile: BasePart)
	if self.falling[tile] then
		return
	end
	self.falling[tile] = true
	tile.Anchored = false
	tile.CanCollide = true
	CollectionService:AddTag(tile, "Freezable") -- Kai can stop it mid-fall and stand on it
	if tile:CanSetNetworkOwnership() then
		tile:SetNetworkOwner(nil)
	end
	Audio.play("PoundDebris", tile.Position, 0.8)
end

-- hide / show a tile with its grass cap and dirt chunks
local function showTile(tile: BasePart, visible: boolean)
	local parts: { Instance } = tile:GetDescendants()
	table.insert(parts, tile) -- the tile itself is the voxel dirt body now
	for _, d in parts do
		if d:IsA("BasePart") then
			if visible then
				local t = d:GetAttribute("ShownT")
				if t ~= nil then
					d.Transparency = t
					d:SetAttribute("ShownT", nil)
				end
			elseif d:GetAttribute("ShownT") == nil then
				d:SetAttribute("ShownT", d.Transparency)
				d.Transparency = 1
			end
		end
	end
end

local function restoreTile(self: any, tile: BasePart)
	if not tile.Parent then
		return
	end
	showTile(tile, true)
	MoverService.Resume(tile)
	CollectionService:RemoveTag(tile, "Freezable")
	tile.Anchored = true
	tile.AssemblyLinearVelocity = Vector3.zero
	tile.AssemblyAngularVelocity = Vector3.zero
	tile.CFrame = tileHome(tile) - Vector3.new(0, 8, 0)
	TweenService:Create(tile, TweenInfo.new(0.5, Enum.EasingStyle.Back), { CFrame = tileHome(tile) }):Play()
	self.falling[tile] = nil
	self.warned[tile] = nil
end

-- shake a tile, then drop it; it comes back after `back` seconds (nil = stays down until restoreAll)
local function crumble(self: any, tile: BasePart, warnTime: number, back: number?)
	if self.warned[tile] or self.falling[tile] then
		return
	end
	self.warned[tile] = true
	local token = self.token
	task.spawn(function()
		local home = tileHome(tile)
		-- the tile and its skin flicker Glitch magenta while it shakes
		local looks: { [BasePart]: Color3 } = { [tile] = tile.Color }
		for _, d in tile:GetDescendants() do
			if d:IsA("BasePart") then
				looks[d] = d.Color
			end
		end
		local start = os.clock()
		while os.clock() - start < warnTime do
			if self.token ~= token or not tile.Parent then
				break
			end
			tile.CFrame = home * CFrame.new(math.random() * 0.4 - 0.2, 0, math.random() * 0.4 - 0.2)
			local on = math.floor((os.clock() - start) * 10) % 2 == 0
			for part, color in looks do
				part.Color = if on then Palette.Glitch else color
			end
			task.wait(0.05)
		end
		for part, color in looks do
			part.Color = color
		end
		if not self.falling[tile] then
			tile.CFrame = home
		end
		if self.token ~= token then
			return
		end
		if self.token ~= token then
			return
		end
		dropTile(self, tile)
		if back then
			task.wait(back)
			if self.token == token then
				restoreTile(self, tile)
			end
		end
	end)
end

local function restoreAll(self: any)
	self.token += 1 -- stop every pending crumble
	for _, tile in self.tiles do
		if self.falling[tile] or tile.CFrame ~= tileHome(tile) then
			restoreTile(self, tile)
		end
		self.warned[tile] = nil
	end
end

-- falling tiles stop far below instead of dropping out of the world (they come back later)
local function parkFallen(self: any)
	for tile in self.falling do
		if not tile.Anchored and tile.Position.Y < self.floorTop - 120 then
			tile.Anchored = true
			CollectionService:RemoveTag(tile, "Freezable") -- no orange frame hanging in the void
			showTile(tile, false) -- its skin and dirt chunk too: no floating island far below
		end
	end
end

-- Fists --------------------------------------------------------------------------------------------------------

local function placeFist(f: Fist, cf: CFrame)
	f.part.CFrame = cf
	f.crystal.CFrame = cf * CFrame.new(0, f.part.Size.Y / 2 + f.crystal.Size.Y / 2, 0)
end

local function clearMark(f: Fist)
	if f.mark then
		f.mark:Destroy()
		f.mark = nil
	end
end

local function slamMark(self: any, f: Fist): BasePart
	local mark = Instance.new("Part")
	mark.Name = "SlamMark"
	mark.Shape = Enum.PartType.Cylinder
	mark.Size = Vector3.new(0.2, T.SlamRadius * 2, T.SlamRadius * 2)
	mark.Color = Palette.ForNeon(Palette.Glitch)
	mark.Material = Enum.Material.Neon
	mark.Transparency = 0.55
	mark.Anchored = true
	mark.CanCollide = false
	mark.CanQuery = false
	mark.CanTouch = false
	mark.Parent = self.fx
	return mark
end

local function clampToArena(self: any, pos: Vector3): Vector3
	local b = self.bounds
	return Vector3.new(math.clamp(pos.X, b.min.X, b.max.X), pos.Y, math.clamp(pos.Z, b.min.Z, b.max.Z))
end

local function fistIsFrozen(self: any, f: Fist): boolean
	return f.part:GetAttribute("Frozen") == true or self.king:GetAttribute("Frozen") == true
end

local function hover(self: any, f: Fist, xz: Vector3): CFrame
	return CFrame.new(xz.X, self.floorTop + T.Hover + f.part.Size.Y / 2, xz.Z)
end

local function updateFist(self: any, f: Fist, dt: number)
	if fistIsFrozen(self, f) then
		return
	end
	local speed = self.speed
	f.t += dt * speed
	local floorY = self.floorTop + f.part.Size.Y / 2
	if f.state == "Track" then
		local root = f.target and rootOf(f.target)
		local goal = if root then clampToArena(self, root.Position) else f.part.Position
		local cur = f.part.Position
		local want = hover(self, f, goal)
		local lift = math.min(f.t / 0.5, 1) -- rise to hover height on the way out
		local y = cur.Y + (want.Y - cur.Y) * lift
		local xz = Vector3.new(cur.X, 0, cur.Z):Lerp(Vector3.new(goal.X, 0, goal.Z), math.min(dt * speed * 4, 1))
		placeFist(f, CFrame.new(xz.X, y, xz.Z))
		if not f.mark then
			f.mark = slamMark(self, f)
		end
		local mark = f.mark :: BasePart
		mark.CFrame = CFrame.new(xz.X, self.floorTop + 0.15, xz.Z) * CFrame.Angles(0, 0, math.rad(90))
		mark.Transparency = 0.75 - 0.35 * math.min(f.t / T.Track, 1)
		if f.t >= T.Track then
			f.state, f.t, f.from = "Slam", 0, f.part.CFrame
		end
	elseif f.state == "Slam" then
		local a = math.min(f.t / T.SlamTime, 1)
		local p = f.from.Position
		placeFist(f, CFrame.new(p.X, p.Y + (floorY - p.Y) * a * a, p.Z))
		if a >= 1 then
			clearMark(f)
			Audio.play("PoundImpact", f.part.Position, 2)
			Audio.play("PoundDebris", f.part.Position, 1.5)
			for _, pl in DuoService.Players() do
				local root = rootOf(pl)
				if root then
					local flat = (root.Position - f.part.Position) * Vector3.new(1, 0, 1)
					if flat.Magnitude <= T.SlamRadius and root.Position.Y < self.floorTop + 9 then
						HealthService.Damage(pl, 1)
					end
				end
			end
			f.state, f.t = "Rest", 0
		end
	elseif f.state == "Rest" then
		if f.t >= T.Rest then
			f.state, f.t, f.from = "Rise", 0, f.part.CFrame
		end
	elseif f.state == "Rise" then
		local a = math.min(f.t / T.Rise, 1)
		local s = (1 - math.cos(a * math.pi)) / 2
		placeFist(f, f.from:Lerp(f.home, s))
		if a >= 1 then
			f.state, f.t, f.hit = "Idle", 0, false
			self.gap = T.Gap
		end
	end
end

-- one fist at a time: when both are home, the next one (left/right in turn) goes after the next target
local function runFists(self: any, dt: number)
	local busy = false
	for _, f in self.fists do
		updateFist(self, f, dt)
		busy = busy or f.state ~= "Idle"
	end
	if busy or self.king:GetAttribute("Frozen") then
		return
	end
	self.gap -= dt * self.speed
	if self.gap > 0 then
		return
	end
	local target = nextTarget(self)
	if not target then
		return
	end
	self.fistTurn = self.fistTurn % 2 + 1
	local f = self.fists[self.fistTurn]
	f.state, f.t, f.target = "Track", 0, target
end

local function homeFists(self: any)
	for _, f in self.fists do
		MoverService.Resume(f.part)
		clearMark(f)
		f.state, f.t, f.hit, f.target = "Idle", 0, false, nil
		placeFist(f, f.home)
	end
	self.gap = T.Gap * 2
end

-- Thrown blocks (phase 2) ---------------------------------------------------------------------------------------

local function throwBlock(self: any)
	-- only at players on the floor side of the gap: once Miko is on him she's busy climbing
	local target = nextTarget(self, function(p)
		local root = rootOf(p)
		return not root or root.Position.Z > self.gapStart or root.Position.Y > self.floorTop + 12
	end)
	if not target then
		return
	end
	local f = self.fists[self.fistTurn % 2 + 1]
	self.fistTurn = self.fistTurn % 2 + 1
	local size = T.BlockSize
	local from = f.part.Position + Vector3.new(0, f.part.Size.Y / 2 + size / 2, 0)
	local to = clampToArena(self, (rootOf(target) :: BasePart).Position)
	to = Vector3.new(to.X, self.floorTop + size / 2, to.Z)
	local part = Instance.new("Part")
	part.Name = "ThrownBlock"
	part.Size = Vector3.new(size, size, size)
	part.Color = Palette.Kai -- Kai's target (art-direction.md §6)
	part.Material = Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = CFrame.new(from)
	CollectionService:AddTag(part, "Freezable")
	part.Parent = self.fx
	table.insert(self.thrown, { part = part, from = from, to = to, t = 0 } :: Thrown)
	Audio.play("MeteorFall", from, 0.8)
end

local function updateThrown(self: any, dt: number)
	for i = #self.thrown, 1, -1 do
		local b: Thrown = self.thrown[i]
		local frozen = b.part:GetAttribute("Frozen") == true
		b.part.CanCollide = frozen -- a frozen block is a platform; a flying one never shoves anyone
		if frozen then
			continue
		end
		b.t += dt
		local a = math.min(b.t / T.ThrowTime, 1)
		local arc = T.ThrowArc + math.abs(b.from.Y - b.to.Y) * 0.5
		local pos = b.from:Lerp(b.to, a) + Vector3.new(0, arc * 4 * a * (1 - a), 0)
		b.part.CFrame = CFrame.new(pos) * CFrame.Angles(a * 3, a * 2, 0)
		if a >= 1 then
			Audio.play("PoundImpact", pos, 1.5)
			for _, pl in DuoService.Players() do
				local root = rootOf(pl)
				if root and (root.Position - pos).Magnitude <= T.BlockRadius then
					HealthService.Damage(pl, 1)
				end
			end
			b.part:Destroy()
			table.remove(self.thrown, i)
		end
	end
end

local function clearThrown(self: any)
	for _, b in self.thrown do
		b.part:Destroy()
	end
	table.clear(self.thrown)
end

-- Setup ---------------------------------------------------------------------------------------------------------

function Boss.Setup(self: any, world: Instance)
	local king = world:FindFirstChild("CrusherKing", true) :: Model
	local floor = world:FindFirstChild("BossFloor", true) :: Folder
	assert(king and floor, "[CrusherKing] arena not built")
	self.king = king
	self.turn = 0
	self.fistTurn = 0
	self.gap = 1.5
	self.speed = 1
	self.hits = 0
	self.token = 0
	self.falling = {} :: { [BasePart]: boolean }
	self.warned = {} :: { [BasePart]: boolean }
	self.thrown = {} :: { Thrown }

	self.fx = Instance.new("Folder")
	self.fx.Name = "BossFx"
	self.fx.Parent = world

	self.tiles = {} :: { BasePart }
	local minP, maxP = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, tile in floor:GetChildren() do
		if tile:IsA("BasePart") then
			tile:SetAttribute("Home", tile.CFrame)
			table.insert(self.tiles, tile)
			minP = minP:Min(tile.Position - tile.Size / 2)
			maxP = maxP:Max(tile.Position + tile.Size / 2)
			self.floorTop = tile.Position.Y + tile.Size.Y / 2
		end
	end
	local edge = 4 -- slam marks stay a little inside the floor
	self.bounds = { min = minP + Vector3.new(edge, 0, edge), max = maxP - Vector3.new(edge, 0, edge) }
	local rows = 0
	for _, tile in self.tiles do
		rows = math.max(rows, (tile:GetAttribute("Row") :: number) + 1)
	end
	self.dropFrom = rows - T.DropRows -- rows >= this fall away in phase 2
	local rowDepth = (maxP.Z - minP.Z) / rows
	self.gapStart = minP.Z + self.dropFrom * rowDepth

	self.fists = {}
	for _, s in { "L", "R" } do
		local part = king:FindFirstChild("Fist" .. s, true) :: BasePart
		local crystal = king:FindFirstChild("WristCrystal" .. s, true) :: BasePart
		table.insert(
			self.fists,
			{
				part = part,
				crystal = crystal,
				home = part.CFrame,
				state = "Idle",
				t = 0,
				from = part.CFrame,
				hit = false,
			} :: Fist
		)
	end
	self.crown = king:FindFirstChild("Crown", true) :: BasePart
	self.crownHome = self.crown.CFrame
	self.shield = king:FindFirstChild("GlitchShield", true) :: BasePart

	self.poundConn = InteractableService.Pounded:Connect(function(p: Player, pos: Vector3)
		if self.onPound then
			self.onPound(p, pos)
		end
	end)
	setHealth(self)
end

function Boss.Cleanup(self: any)
	if self.poundConn then
		self.poundConn:Disconnect()
	end
	self.token += 1
	if self.fx then
		self.fx:Destroy()
	end
end

-- Phases --------------------------------------------------------------------------------------------------------

-- Intro (user, Oct 12: "same with the last world pixel plain boss"): while W1_BossIntro plays he breathes and sways
-- on his throne, his fists bob, and as the camera reaches his face both fists rise and slam the floor (no damage:
-- camera shake + dust). The stop function eases everything back and lands it exactly as built.
function Boss.Intro(world: Instance, shots: { any }): () -> ()
	local king = world:FindFirstChild("CrusherKing", true) :: Model?
	local floor = world:FindFirstChild("BossFloor", true)
	if not (king and floor) then
		return function() end
	end
	local floorTop = -math.huge
	for _, tile in floor:GetChildren() do
		if tile:IsA("BasePart") then
			floorTop = math.max(floorTop, tile.Position.Y + tile.Size.Y / 2)
		end
	end
	local saved: { [BasePart]: CFrame } = {}
	for _, d in king:GetDescendants() do
		if d:IsA("BasePart") and d.Anchored then
			saved[d] = d.CFrame
		end
	end
	local fists: { BasePart } = {}
	for _, s in { "L", "R" } do
		local f = king:FindFirstChild("Fist" .. s, true)
		if f and f:IsA("BasePart") then
			table.insert(fists, f)
		end
	end
	local pivot = king:GetPivot()
	-- his close-up starts after the drone flight and the first plain shot
	local face, plain = 0, 0
	for _, shot in shots do
		if shot.Glide then
			face += shot.Duration
		elseif plain == 0 then
			plain = shot.Duration
		end
	end
	face += plain
	local closeUp, plains = 3, 0
	for _, shot in shots do
		if not shot.Glide then
			plains += 1
			if plains == 2 then
				closeUp = shot.Duration -- the second plain shot: his face
				break
			end
		end
	end
	local SLAM = closeUp + 0.9
	local t, slammed = 0, false
	local blend = 1 -- 1 = alive, eased to 0 by stop()
	local function pose()
		local breathe = math.sin(t * 0.35 * math.pi * 2)
		local body = CFrame.new(0, breathe * 0.35 * blend, 0) * CFrame.Angles(0, math.sin(t * 0.5) * 0.025 * blend, 0)
		for part, cf in saved do
			part.CFrame = pivot * body * pivot:ToObjectSpace(cf)
		end
		-- fists: a slow hover, then up (face + 0.4..1.2 s) and down onto the floor (by face + 1.5), held, back up
		local k = t - face
		for i, f in fists do
			local home = saved[f]
			local lift = math.sin(t * 1.3 + i) * 0.8
			-- up beside his head during the close-up (k 0.4..1.4), held, then slammed down early in the wide arena shot
			-- (SLAM: the face shot frames only his head, so a slam there fell out of view), held, back up
			local floorLift = floorTop + f.Size.Y / 2 - home.Position.Y
			if k > 0.4 and k < 1.4 then
				lift += 9 * math.sin((k - 0.4) / 1.0 * math.pi / 2)
			elseif k >= 1.4 and k < SLAM - 0.3 then
				lift += 9
			elseif k >= SLAM - 0.3 and k < SLAM then
				lift = 9 + (floorLift - 9) * ((k - SLAM + 0.3) / 0.3) ^ 2
			elseif k >= SLAM and k < SLAM + 2 then
				lift = floorLift * (1 - math.clamp((k - SLAM - 0.9) / 1.1, 0, 1))
			end
			f.CFrame = f.CFrame + Vector3.new(0, lift * blend, 0)
		end
		if not slammed and k >= SLAM then
			slammed = true
			Net.event("CameraShake"):FireAllClients(pivot.Position, 1.2, 0.8)
			for _, f in fists do
				local at = Vector3.new(f.Position.X, floorTop, f.Position.Z)
				Audio.play("PoundImpact", at)
				local dust = Instance.new("Part")
				dust.Anchored, dust.CanCollide, dust.CanQuery, dust.CanTouch = true, false, false, false
				dust.Transparency, dust.Size, dust.Position = 1, Vector3.one, at
				local e = Instance.new("ParticleEmitter")
				e.Texture = "rbxasset://textures/particles/smoke_main.dds"
				e.Color = ColorSequence.new(Color3.fromRGB(220, 210, 190))
				e.Size = NumberSequence.new(3, 7)
				e.Transparency = NumberSequence.new(0.4, 1)
				e.Lifetime = NumberRange.new(0.8, 1.4)
				e.Speed = NumberRange.new(10, 18)
				e.SpreadAngle = Vector2.new(80, 10)
				e.Enabled = false
				e.Parent = dust
				dust.Parent = workspace
				e:Emit(24)
				task.delay(2, dust.Destroy, dust)
			end
		end
	end
	local conn = RunService.Heartbeat:Connect(function(dt)
		t += dt
		pose()
	end)
	return function()
		conn:Disconnect()
		local left = 0.8
		conn = RunService.Heartbeat:Connect(function(dt)
			t += dt
			left -= dt
			blend = math.max(0, left / 0.8)
			pose()
			if left <= 0 then
				conn:Disconnect()
				for part, cf in saved do
					part.CFrame = cf
				end
			end
		end)
	end
end

Boss.Phases = {
	{
		Name = "Fists",
		Enter = function(self)
			-- a restart at a later phase skips this one: count its hits as done
			self.hits = 0
			setHealth(self)
			self.onPound = function(p: Player, pos: Vector3)
				if not mayPound(p) then
					return
				end
				for _, f in self.fists do
					if not f.hit and f.part:GetAttribute("Frozen") and poundOn(f.part, pos, 1) then
						f.hit = true
						self.hits += 1
						setHealth(self)
						flash(f.crystal)
						Audio.play("GlitchStatic", f.crystal.Position, 2)
						Audio.play("EnemyHit", f.crystal.Position, 2)
						task.delay(T.ShakeOff, function()
							MoverService.Resume(f.part) -- he shakes the fist free and pulls it back
							if f.state ~= "Idle" then
								f.state, f.t, f.from = "Rise", 0, f.part.CFrame
							end
						end)
					end
				end
			end
		end,
		Update = function(self, dt)
			runFists(self, dt)
		end,
		IsDone = function(self)
			return self.hits >= T.CrystalHits
		end,
		Exit = function(self)
			self.onPound = nil
			homeFists(self)
		end,
	},
	{
		Name = "Falling Floor",
		Enter = function(self)
			self.hits = T.CrystalHits
			setHealth(self)
			homeFists(self)
			Audio.play("GlitchCrackle", self.crown.Position, 2)
			-- the rows in front of him fall away in a wave, nearest first
			for _, tile in self.tiles do
				local row = tile:GetAttribute("Row") :: number
				if row >= self.dropFrom then
					task.delay((row - self.dropFrom) * -0.25 + 0.75, crumble, self, tile, 0.6, nil)
				end
			end
			self.throwT = 2.5
			self.crumbleT = T.CrumbleEvery
			self.shoulders = {}
			for _, s in { "L", "R" } do
				local c = self.king:FindFirstChild("ShoulderCrystal" .. s, true) :: BasePart
				c.Transparency = 0
				c.Material = Enum.Material.Neon
				self.shoulders[c] = false
			end
			self.onPound = function(p: Player, pos: Vector3)
				for c, done in self.shoulders do
					if not done and poundOn(c, pos, 3) then
						self.shoulders[c] = true
						self.hits += 1
						setHealth(self)
						c.Material = Enum.Material.SmoothPlastic
						c.Transparency = 0.6
						flash(c)
						Audio.play("GlitchStatic", c.Position, 2)
						Audio.play("EnemyHit", c.Position, 2)
					end
				end
			end
		end,
		Update = function(self, dt)
			parkFallen(self)
			updateThrown(self, dt)
			self.throwT -= dt
			if self.throwT <= 0 then
				self.throwT = T.ThrowEvery
				throwBlock(self)
			end
			self.crumbleT -= dt
			if self.crumbleT <= 0 then
				self.crumbleT = T.CrumbleEvery
				local pick = {}
				for _, tile in self.tiles do
					if
						(tile:GetAttribute("Row") :: number) < self.dropFrom
						and not self.warned[tile]
						and not tile:GetAttribute("Safe") -- under the checkpoint: respawns land on it
					then
						table.insert(pick, tile)
					end
				end
				if #pick > 0 then
					crumble(self, pick[math.random(#pick)], T.CrumbleWarn, T.CrumbleBack)
				end
			end
		end,
		IsDone = function(self)
			for _, done in self.shoulders do
				if not done then
					return false
				end
			end
			return true
		end,
		Exit = function(self)
			self.onPound = nil
			clearThrown(self)
			restoreAll(self)
		end,
	},
	{
		Name = "Crown",
		Enter = function(self)
			self.hits = T.CrystalHits + 2
			setHealth(self)
			restoreAll(self)
			homeFists(self)
			self.speed = T.Phase3Speed
			CollectionService:AddTag(self.king, "Freezable")
			Audio.play("GlitchCrackle", self.crown.Position, 2)
		end,
		Update = function(self, dt)
			local frozen = self.king:GetAttribute("Frozen") == true
			self.shield.Transparency = if frozen then 1 else 0.35
			if frozen then
				CollectionService:AddTag(self.crown, "Pullable")
			else
				CollectionService:RemoveTag(self.crown, "Pullable")
			end
			runFists(self, dt)
		end,
		IsDone = function(self)
			return (self.crown.Position - self.crownHome.Position).Magnitude > 6
		end,
		Exit = function(self)
			self.hits = TOTAL_HITS
			setHealth(self)
			CollectionService:RemoveTag(self.king, "Freezable")
			CollectionService:RemoveTag(self.crown, "Pullable")
			MoverService.Resume(self.king)
			self.shield.Transparency = 1
			for _, f in self.fists do
				clearMark(f)
			end
			-- he comes apart block by block (the crown stays with Miko)
			Audio.play("GlitchCrackle", self.king:GetPivot().Position, 3)
			Audio.play("MeteorImpact", self.king:GetPivot().Position, 1)
			for _, part in self.king:GetDescendants() do
				if part:IsA("BasePart") and part ~= self.crown then
					CollectionService:RemoveTag(part, "Freezable")
					part.CanCollide = false
					part.Anchored = false
					part.AssemblyLinearVelocity =
						Vector3.new(math.random(-20, 20), math.random(10, 40), math.random(-5, 25))
					TweenService:Create(part, TweenInfo.new(2.5), { Transparency = 1 }):Play()
					task.delay(3, part.Destroy, part)
				end
			end
		end,
	},
}

return Boss
