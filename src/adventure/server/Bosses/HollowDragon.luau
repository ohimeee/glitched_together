-- The Hollow Dragon (World 2 boss, top-down; mechanics.md §5, Story Line 2-3). The dragon Kai and Miko drew as the
-- castle's final boss, its middle eaten hollow by the Glitch. The hall and its body are built by Greybox
-- (buildStarfallCastle, THE HOLLOW THRONE); this runs the fight.
--   1. Static breath: a beam aimed at one player (targets alternate). While it breathes it rears, its wings lift and
--      the four scales on its flanks open. Miko's raised shield stops the beam for everyone behind her; Kai burns
--      the open scales (3 fireballs each).
--   2. Skies: it flies circles over the hall and calls skeletons and archers. Every minion that falls charges
--      Kai's Meteor. Every LandEvery s it lands (danger ring first) and lies grounded; a Meteor on it counts.
--   3. Static wall: a wall of static splits the hall with one gap that moves. The Glitch lets only Miko's light
--      through: Kai fires into Miko's raised shield at the gap and the reflected shots hit the open heart.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)
local Net = require(ReplicatedStorage.Shared.Net)
local Services = script.Parent.Parent.Services
local CombatService = require(Services.CombatService)
local CombatFx = require(Services.CombatFx)
local DuoService = require(Services.DuoService)

local T = Tuning.HollowDragon
local TOTAL_HITS = 4 + T.MeteorHits + T.HeartHits -- scales, grounded Meteors, heart: the boss bar
local WALL_Z = 1575 -- section-free: the castle is built in absolute coordinates (Greybox)
local GAPS = { -28, 0, 28 }
local CLOSED = Color3.fromRGB(120, 70, 40) -- a shut scale: dull, still Kai's color family
local BURNT = Color3.fromRGB(30, 26, 34)

local Boss = {}

local function rootOf(p: Player): BasePart?
	return p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function setHealth(self: any)
	workspace:SetAttribute("BossHealth", math.max(0, 1 - self.hits / TOTAL_HITS))
end

local function flash(part: BasePart)
	local color = part.Color
	part.Color = Color3.new(1, 1, 1)
	task.delay(Tuning.BossHitFlash, function()
		if part.Color == Color3.new(1, 1, 1) then
			part.Color = color
		end
	end)
end

-- the whole dragon blinks white (its grey-box parts are invisible under the skins)
local function hurtFlash(self: any)
	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.new(1, 1, 1)
	hl.FillTransparency = 0.35
	hl.OutlineTransparency = 1
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Parent = self.dragon
	task.delay(Tuning.BossHitFlash, hl.Destroy, hl)
end

-- targets alternate between the two players (design.md §6); Downed players sit out
local function nextTarget(self: any): Player?
	local duo = DuoService.Players()
	for _ = 1, #duo do
		self.turn = self.turn % math.max(#duo, 1) + 1
		local p = duo[self.turn]
		if p and rootOf(p) and not p:GetAttribute("Downed") then
			return p
		end
	end
	return nil
end

local function fxPart(self: any, name: string, size: Vector3, cf: CFrame, color: Color3, transparency: number): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = transparency
	p.Size = size
	p.CFrame = cf
	p.Parent = self.fx
	return p
end

-- Body pose ------------------------------------------------------------------------------------------------------

-- the whole dragon from its home pose: `base` replaces the pivot, `yaw` turns head + neck about the neck's root,
-- `lift` raises the wings (0 = folded over the flanks, 1 = up, scales showing)
-- Phases set a target pose (pose()); animate() runs every frame, eases toward it and layers life on top (user, Oct 10:
-- the first version's movement "feels hard": parts snapped and stayed rigid). `snap` jumps straight to the target.
--   base  the whole body (pivot)        yaw   head + neck turn about the neck root
--   lift  wings (0 folded, 1 up)        pitch head rears (-) / lunges (+)
--   flap  wing beat amplitude (flight)
local function pose(self: any, base: CFrame, yaw: number, lift: number, snap: boolean?)
	self.target.base, self.target.yaw, self.target.lift = base, yaw, lift
	if snap then
		self.cur.base, self.cur.yaw, self.cur.lift = base, yaw, lift
	end
	self.base, self.yaw, self.lift = base, yaw, lift
end

local function ease(a: number, b: number, rate: number, dt: number): number
	return b + (a - b) * math.exp(-rate * dt)
end

local function animate(self: any, dt: number)
	local cur, tgt = self.cur, self.target
	local k = 1 - math.exp(-T.EaseBase * dt)
	cur.base = cur.base:Lerp(tgt.base, k)
	cur.yaw = ease(cur.yaw, tgt.yaw, T.EaseHead, dt)
	cur.lift = ease(cur.lift, tgt.lift, T.EaseWings, dt)
	cur.pitch = ease(cur.pitch or 0, tgt.pitch or 0, T.EaseHead, dt)
	cur.flap = ease(cur.flap or 0, tgt.flap or 0, 3, dt)
	cur.roll = ease(cur.roll or 0, tgt.roll or 0, 2.5, dt)
	local t = os.clock()
	local airborne = (tgt.flap or 0) > 0
	-- breathing: the chest rises and falls; slower and deeper while it lies still
	local breathe = math.sin(t * T.BreathRate * math.pi * 2)
	-- it hovers: a slow bob in time with the wingbeat (on the ground only the chest moves)
	local bob = if airborne then math.sin(t * T.FlapRate * math.pi * 2 - 1.2) * 0.9 else breathe * 0.25
	-- one body mesh: aiming turns the whole dragon about its claws; rearing (+) / lunging (-) tips it about them,
	-- with a slight sway so it never stands frozen
	local sway = math.sin(t * 0.7) * 0.03
	local base = cur.base * CFrame.new(0, bob, 0) * CFrame.Angles(cur.pitch + 0.015 * breathe, cur.yaw + sway, cur.roll)
	local beat = cur.flap * math.sin(t * T.FlapRate * math.pi * 2)
	local wingAngle = math.rad(T.WingAngle) * (cur.lift + beat) + 0.02 * breathe
	for part, offset in self.offsets do
		local cf
		if self.wings[part] then
			local side = self.wings[part]
			local hinge = base * self.wingHinge[part]
			cf = hinge * CFrame.Angles(0, 0, side * wingAngle) * hinge:Inverse() * (base * offset)
		else
			cf = base * offset
		end
		part.CFrame = cf
	end
end

local function mouth(self: any): Vector3
	return self.head.Position -- the Head part sits on its snout
end

local function setScales(self: any, open: boolean)
	self.open = open
	for _, s in self.scales do
		if not s.burnt then
			s.part.Color = if open then Palette.Kai else CLOSED
			s.part.Material = if open then Enum.Material.Neon else Enum.Material.SmoothPlastic
		end
	end
end

local function burnScale(s: any)
	s.burnt = true
	CollectionService:RemoveTag(s.part, "BossHurt")
	s.part.Color = BURNT
	s.part.Material = Enum.Material.Slate
end

local function setFlying(self: any, flying: boolean)
	for part in self.offsets do
		part.CanCollide = (not flying) and part:GetAttribute("Collide") == true
	end
	-- airborne it's half static: see-through, so it never hides the players under it from the top-down camera
	-- (skins only: a grey-box holder still waiting for its mesh must never be stored as "solid", or it shows up as a
	-- box after landing)
	for _, d in self.dragon:GetDescendants() do
		if
			d:IsA("BasePart")
			and d:GetAttribute("Skin") == nil
			and (d.Transparency < 1 or d:GetAttribute("SolidT") ~= nil)
		then
			if flying and d:GetAttribute("SolidT") == nil then
				d:SetAttribute("SolidT", d.Transparency)
				d.Transparency = math.max(d.Transparency, T.FlyGhost)
			elseif not flying and d:GetAttribute("SolidT") ~= nil then
				d.Transparency = d:GetAttribute("SolidT")
				d:SetAttribute("SolidT", nil)
			end
		end
	end
end

-- Phase 1: static breath -------------------------------------------------------------------------------------------

local function clearBreath(self: any)
	if self.aim then
		self.aim:Destroy()
		self.aim = nil
	end
	for _, name in { "beamFloor", "beamFall" } do
		if self[name] then
			self[name]:Destroy()
			self[name] = nil
		end
	end
	self.beam = nil
end

local function aimAt(self: any, target: Player?, dt: number?)
	local root = target and rootOf(target)
	if not root then
		return
	end
	local from = mouth(self)
	local want = flat(root.Position - from)
	if want.Magnitude < 1 then
		return
	end
	want = want.Unit
	if dt then -- the beam swings after its target at BreathTurn deg/s
		local cur = self.dir
		local ang = math.acos(math.clamp(cur:Dot(want), -1, 1))
		local step = math.min(ang, math.rad(T.BreathTurn) * dt)
		if ang > 1e-3 then
			local sign = if cur:Cross(want).Y >= 0 then 1 else -1
			self.dir = (CFrame.Angles(0, sign * step, 0) * cur).Unit
		end
	else
		self.dir = want
	end
	-- the dragon turns its whole body to follow (clamped: it never shows its back to the hall)
	local yaw = math.atan2(-self.dir.X, -self.dir.Z)
	pose(self, self.base, math.clamp(yaw, -0.6, 0.6), self.lift)
end

-- how far the beam reaches: a raised shield facing the mouth stops it; returns (length, blocker)
local function beamReach(self: any, from: Vector3): (number, Player?)
	local best, blocker = T.BreathLength, nil
	for _, p in DuoService.Players() do
		local r = rootOf(p)
		if r and p:GetAttribute("Blocking") and CombatService.ShieldCovers(p, from) then
			local rel = flat(r.Position - from)
			local along = rel:Dot(self.dir)
			local off = (rel - self.dir * along).Magnitude
			if along > 0 and along < best and off <= T.BreathWidth / 2 + 1.5 then
				best, blocker = along, p
			end
		end
	end
	return best, blocker
end

local function drawBeam(self: any, from: Vector3, length: number)
	-- from the mouth (high up) to the floor where it stops: the breath pours down onto the hall
	local floorFrom = Vector3.new(from.X, 2, from.Z)
	local stop = floorFrom + self.dir * length
	local reach = Vector3.new(from.X, 2, from.Z) + self.dir * math.min(length, 14) -- it hits the floor near the mouth
	local function bar(name: string, a: Vector3, b: Vector3): Part
		local d = (b - a).Magnitude
		local cf = CFrame.lookAt((a + b) / 2, b)
		local bar = self[name]
		if not bar then
			bar = fxPart(
				self,
				"StaticBreath",
				Vector3.new(T.BreathWidth, T.BreathWidth * 0.6, d),
				cf,
				Palette.Glitch,
				0.25
			)
			CombatFx.Emit(bar, "Stars", 2, 30, Palette.Glitch)
			self[name] = bar
		end
		bar.Size = Vector3.new(T.BreathWidth, T.BreathWidth * 0.6, d)
		bar.CFrame = cf
		return bar
	end
	self.beam = bar("beamFloor", reach, stop)
	bar("beamFall", from, reach)
end

local function stepBreath(self: any, dt: number)
	local b = self.breath
	b.t -= dt
	if b.state == "Wait" then
		if b.t <= 0 then
			b.target = nextTarget(self)
			if not b.target then
				b.t = 1
				return
			end
			b.state, b.t = "Windup", T.BreathWindup
			setScales(self, true)
			pose(self, self.base, self.yaw, 1)
			self.target.pitch = T.Rear -- it rears back, wings up, drawing breath
			aimAt(self, b.target)
			Audio.play("GlitchCrackle", self.head.Position, 2)
		end
	elseif b.state == "Windup" then
		aimAt(self, b.target)
		local from = mouth(self)
		local mid = from + self.dir * (T.BreathLength / 2)
		local cf = CFrame.lookAt(Vector3.new(mid.X, 0.15, mid.Z), Vector3.new(mid.X, 0.15, mid.Z) + self.dir)
		if not self.aim then
			self.aim = fxPart(self, "BreathAim", Vector3.new(1, 0.1, T.BreathLength), cf, Palette.Danger, 0.4)
		end
		self.aim.CFrame = cf
		self.aim.Transparency = 0.2 + 0.4 * (b.t / T.BreathWindup) -- brightens as it comes
		if b.t <= 0 then
			b.state, b.t, b.tick = "Breathe", T.BreathTime, 0
			self.target.pitch = -T.Lunge -- ...and lunges into the breath
			clearBreath(self)
			Audio.play("StaticShot", self.head.Position, 2)
		end
	elseif b.state == "Breathe" then
		aimAt(self, b.target, dt)
		local from = mouth(self)
		local length, blocker = beamReach(self, from)
		drawBeam(self, from, length)
		b.tick -= dt
		if b.tick <= 0 then
			b.tick = T.BreathTick
			for _, p in DuoService.Players() do
				local r = rootOf(p)
				if r and not p:GetAttribute("Downed") then
					local rel = flat(r.Position - from)
					local along = rel:Dot(self.dir)
					local off = (rel - self.dir * along).Magnitude
					local inside = along > 0 and off <= T.BreathWidth / 2 + 1
					-- the blocker takes it on the shield (HitPlayer charges her Rally); everyone behind her is safe
					if p == blocker or (inside and along < length - 0.5) then
						CombatService.HitPlayer(p, T.BreathDamage, from)
					end
				end
			end
		end
		if b.t <= 0 then
			b.state, b.t = "Wait", T.BreathEvery
			clearBreath(self)
			setScales(self, false)
			pose(self, self.base, 0, 0)
			self.target.pitch = 0
		end
	end
end

-- Phase 2: skies ---------------------------------------------------------------------------------------------------

local MINION_LOOKS = {
	Skeleton = { Vector3.new(3, 5, 2), Color3.fromRGB(230, 225, 210) },
	StaticArcher = { Vector3.new(3, 5, 2), Color3.fromRGB(170, 165, 200) },
}

local function summon(self: any)
	local alive = 0
	for m in self.minions do
		if m.Parent then
			alive += 1
		end
	end
	for _ = 1, 2 do
		if alive >= T.MaxMinions or #self.spawns == 0 then
			return
		end
		local kind = if math.random() < 0.6 then "Skeleton" else "StaticArcher"
		local look = MINION_LOOKS[kind]
		local at = self.spawns[math.random(#self.spawns)].Position
		local body = Instance.new("Part")
		body.Name = kind
		body.Size = look[1]
		body.Color = look[2]
		body.Anchored = true
		body.CFrame = CFrame.new(at.X, look[1].Y / 2, at.Z)
		body:SetAttribute("Type", kind)
		body:SetAttribute("NoXp", true) -- they charge Kai's Meteor instead (and no level-up pause mid-fight)
		CollectionService:AddTag(body, "Enemy")
		body.Parent = self.world
		CombatFx.Burst(body.Position, { { "Stars", 14, 1.5, Palette.Glitch } }, Palette.Glitch, 10)
		self.minions[body] = true
		body.AncestryChanged:Connect(function(_, parent)
			if parent == nil and self.minions[body] then
				self.minions[body] = nil
				if self.phase == "Skies" then -- it fell in the fight: Kai's Meteor charges
					for _, p in DuoService.Players() do
						if p:GetAttribute("Role") == "Kai" or #DuoService.Players() < 2 then
							p:SetAttribute("Ultimate", math.min(1, (p:GetAttribute("Ultimate") or 0) + T.MinionCharge))
						end
					end
				end
			end
		end)
		alive += 1
	end
end

local function clearMinions(self: any)
	local list = {}
	for m in self.minions do
		table.insert(list, m)
	end
	table.clear(self.minions)
	for _, m in list do
		m:Destroy()
	end
end

local function setGrounded(self: any, on: boolean)
	if on and not self.groundBox then
		local body = self.body
		self.groundBox =
			fxPart(self, "GroundedHurt", Vector3.new(18, 12, 24), self.base * CFrame.new(0, 6, -2), Palette.Kai, 1)
		CollectionService:AddTag(self.groundBox, "BossHurt")
		self.groundBox:SetAttribute("Kind", "Body")
	elseif not on and self.groundBox then
		self.groundBox:Destroy()
		self.groundBox = nil
	end
end

local function stepSkies(self: any, dt: number)
	local s = self.sky
	s.t -= dt
	s.summon -= dt
	if s.state ~= "Grounded" and s.summon <= 0 then
		s.summon = T.SummonEvery
		summon(self)
	end
	if s.state == "Rise" then
		local a = 1 - math.max(s.t, 0) / 1.5
		pose(self, self.home * CFrame.new(0, T.FlyHeight * a * a, 0), 0, 0.45)
		self.target.flap = T.Flap * 1.4
		if s.t <= 0 then
			s.state, s.t, s.angle = "Fly", T.LandEvery, 0
		end
	elseif s.state == "Fly" then
		-- a wide, slow strafe over the hole that always faces the hall (user, Oct 10: the tight loop over the players
		-- spun it round and tipped it sideways: "quite broken when flying"); it only leans and turns a little toward
		-- where it's going, like a boss keeping its eyes on you
		s.angle += dt * math.pi * 2 / T.LapTime
		local c = self.loopCenter
		local pos = c + Vector3.new(math.sin(s.angle) * T.LoopX, T.FlyHeight, math.cos(s.angle) * T.LoopZ)
		local side = math.cos(s.angle) -- -1..1: sideways speed (+X)
		pose(self, CFrame.new(pos) * self.home.Rotation * CFrame.Angles(0, -side * T.FlyTurn, 0), 0, 0.45)
		self.target.flap = T.Flap
		self.target.roll = side * T.Bank
		self.shadow.CFrame = CFrame.new(pos.X, 0.12, pos.Z) * CFrame.Angles(0, 0, math.pi / 2)
		if s.t <= 0 then
			s.spot = self.landSpots[math.random(#self.landSpots)]
			s.from = self.base
			s.state, s.t = "Warn", T.LandWarn
			self.target.roll = 0
			self.target.flap = T.Flap * 1.4 -- big back-beats as it drops
			s.ring = CombatFx.AreaMarker(s.spot + Vector3.new(0, 0.12, 0), T.LandRadius, Palette.Danger)
			s.ring.Parent = self.fx
			Audio.play("GlitchCrackle", s.spot, 2)
		end
	elseif s.state == "Warn" then
		local a = 1 - math.max(s.t, 0) / T.LandWarn
		local over = CFrame.new(s.spot + Vector3.new(0, T.FlyHeight * (1 - a * a), 0)) * self.home.Rotation
		pose(self, s.from:Lerp(over, math.min(a * 1.6, 1)), 0, 0.45 * (1 - a))
		self.shadow.CFrame = CFrame.new(self.base.Position.X, 0.12, self.base.Position.Z)
			* CFrame.Angles(0, 0, math.pi / 2)
		if s.t <= 0 then
			pose(self, CFrame.new(s.spot) * self.home.Rotation, 0, 0)
			self.target.flap = 0
			self.cur.base = self.target.base -- it lands where the ring said
			s.ring:Destroy()
			s.ring = nil
			Audio.play("MeteorImpact", s.spot, 1)
			CombatFx.Burst(s.spot + Vector3.new(0, 1, 0), { { "Smoke", 18, 4, Color3.new(1, 1, 1) } })
			for _, p in DuoService.Players() do
				local r = rootOf(p)
				if r and flat(r.Position - s.spot).Magnitude <= T.LandRadius then
					CombatService.HitPlayer(p, T.LandDamage, s.spot)
				end
			end
			setFlying(self, false)
			setGrounded(self, true)
			s.state, s.t = "Grounded", T.Grounded
		end
	elseif s.state == "Grounded" then
		if s.t <= 0 then
			setGrounded(self, false)
			setFlying(self, true)
			s.from = self.base
			self.target.flap = T.Hover
			s.state, s.t = "TakeOff", 1.2
			self.target.flap = T.Flap * 1.4
		end
	elseif s.state == "TakeOff" then
		local a = 1 - math.max(s.t, 0) / 1.2
		pose(self, s.from * CFrame.new(0, T.FlyHeight * a * a, 0), 0, 0.45)
		if s.t <= 0 then
			local rel = self.base.Position - self.loopCenter
			s.angle = math.atan2(rel.X / T.LoopX, rel.Z / T.LoopZ)
			s.state, s.t = "Fly", T.LandEvery
		end
	end
end

-- Phase 3: the static wall ----------------------------------------------------------------------------------------

local function buildWall(self: any, gapX: number)
	if self.wall then
		self.wall:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "StaticWall"
	folder.Parent = self.fx
	self.wall = folder
	self.gapX = gapX
	local half = T.GapWidth / 2
	for _, span in { { -48, gapX - half }, { gapX + half, 48 } } do
		local w = span[2] - span[1]
		if w > 0.5 then
			local p = fxPart(
				self,
				"Static",
				Vector3.new(w, 9, 1.5),
				CFrame.new((span[1] + span[2]) / 2, 4.5, WALL_Z),
				Palette.Glitch,
				0.3
			)
			p.CanCollide = true
			p.CanQuery = true -- shots stop on it (only the gap lets them through)
			p.Parent = folder
			CombatFx.Emit(p, "Stars", 1.5, 10, Palette.Glitch)
		end
	end
end

local function stepWall(self: any, dt: number)
	local w = self.wallState
	w.move -= dt
	if w.move <= 1 and not w.warned then
		w.warned = true
		for _, p in self.wall:GetChildren() do
			if p:IsA("BasePart") then
				p.Transparency = 0.05 -- it's about to move
			end
		end
	end
	if w.move <= 0 then
		w.move, w.warned = T.GapMove, false
		local options = {}
		for _, g in GAPS do
			if g ~= self.gapX then
				table.insert(options, g)
			end
		end
		buildWall(self, options[math.random(#options)])
		Audio.play("GlitchCrackle", Vector3.new(self.gapX, 4, WALL_Z), 2)
	end
	-- touching the static hurts (outside the gap)
	w.touch -= dt
	if w.touch <= 0 then
		w.touch = 0.5
		for _, p in DuoService.Players() do
			local r = rootOf(p)
			if r and math.abs(r.Position.Z - WALL_Z) < 2.2 and math.abs(r.Position.X - self.gapX) > T.GapWidth / 2 then
				CombatService.HitPlayer(p, T.WallDamage, Vector3.new(r.Position.X, 3, WALL_Z))
			end
		end
	end
	-- static bombs lobbed over the wall at one player
	w.bomb -= dt
	if w.bomb <= 0 then
		w.bomb = T.BombEvery
		local target = nextTarget(self)
		local r = target and rootOf(target)
		if r then
			local at = Vector3.new(r.Position.X, 0.12, r.Position.Z)
			local ring = CombatFx.AreaMarker(at, T.BombRadius, Palette.Danger)
			ring.Parent = self.fx
			local token = self.token
			task.delay(T.BombWarn, function()
				ring:Destroy()
				if self.token ~= token then
					return
				end
				Audio.play("GlitchStatic", at, 1.5)
				CombatFx.Burst(at + Vector3.new(0, 1, 0), { { "Stars", 20, 2, Palette.Glitch } }, Palette.Glitch, 12)
				for _, p in DuoService.Players() do
					local pr = rootOf(p)
					if pr and flat(pr.Position - at).Magnitude <= T.BombRadius then
						CombatService.HitPlayer(p, T.BombDamage, at + Vector3.new(0, 10, 0))
					end
				end
			end)
		end
	end
	-- the heart pulses
	self.heart.Transparency = 0.1 + 0.15 * math.sin(os.clock() * 5)
end

-- When it falls the Glitch lets go of the hall: the floor knits back over the hole, tile by tile, to the hidden room
local function knitBridge(self: any)
	local world = self.world
	local rail = world:FindFirstChild("EdgeRail", true)
	if rail and rail:IsA("BasePart") then
		for _, side in { -1, 1 } do -- keep the rail either side of the new path
			local r = rail:Clone()
			r.Size = Vector3.new(42, rail.Size.Y, rail.Size.Z)
			r.Position = rail.Position + Vector3.new(side * 27, 0, 0)
			r.Parent = rail.Parent
		end
		rail:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "KnitBridge"
	folder.Parent = world
	for i = 0, 7 do
		local tile = Instance.new("Part")
		tile.Name = "KnitFloor"
		tile.Anchored = true
		tile.Size = Vector3.new(12, 2, 8)
		tile.Material = Enum.Material.Cobblestone
		tile.Color = Palette.Castle.Stone
		tile.Transparency = 1
		tile.CanCollide = false
		tile.CFrame = CFrame.new(0, -1, 1604 + i * 8)
		tile.Parent = folder
		task.delay(1 + i * 0.35, function()
			tile.CanCollide = true
			TweenService:Create(tile, TweenInfo.new(0.4), { Transparency = 0 }):Play()
			CombatFx.Burst(tile.Position + Vector3.new(0, 1, 0), { { "Stars", 8, 1.2, Palette.Castle.Gold } })
		end)
	end
end

-- The pose rig (Setup and the intro): every grey-box part's offset from the pivot, the wings and their shoulder hinges.
local function rig(self: any, dragon: Model)
	self.home = dragon.WorldPivot
	self.base = self.home
	self.yaw, self.lift = 0, 0
	self.target = { base = self.home, yaw = 0, lift = 0, pitch = 0, flap = T.Hover, roll = 0 }
	self.cur = { base = self.home, yaw = 0, lift = 0, pitch = 0, flap = 0, roll = 0 }
	self.pivotTilt = CFrame.identity
	self.offsets = {} :: { [BasePart]: CFrame }
	self.headBits = {} :: { [BasePart]: boolean }
	self.wings = {} :: { [BasePart]: number }
	self.wingHinge = {} :: { [BasePart]: CFrame }
	for _, d in dragon:GetChildren() do -- the grey-box parts only: their skins are welded meshes that follow
		if d:IsA("BasePart") then
			self.offsets[d] = self.home:ToObjectSpace(d.CFrame)
			d:SetAttribute("Collide", d.CanCollide)
		end
	end
	self.body = dragon:FindFirstChild("Body", true) :: BasePart
	self.head = dragon:FindFirstChild("Head", true) :: BasePart
	self.heart = dragon:FindFirstChild("Heart", true) :: BasePart
	for _, s in { "L", "R" } do
		local wing = dragon:FindFirstChild("Wing" .. s, true) :: BasePart
		local side = if s == "L" then -1 else 1
		self.wings[wing] = side
		-- the wing's root on the shoulder (measured on the mesh; Greybox Hinge), else its inner edge
		local root = wing:GetAttribute("Hinge")
		local hinge = if typeof(root) == "Vector3"
			then root
			else (wing.CFrame * CFrame.new(-side * wing.Size.X / 2, 0, 0)).Position
		self.wingHinge[wing] = self.home:ToObjectSpace(CFrame.new(hinge))
	end
end

-- Setup ------------------------------------------------------------------------------------------------------------

function Boss.Setup(self: any, world: Instance)
	local dragon = world:FindFirstChild("HollowDragon", true) :: Model
	assert(dragon, "[HollowDragon] hall not built")
	self.world = world
	self.dragon = dragon
	self.turn = 0
	self.token = 0
	self.hits = 0
	self.minions = {} :: { [BasePart]: boolean }
	self.fx = Instance.new("Folder")
	self.fx.Name = "BossFx"
	self.fx.Parent = world

	rig(self, dragon)
	self.scales = {}
	for _, d in dragon:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Kind") == "Scale" then
			table.insert(self.scales, { part = d, hits = 0, burnt = false })
		end
	end
	self.landSpots, self.spawns = {}, {}
	for _, d in world:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name:match("^LandSpot") then
				table.insert(self.landSpots, d.Position)
			elseif d.Name:match("^MinionSpawn") then
				table.insert(self.spawns, d)
			end
		end
	end
	self.center = Vector3.new(0, 0, 1582)
	self.loopCenter = Vector3.new(0, 0, T.LoopCenterZ)
	-- the heart is hidden in its chest until phase 3 opens it (a neon cube glowing through the ghosted body read as
	-- a loose pink block in flight)
	self.heart.Transparency = 1
	self.heart.Shape = Enum.PartType.Ball
	local glow = self.heart:FindFirstChildOfClass("PointLight")
	if glow then
		glow.Enabled = false
	end
	-- a round shadow under it while it flies (a flat cylinder; the square one read as a slab)
	self.shadow = fxPart(self, "DragonShadow", Vector3.new(0.1, 30, 30), CFrame.new(0, -5, 0), Color3.new(0, 0, 0), 1)
	self.shadow.Shape = Enum.PartType.Cylinder
	self.shadow.Material = Enum.Material.SmoothPlastic

	self.hitConn = CombatService.BossHit:Connect(function(part: BasePart, damage: number, owner: Player?, how: string)
		if part:IsDescendantOf(self.dragon) or part:IsDescendantOf(self.fx) then
			if self.onHit then
				self.onHit(part, damage, owner, how)
			end
		end
	end)
	workspace:SetAttribute("TopDownZoom", T.Zoom)
	-- the castle camera looks back from +Z, right over the dragon (it sat off the bottom edge): look from the door
	-- side instead, and pull the view toward it
	workspace:SetAttribute("TopDownFlip", true)
	workspace:SetAttribute("TopDownBack", T.CameraBack)
	workspace:SetAttribute("TopDownFocus", T.Focus)
	workspace:SetAttribute("TopDownFocusWeight", T.FocusWeight)
	setScales(self, false)
	setHealth(self)
end

function Boss.Cleanup(self: any)
	if self.hitConn then
		self.hitConn:Disconnect()
	end
	self.token += 1
	self.phase = nil
	clearMinions(self)
	workspace:SetAttribute("TopDownZoom", nil)
	workspace:SetAttribute("TopDownFocus", nil)
	workspace:SetAttribute("TopDownFlip", nil)
	workspace:SetAttribute("TopDownBack", nil)
	workspace:SetAttribute("TopDownFocusWeight", nil)
	if self.fx then
		self.fx:Destroy()
	end
	-- back to the home pose if the fight stopped mid-flight (a game over rebuilds the world anyway)
	if self.dragon.Parent then
		pose(self, self.home, 0, 0, true)
		self.target.flap, self.target.roll, self.target.pitch = 0, 0, 0
		self.cur.flap, self.cur.roll, self.cur.pitch = 0, 0, 0
		animate(self, 0)
		setFlying(self, false)
	end
end

-- Phases -----------------------------------------------------------------------------------------------------------

local function burnAllScales(self: any)
	for _, s in self.scales do
		if not s.burnt then
			burnScale(s)
		end
	end
end

-- Intro (user, Oct 12: "the body is not moving... and what about the sounds"): while W2_BossIntro plays the dragon
-- hovers alive (breathing, wing beats), and as the camera reaches its face it rears back, wings up (camera shake,
-- static sparks). The stop function eases it back and lands every part where it was built, so the fight's Setup
-- measures the same pose.
function Boss.Intro(world: Instance, shots: { any }): () -> ()
	local dragon = world:FindFirstChild("HollowDragon", true) :: Model?
	if not dragon then
		return function() end
	end
	local self: any = {}
	local saved: { [BasePart]: CFrame } = {}
	for _, d in dragon:GetChildren() do
		if d:IsA("BasePart") then
			saved[d] = d.CFrame
		end
	end
	rig(self, dragon)
	-- the close-up starts after the drone flight and the first plain shot
	local face, plain = 0, 0
	for _, shot in shots do
		if shot.Glide then
			face += shot.Duration
		elseif plain == 0 then
			plain = shot.Duration
		end
	end
	face += plain
	local t, roared, settled = 0, false, false
	local conn = RunService.Heartbeat:Connect(function(dt)
		t += dt
		if not roared and t >= face + 0.3 then
			roared = true
			self.target.pitch = -T.Rear * 2.4
			self.target.lift = 1.3
			self.target.flap = T.Flap * 1.5
			Net.event("CameraShake"):FireAllClients(self.head.Position, 0.6, 1.6)
			CombatFx.Burst(self.head.Position, { { "Stars", 20, 2, Palette.Glitch } }, Palette.Glitch, 30)
		elseif roared and not settled and t >= face + 2.6 then
			settled = true
			self.target.pitch = T.Lunge
			self.target.lift = 0.4
			self.target.flap = T.Hover
		end
		animate(self, dt)
	end)
	return function()
		-- settle: wings down, no hover bob, head level, then land exactly on the built pose (an instant snap popped)
		self.target.pitch, self.target.lift, self.target.flap = 0, 0, 0
		local left = 0.9
		conn:Disconnect()
		conn = RunService.Heartbeat:Connect(function(dt)
			left -= dt
			animate(self, dt)
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
		Name = "Static Breath",
		Enter = function(self)
			self.phase = "Breath"
			self.hits = 0
			setHealth(self)
			self.breath = { state = "Wait", t = 2.5 }
			self.dir = Vector3.new(0, 0, -1)
			self.onHit = function(part: BasePart, _damage: number, _owner: Player?, how: string)
				if part:GetAttribute("Kind") ~= "Scale" or how == "Area" then
					return
				end
				for _, s in self.scales do
					if s.part == part and not s.burnt then
						if not self.open then
							Audio.play("ShieldBlock", part.Position) -- shut: the fire glances off
							return
						end
						s.hits += 1
						flash(part)
						Audio.play("EnemyHit", part.Position, 1.5)
						if s.hits >= T.ScaleHits then
							burnScale(s)
							self.hits += 1
							setHealth(self)
							Audio.play("GlitchCrackle", part.Position, 2)
							CombatFx.Burst(
								part.Position,
								{ { "Flame", 16, 2 }, { "Smoke", 6, 2, Color3.new(0.2, 0.2, 0.2) } }
							)
						end
					end
				end
			end
		end,
		Update = function(self, dt)
			stepBreath(self, dt)
			animate(self, dt)
		end,
		IsDone = function(self)
			for _, s in self.scales do
				if not s.burnt then
					return false
				end
			end
			return true
		end,
		Exit = function(self)
			self.onHit = nil
			clearBreath(self)
			setScales(self, false)
			pose(self, self.home, 0, 0, true)
		end,
	},
	{
		Name = "Skies",
		Enter = function(self)
			self.phase = "Skies"
			burnAllScales(self)
			self.hits = 4
			self.meteors = 0
			setHealth(self)
			setFlying(self, true)
			self.shadow.Transparency = 0.6
			self.sky = { state = "Rise", t = 1.5, summon = 1, angle = 0 }
			Audio.play("GlitchCrackle", self.body.Position, 3)
			self.onHit = function(part: BasePart, damage: number, owner: Player?, how: string)
				if how ~= "Area" or part ~= self.groundBox then
					return
				end
				local kai = owner and (owner:GetAttribute("Role") == "Kai" or #DuoService.Players() < 2)
				if not kai or damage < Tuning.FireMage.Meteor.Damage then
					return -- Rally only stuns; Kai's Meteor is what brings it down
				end
				self.meteors += 1
				self.hits += 1
				setHealth(self)
				hurtFlash(self)
				Audio.play("GlitchStatic", self.body.Position, 2)
				self.sky.t = math.min(self.sky.t, 0.4) -- it shakes it off and takes off
			end
		end,
		Update = function(self, dt)
			stepSkies(self, dt)
			animate(self, dt)
		end,
		IsDone = function(self)
			return self.meteors >= T.MeteorHits
		end,
		Exit = function(self)
			self.onHit = nil
			self.phase = nil
			clearMinions(self)
			setGrounded(self, false)
			if self.sky and self.sky.ring then
				self.sky.ring:Destroy()
			end
			self.shadow.Transparency = 1
			pose(self, self.home, 0, 0, true)
			setFlying(self, false)
		end,
	},
	{
		Name = "Static Wall",
		Enter = function(self)
			self.phase = "Wall"
			burnAllScales(self)
			self.hits = 4 + T.MeteorHits
			self.heartHits = 0
			local glow = self.heart:FindFirstChildOfClass("PointLight")
			if glow then
				glow.Enabled = true
			end
			setHealth(self)
			-- worn out, it sinks over the hole until its open chest is level with the hall (reflect height)
			pose(self, self.home * CFrame.new(0, -T.Sink, 0), 0, 0.3)
			self.target.flap = T.Hover * 1.6
			setFlying(self, false)
			buildWall(self, 0)
			-- anyone caught on the dragon's side is thrown back over it
			for _, p in DuoService.Players() do
				local r = rootOf(p)
				if r and r.Position.Z > WALL_Z - 2 then
					r.CFrame = CFrame.new(r.Position.X, r.Position.Y + 2, WALL_Z - 14)
				end
			end
			self.wallState = { move = T.GapMove, touch = 0.5, bomb = 2.5, warned = false }
			Audio.play("GlitchCrackle", Vector3.new(0, 4, WALL_Z), 3)
			self.onHit = function(part: BasePart, _damage: number, _owner: Player?, how: string)
				if part ~= self.heart then
					return
				end
				if how ~= "Reflected" then
					-- the Glitch swallows plain fire: only Miko's light gets through
					CombatFx.Burst(part.Position, { { "Stars", 10, 1.5, Palette.Glitch } }, Palette.Glitch, 8)
					Audio.play("GlitchStatic", part.Position)
					return
				end
				self.heartHits += 1
				self.hits += 1
				setHealth(self)
				flash(part)
				hurtFlash(self)
				Audio.play("EnemyHit", part.Position, 2)
				Audio.play("GlitchCrackle", part.Position, 2)
			end
		end,
		Update = function(self, dt)
			stepWall(self, dt)
			animate(self, dt)
		end,
		IsDone = function(self)
			return self.heartHits >= T.HeartHits
		end,
		Exit = function(self)
			self.onHit = nil
			self.hits = TOTAL_HITS
			setHealth(self)
			if self.wall then
				self.wall:Destroy()
				self.wall = nil
			end
			-- it comes apart into static
			local at = self.body.Position
			Audio.play("GlitchCrackle", at, 3)
			Audio.play("MeteorImpact", at, 1)
			for part in self.offsets do
				CollectionService:RemoveTag(part, "BossHurt")
				part.CanCollide = false
				part.Anchored = false
				part.AssemblyLinearVelocity =
					Vector3.new(math.random(-25, 25), math.random(15, 45), math.random(-10, 20))
				task.delay(3, part.Destroy, part)
			end
			for _, d in self.dragon:GetDescendants() do -- skins too: they dissolve toward the Glitch's magenta
				if d:IsA("BasePart") and d.Transparency < 1 then
					d.CanCollide = false
					d.Color = d.Color:Lerp(Palette.Glitch, 0.5)
					TweenService:Create(d, TweenInfo.new(2.5), { Transparency = 1 }):Play()
				end
			end
			table.clear(self.offsets)
			knitBridge(self)
		end,
	},
}

return Boss
