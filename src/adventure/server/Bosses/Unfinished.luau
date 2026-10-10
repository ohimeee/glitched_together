-- The Unfinished (final boss, World 3; mechanics.md §5, blender_assets/briefs/Unfinished.md): the level Kai and
-- Miko never finished, a meteor golem of half-built rock standing in the void behind the far rim of a round stage.
-- The stage and its body are built by Greybox (GlitchedCore, FINAL STAGE); this runs the fight. Every phase hands
-- both players another world's kit (WorldService.ForceKit).
--   1. Static King (Pixel Plains kit): it throws its forearms, one at a time, at alternating targets; they slam
--      down flat. Kai freezes a resting arm, Miko climbs on and pounds it. 3 hits.
--   2. Static Dragon (castle kit, top-down): it slumps until its chest core is level with the stage and breathes
--      static at one player (a raised shield cuts the beam). Between breaths the core opens: only Miko's
--      reflected shots count. 4 hits.
--   3. True form (Core kit): static rings roll over the stage (jump them); nothing hurts it. Then Pip's line.
--   4. Finish it (Core kit): six level pieces wait in the Code Layer outside the rail. Miko pulls one out, Kai
--      copies it and pastes it on its glowing slot; each filled slot calms it (rings slow, it warms to gold).
--      Then the SAVE button rises; both ground-pound it together.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)
local Services = script.Parent.Parent.Services
local CombatService = require(Services.CombatService)
local CombatFx = require(Services.CombatFx)
local CutsceneService = require(Services.CutsceneService)
local DuoService = require(Services.DuoService)
local HealthService = require(Services.HealthService)
local InteractableService = require(Services.InteractableService)
local MoverService = require(Services.MoverService)
local WorldService = require(Services.WorldService)

local T = Tuning.Unfinished
local SLOTS = 6
local TOTAL_HITS = T.CrystalHits + T.HeartHits + SLOTS + 1 -- arms, core, slots, SAVE: the boss bar
local GOLD = Color3.fromRGB(255, 196, 92) -- a finished level: warm, not an owner color

type Arm = {
	part: BasePart,
	crystal: BasePart,
	crystalOffset: CFrame,
	state: string, -- Idle | Track | Slam | Rest | Rise
	t: number,
	from: CFrame,
	target: Player?,
	mark: BasePart?,
	hit: boolean,
}
type Ring = { r: number, segs: { BasePart }, hitBy: { [Player]: boolean } }

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

-- the whole golem blinks white (its grey-box parts are invisible under the skins)
local function hurtFlash(self: any)
	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.new(1, 1, 1)
	hl.FillTransparency = 0.35
	hl.OutlineTransparency = 1
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Parent = self.golem
	task.delay(Tuning.BossHitFlash, hl.Destroy, hl)
end

-- Miko's job (mechanics.md §5); a solo tester in Studio may do it too
local function mayPound(p: Player): boolean
	return p:GetAttribute("Role") == "Miko" or #DuoService.Players() < 2
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

-- the stage floor wears the world whose rules are on (the colliders never change): Pixel Plains voxel grass,
-- castle flagstones, the Core's pencil-grid primer
local LOOKS = {
	PixelPlains = { Enum.Material.SmoothPlastic, "PPGrass", Color3.fromRGB(214, 222, 204) },
	StarfallCastle = { Enum.Material.Cobblestone, "CastleFloor", Color3.fromRGB(205, 196, 214) },
}

-- a static wipe over the stage when the rules change (brief: magenta/cyan checker flash)
local function wipe(self: any, look: string?)
	local l = look and LOOKS[look] or self.coreLook
	self.stage.Material, self.stage.MaterialVariant, self.stage.Color = l[1], l[2], l[3]
	local disc = fxPart(
		self,
		"StaticWipe",
		Vector3.new(0.4, self.radius * 2, self.radius * 2),
		CFrame.new(self.center + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Palette.ForNeon(Palette.Glitch),
		0.3
	)
	disc.Shape = Enum.PartType.Cylinder
	CombatFx.Emit(disc, "Stars", 30, 20, Palette.Glitch)
	Audio.play("GlitchCrackle", self.center, 3)
	TweenService:Create(disc, TweenInfo.new(0.8), { Transparency = 1 }):Play()
	task.delay(0.9, disc.Destroy, disc)
end

-- Body -----------------------------------------------------------------------------------------------------------

-- every grey-box part rides the golem's pivot (its skins are welded); thrown or frozen arms don't
local function placeBody(self: any, dt: number)
	self.drop += (self.dropTarget - self.drop) * math.min(dt * T.Ease, 1)
	self.clock += dt
	local bob = math.sin(self.clock * 1.3) * T.Bob
	self.pivot = self.home * CFrame.new(0, -self.drop + bob, 0)
	for part, offset in self.offsets do
		if part.Parent and not self.detached[part] and not part:GetAttribute("Frozen") then
			part.CFrame = self.pivot * offset
		end
	end
	for _, a in self.arms do
		a.crystal.CFrame = a.part.CFrame * a.crystalOffset
	end
end

-- Phase 1: thrown arms --------------------------------------------------------------------------------------------

-- a forearm lying flat: its length along `dir`, fist end away from the golem, the crystal side up
local function flatArm(at: Vector3, dir: Vector3): CFrame
	local yaw = math.atan2(-dir.X, -dir.Z)
	return CFrame.new(at) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(math.rad(90), 0, 0)
end

local function clampToStage(self: any, pos: Vector3): Vector3
	local rel = flat(pos - self.center)
	local max = self.radius - 14
	if rel.Magnitude > max then
		rel = rel.Unit * max
	end
	return self.center + rel
end

local function clearMark(a: Arm)
	if a.mark then
		a.mark:Destroy()
		a.mark = nil
	end
end

local function updateArm(self: any, a: Arm, dt: number)
	if a.part:GetAttribute("Frozen") then
		return
	end
	a.t += dt
	local thick = a.part.Size.Z
	if a.state == "Track" then
		local root = a.target and rootOf(a.target)
		local goal = clampToStage(self, if root then root.Position else a.part.Position)
		local cur = a.part.Position
		local dir = flat(goal - self.pivot.Position)
		dir = if dir.Magnitude > 1 then dir.Unit else Vector3.new(0, 0, -1)
		local y = self.floorTop + T.Hover + thick / 2
		local lift = math.min(a.t / 0.5, 1)
		local xz = flat(cur):Lerp(flat(goal), math.min(dt * 4, 1))
		a.part.CFrame = flatArm(Vector3.new(xz.X, cur.Y + (y - cur.Y) * lift, xz.Z), dir)
		if not a.mark then
			a.mark = fxPart(self, "SlamMark", Vector3.one, CFrame.identity, Palette.ForNeon(Palette.Glitch), 0.75)
		end
		local mark = a.mark :: BasePart
		mark.Size = Vector3.new(a.part.Size.X + T.SlamPad * 2, 0.2, a.part.Size.Y + T.SlamPad * 2)
		mark.CFrame = CFrame.new(xz.X, self.floorTop + 0.15, xz.Z) * CFrame.Angles(0, math.atan2(-dir.X, -dir.Z), 0)
		mark.Transparency = 0.75 - 0.35 * math.min(a.t / T.Track, 1)
		if a.t >= T.Track then
			a.state, a.t, a.from = "Slam", 0, a.part.CFrame
		end
	elseif a.state == "Slam" then
		local s = math.min(a.t / T.SlamTime, 1)
		local floorY = self.floorTop + thick / 2
		local p = a.from.Position
		a.part.CFrame = a.from + Vector3.new(0, (floorY - p.Y) * s * s, 0)
		if s >= 1 then
			clearMark(a)
			Audio.play("PoundImpact", a.part.Position, 2)
			Audio.play("PoundDebris", a.part.Position, 1.5)
			for _, pl in DuoService.Players() do
				local root = rootOf(pl)
				if root and root.Position.Y < self.floorTop + 9 then
					local lp = a.part.CFrame:PointToObjectSpace(root.Position)
					local h = a.part.Size / 2
					if math.abs(lp.X) <= h.X + T.SlamPad and math.abs(lp.Y) <= h.Y + T.SlamPad then
						HealthService.Damage(pl, 1)
					end
				end
			end
			a.state, a.t = "Rest", 0
		end
	elseif a.state == "Rest" then
		if a.t >= T.Rest then
			a.state, a.t, a.from = "Rise", 0, a.part.CFrame
		end
	elseif a.state == "Rise" then
		local s = math.min(a.t / T.Rise, 1)
		local e = (1 - math.cos(s * math.pi)) / 2
		a.part.CFrame = a.from:Lerp(self.pivot * self.offsets[a.part], e)
		if s >= 1 then
			a.state, a.t, a.hit = "Idle", 0, false
			self.detached[a.part] = nil
			self.gap = T.Gap
		end
	end
end

local function runArms(self: any, dt: number)
	local busy = false
	for _, a in self.arms do
		updateArm(self, a, dt)
		busy = busy or a.state ~= "Idle"
	end
	if busy then
		return
	end
	self.gap -= dt
	if self.gap > 0 then
		return
	end
	local target = nextTarget(self)
	if not target then
		return
	end
	self.armTurn = self.armTurn % 2 + 1
	local a = self.arms[self.armTurn]
	a.state, a.t, a.target = "Track", 0, target
	self.detached[a.part] = true
	Audio.play("GlitchCrackle", a.part.Position, 1)
end

local function homeArms(self: any)
	for _, a in self.arms do
		MoverService.Resume(a.part)
		clearMark(a)
		a.state, a.t, a.hit, a.target = "Idle", 0, false, nil
		self.detached[a.part] = nil
	end
	self.gap = T.Gap * 2
end

-- a pound on the top face of a flat arm (its local -Z points up)
local function poundOnArm(a: Arm, pos: Vector3): boolean
	local lp = a.part.CFrame:PointToObjectSpace(pos)
	local h = a.part.Size / 2
	local up = pos.Y - a.part.Position.Y
	return math.abs(lp.X) <= h.X + 1 and math.abs(lp.Y) <= h.Y + 1 and up >= h.Z - 3 and up <= h.Z + 8
end

-- Phase 2: static breath -----------------------------------------------------------------------------------------

local function clearBreath(self: any)
	for _, name in { "aim", "beamFloor", "beamFall" } do
		if self[name] then
			self[name]:Destroy()
			self[name] = nil
		end
	end
end

local function aimAt(self: any, target: Player?, dt: number?)
	local root = target and rootOf(target)
	if not root then
		return
	end
	local want = flat(root.Position - self.head.Position)
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
	local floorY = self.floorTop + 1
	local floorFrom = Vector3.new(from.X, floorY, from.Z)
	local stop = floorFrom + self.dir * length
	local reach = floorFrom + self.dir * math.min(length, 12)
	local function bar(name: string, a: Vector3, b: Vector3)
		local d = (b - a).Magnitude
		local cf = CFrame.lookAt((a + b) / 2, b)
		local size = Vector3.new(T.BreathWidth, T.BreathWidth * 0.6, d)
		if not self[name] then
			self[name] = fxPart(self, "StaticBreath", size, cf, Palette.Glitch, 0.25)
			CombatFx.Emit(self[name], "Stars", 2, 30, Palette.Glitch)
		end
		self[name].Size = size
		self[name].CFrame = cf
	end
	bar("beamFloor", reach, stop)
	bar("beamFall", from, reach)
end

local function setCore(self: any, open: boolean)
	self.coreOpen = open
	self.heart.Transparency = if open then 0 else 0.85
	local glow = self.heart:FindFirstChildOfClass("PointLight")
	if glow then
		glow.Enabled = open
	end
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
			setCore(self, false)
			aimAt(self, b.target)
			Audio.play("GlitchCrackle", self.head.Position, 2)
		end
	elseif b.state == "Windup" then
		aimAt(self, b.target)
		local from = self.head.Position
		local mid = Vector3.new(from.X, self.floorTop + 0.15, from.Z) + self.dir * (T.BreathLength / 2)
		local cf = CFrame.lookAt(mid, mid + self.dir)
		if not self.aim then
			self.aim = fxPart(self, "BreathAim", Vector3.new(1, 0.1, T.BreathLength), cf, Palette.Danger, 0.4)
		end
		self.aim.CFrame = cf
		self.aim.Transparency = 0.2 + 0.4 * (b.t / T.BreathWindup)
		if b.t <= 0 then
			b.state, b.t, b.tick, b.hit = "Breathe", T.BreathTime, 0, {}
			clearBreath(self)
			Audio.play("StaticShot", self.head.Position, 2)
		end
	elseif b.state == "Breathe" then
		aimAt(self, b.target, dt)
		local from = self.head.Position
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
					if p == blocker then
						CombatService.HitPlayer(p, T.BreathDamage, from) -- on the shield: charges her Rally
					elseif inside and along < length - 0.5 and not b.hit[p] then
						b.hit[p] = true -- one heart per breath (playtest: 3 ticks downed a player who stood still)
						CombatService.HitPlayer(p, T.BreathDamage, from)
					end
				end
			end
		end
		if b.t <= 0 then
			b.state, b.t = "Wait", T.BreathEvery
			clearBreath(self)
			setCore(self, true) -- spent, its chest core opens
		end
	end
end

local function setTopDown(self: any, on: boolean)
	workspace:SetAttribute("TopDownZoom", if on then T.Zoom else nil)
	workspace:SetAttribute("TopDownFlip", if on then true else nil) -- look from the walkway: the golem at the top
	workspace:SetAttribute("TopDownBack", if on then T.CameraBack else nil)
	workspace:SetAttribute("TopDownFocus", if on then self.center:Lerp(self.home.Position, 0.5) else nil)
	workspace:SetAttribute("TopDownFocusWeight", if on then T.FocusWeight else nil)
end

-- Phase 3 + 4: static rings ---------------------------------------------------------------------------------------

local RING_SEGS = 40

local function spawnRing(self: any)
	local ring: Ring = { r = 2, segs = {}, hitBy = {} }
	for i = 1, RING_SEGS do
		local seg = fxPart(self, "StaticRing", Vector3.new(1, T.RingHeight, 1), CFrame.identity, Palette.Glitch, 0.2)
		seg:SetAttribute("Angle", (i - 0.5) / RING_SEGS * math.pi * 2)
		table.insert(ring.segs, seg)
	end
	table.insert(self.rings, ring)
	Audio.play("StaticShot", self.ringOrigin, 1.5)
end

local function stepRings(self: any, dt: number)
	for i = #self.rings, 1, -1 do
		local ring: Ring = self.rings[i]
		ring.r += T.RingSpeed * dt
		local len = ring.r * math.pi * 2 / RING_SEGS + 0.3
		for _, seg in ring.segs do
			local a = seg:GetAttribute("Angle") :: number
			local at = self.ringOrigin + Vector3.new(math.sin(a), 0, math.cos(a)) * ring.r
			local inside = flat(at - self.center).Magnitude <= self.radius
			seg.Transparency = if inside then 0.2 else 1
			seg.Size = Vector3.new(0.8, T.RingHeight, len)
			seg.CFrame = CFrame.new(at + Vector3.new(0, T.RingHeight / 2, 0)) * CFrame.Angles(0, a + math.pi / 2, 0)
		end
		for _, p in DuoService.Players() do
			local root = rootOf(p)
			if root and not ring.hitBy[p] and not p:GetAttribute("Downed") then
				local d = flat(root.Position - self.ringOrigin).Magnitude
				local feet = root.Position.Y - 3
				if math.abs(d - ring.r) <= 1.5 and feet < self.floorTop + T.RingHeight then
					ring.hitBy[p] = true
					HealthService.Damage(p, T.RingDamage)
				end
			end
		end
		if ring.r > self.radius * 2 + 4 then
			for _, seg in ring.segs do
				seg:Destroy()
			end
			table.remove(self.rings, i)
		end
	end
end

local function clearRings(self: any)
	for _, ring in self.rings do
		for _, seg in ring.segs do
			seg:Destroy()
		end
	end
	table.clear(self.rings)
end

-- Phase 4: building the level --------------------------------------------------------------------------------------

local function showSlots(self: any, on: boolean)
	for _, slot in self.slots do
		if not self.filled[slot] then
			slot.Transparency = if on then 0.5 else 1
		end
	end
end

local function fillSlot(self: any, slot: BasePart)
	self.filled[slot] = true
	self.filledCount += 1
	self.hits += 1
	setHealth(self)
	slot.Material = Enum.Material.SmoothPlastic
	slot.Color = GOLD
	slot.Transparency = 0
	slot.CanCollide = true
	slot.CanQuery = true
	CombatFx.Burst(slot.Position, { { "Stars", 16, 2, GOLD } }, GOLD, 10)
	Audio.play("Checkpoint", slot.Position, 1.5)
	self.calm.FillTransparency = 1 - 0.5 * (self.filledCount / SLOTS) -- it warms to gold, slot by slot
end

local function onPasted(self: any, paste: Instance)
	if not (self.building and paste:IsA("BasePart")) then
		return
	end
	for _, slot in self.slots do
		if not self.filled[slot] and slot:GetAttribute("Piece") == paste.Name then
			local d = flat(paste.Position - slot.Position).Magnitude
			if d <= T.SlotRadius and math.abs(paste.Position.Y - slot.Position.Y) <= 8 then
				paste:Destroy() -- the slot itself becomes the finished piece
				fillSlot(self, slot)
				return
			end
		end
	end
end

local function raiseSave(self: any)
	local b = self.save
	b.Transparency = 0
	b.Material = Enum.Material.Neon
	b.Color = Palette.ForNeon(GOLD)
	b.CanCollide = true
	local up = self.floorTop + b.Size.X / 2
	TweenService:Create(b, TweenInfo.new(T.SaveRise, Enum.EasingStyle.Back), {
		CFrame = b.CFrame + Vector3.new(0, up - b.Position.Y, 0),
	}):Play()
	Audio.play("GlitchCrackle", b.Position, 1)
	self.saveUp = true
end

-- Setup -------------------------------------------------------------------------------------------------------------

function Boss.Setup(self: any, world: Instance)
	local golem = world:FindFirstChild("Unfinished", true) :: Model
	-- the stage disc (the section Model shares its name): the part carrying its Radius
	local stage: BasePart? = nil
	for _, d in world:GetDescendants() do
		if d.Name == "FinalStage" and d:IsA("BasePart") and d:GetAttribute("Radius") then
			stage = d
			break
		end
	end
	assert(golem and stage, "[Unfinished] stage not built")
	local stage = stage :: BasePart
	self.world = world
	self.golem = golem
	self.stage = stage
	self.coreLook = { stage.Material, stage.MaterialVariant, stage.Color }
	self.turn = 0
	self.armTurn = 0
	self.gap = 1.5
	self.hits = 0
	self.clock = 0
	self.drop, self.dropTarget = 0, 0
	self.rings = {} :: { Ring }
	self.fx = Instance.new("Folder")
	self.fx.Name = "BossFx"
	self.fx.Parent = world

	self.center = Vector3.new(stage.Position.X, stage.Position.Y + stage.Size.X / 2, stage.Position.Z)
	self.floorTop = self.center.Y
	self.radius = (stage:GetAttribute("Radius") :: number?) or stage.Size.Y / 2
	self.home = golem.WorldPivot
	self.pivot = self.home
	self.ringOrigin = self.center + Vector3.new(0, 0, self.radius) -- the rim in front of it

	self.offsets = {} :: { [BasePart]: CFrame }
	self.detached = {} :: { [BasePart]: boolean }
	for _, d in golem:GetChildren() do
		if d:IsA("BasePart") and not d.Name:match("^Crystal") then
			self.offsets[d] = self.home:ToObjectSpace(d.CFrame)
		end
	end
	self.head = golem:FindFirstChild("Head") :: BasePart
	self.heart = golem:FindFirstChild("Heart") :: BasePart
	self.arms = {}
	for _, s in { "L", "R" } do
		local part = golem:FindFirstChild("Arm" .. s) :: BasePart
		local crystal = golem:FindFirstChild("Crystal" .. s) :: BasePart
		table.insert(
			self.arms,
			{
				part = part,
				crystal = crystal,
				crystalOffset = part.CFrame:ToObjectSpace(crystal.CFrame),
				state = "Idle",
				t = 0,
				from = part.CFrame,
				hit = false,
			} :: Arm
		)
	end
	self.slots = {} :: { BasePart }
	self.filled = {} :: { [BasePart]: boolean }
	self.filledCount = 0
	local slots = world:FindFirstChild("LevelSlots", true)
	for _, slot in if slots then slots:GetChildren() else {} do
		if slot:IsA("BasePart") then
			table.insert(self.slots, slot)
		end
	end
	self.save = world:FindFirstChild("SaveButton", true) :: BasePart
	self.saveHome = self.save.CFrame
	self.dir = Vector3.new(0, 0, -1)
	setCore(self, false)

	-- gold creeps over it as the level gets finished (phase 4)
	self.calm = Instance.new("Highlight")
	self.calm.FillColor = GOLD
	self.calm.FillTransparency = 1
	self.calm.OutlineTransparency = 1
	self.calm.DepthMode = Enum.HighlightDepthMode.Occluded
	self.calm.Parent = golem

	self.hitConn = CombatService.BossHit:Connect(function(part: BasePart, damage: number, owner: Player?, how: string)
		if part:IsDescendantOf(self.golem) and self.onHit then
			self.onHit(part, damage, owner, how)
		end
	end)
	self.poundConn = InteractableService.Pounded:Connect(function(p: Player, pos: Vector3)
		if self.onPound then
			self.onPound(p, pos)
		end
	end)
	self.pasteConn = CollectionService:GetInstanceAddedSignal("Pasted"):Connect(function(paste)
		task.defer(onPasted, self, paste) -- after CopyPaste has placed and parented it
	end)
	setHealth(self)
end

function Boss.Cleanup(self: any)
	for _, conn in { self.hitConn, self.poundConn, self.pasteConn } do
		conn:Disconnect()
	end
	self.onHit, self.onPound, self.building = nil, nil, false
	WorldService.ForceKit(nil)
	setTopDown(self, false)
	if self.stage.Parent then
		self.stage.Material, self.stage.MaterialVariant, self.stage.Color = table.unpack(self.coreLook)
	end
	clearRings(self)
	clearBreath(self)
	if self.fx then
		self.fx:Destroy()
	end
	if self.calm then
		-- beaten: its gold glow fades out on its own (Finish It's Exit); otherwise gone now
		task.delay(if self.finished then 4 else 0, self.calm.Destroy, self.calm)
	end
	-- a stop mid-fight (game over rebuilds the world anyway): the body back home
	if self.golem.Parent and not self.finished then
		for _, a in self.arms do
			MoverService.Resume(a.part)
		end
		table.clear(self.detached)
		self.drop, self.dropTarget = 0, 0
		placeBody(self, 0)
	end
end

-- Phases ------------------------------------------------------------------------------------------------------------

Boss.Phases = {
	{
		Name = "Static King",
		Enter = function(self)
			self.hits = 0
			setHealth(self)
			WorldService.ForceKit("PixelPlains")
			self.dropTarget = 0
			homeArms(self)
			wipe(self, "PixelPlains")
			self.onPound = function(p: Player, pos: Vector3)
				if not mayPound(p) then
					return
				end
				for _, a in self.arms do
					if not a.hit and a.state == "Rest" and a.part:GetAttribute("Frozen") and poundOnArm(a, pos) then
						a.hit = true
						self.hits += 1
						setHealth(self)
						flash(a.crystal)
						hurtFlash(self)
						Audio.play("GlitchStatic", a.crystal.Position, 2)
						Audio.play("EnemyHit", a.crystal.Position, 2)
						task.delay(T.ShakeOff, function()
							MoverService.Resume(a.part) -- it shakes the arm free and pulls it back
							if a.state ~= "Idle" then
								a.state, a.t, a.from = "Rise", 0, a.part.CFrame
							end
						end)
					end
				end
			end
		end,
		Update = function(self, dt)
			runArms(self, dt)
			placeBody(self, dt)
		end,
		IsDone = function(self)
			return self.hits >= T.CrystalHits
		end,
		Exit = function(self)
			self.onPound = nil
			homeArms(self)
		end,
	},
	{
		Name = "Static Dragon",
		Enter = function(self)
			self.hits = T.CrystalHits
			self.coreHits = 0
			setHealth(self)
			homeArms(self)
			WorldService.ForceKit("StarfallCastle")
			setTopDown(self, true)
			self.dropTarget = T.SlumpDrop - T.StandDrop -- sunk until its chest core is at reflect height
			self.breath = { state = "Wait", t = 2.5 }
			setCore(self, true)
			wipe(self, "StarfallCastle")
			self.onHit = function(part: BasePart, _damage: number, _owner: Player?, how: string)
				if part ~= self.heart then
					return
				end
				if how ~= "Reflected" or not self.coreOpen then
					-- the Glitch swallows plain fire: only Miko's light gets through, and only while it's open
					CombatFx.Burst(part.Position, { { "Stars", 10, 1.5, Palette.Glitch } }, Palette.Glitch, 8)
					Audio.play("GlitchStatic", part.Position)
					return
				end
				self.coreHits += 1
				self.hits += 1
				setHealth(self)
				flash(part)
				hurtFlash(self)
				Audio.play("EnemyHit", part.Position, 2)
				Audio.play("GlitchCrackle", part.Position, 2)
			end
		end,
		Update = function(self, dt)
			stepBreath(self, dt)
			placeBody(self, dt)
		end,
		IsDone = function(self)
			return self.coreHits >= T.HeartHits
		end,
		Exit = function(self)
			self.onHit = nil
			clearBreath(self)
			setCore(self, false)
			setTopDown(self, false)
		end,
	},
	{
		Name = "True Form",
		Enter = function(self)
			self.hits = T.CrystalHits + T.HeartHits
			setHealth(self)
			WorldService.ForceKit("GlitchedCore")
			self.dropTarget = 0
			self.trueT = T.TrueFormTime
			self.ringT = 1.5
			self.talked = false
			wipe(self)
		end,
		Update = function(self, dt)
			placeBody(self, dt)
			if self.talking then
				return -- the cutscene yields elsewhere; BossService keeps ticking meanwhile
			end
			stepRings(self, dt)
			self.trueT -= dt
			self.ringT -= dt
			if self.ringT <= 0 and self.trueT > 2 then
				self.ringT = T.RingEvery
				spawnRing(self)
			end
			if self.trueT <= 0 and #self.rings == 0 and not self.talked then
				self.talking = true
				task.spawn(function()
					CutsceneService.Play("Final_Phase3")
					self.talking = false
					self.talked = true
				end)
			end
		end,
		IsDone = function(self)
			return self.talked == true
		end,
		Exit = function(self)
			clearRings(self)
		end,
	},
	{
		Name = "Finish It",
		Enter = function(self)
			self.hits = T.CrystalHits + T.HeartHits
			setHealth(self)
			WorldService.ForceKit("GlitchedCore")
			self.dropTarget = 0
			self.building = true
			self.ringT = 2
			self.saveUp = false
			self.pounds = {} :: { [Player]: number }
			self.saved = false
			showSlots(self, true)
			wipe(self)
			self.onPound = function(p: Player, pos: Vector3)
				if not self.saveUp then
					return
				end
				local b = self.save
				if flat(pos - b.Position).Magnitude > b.Size.Y / 2 + 1 or pos.Y < self.floorTop - 1 then
					return
				end
				self.pounds[p] = os.clock()
				local duo = DuoService.Players()
				local all = true
				for _, other in duo do
					local at = self.pounds[other]
					if not at or os.clock() - at > Tuning.DuoPoundWindow then
						all = false
					end
				end
				if all then
					self.saved = true
				else
					flash(b)
				end
			end
		end,
		Update = function(self, dt)
			placeBody(self, dt)
			stepRings(self, dt)
			if self.filledCount < SLOTS then
				self.ringT -= dt
				if self.ringT <= 0 then
					self.ringT = T.RingEvery + T.CalmRing * self.filledCount -- every slot calms it
					spawnRing(self)
				end
			elseif not self.saveUp then
				clearRings(self)
				raiseSave(self)
			end
		end,
		IsDone = function(self)
			return self.saved == true
		end,
		Exit = function(self)
			self.onPound, self.building = nil, false
			self.finished = true
			self.hits = TOTAL_HITS
			setHealth(self)
			clearRings(self)
			WorldService.ForceKit(nil)
			-- it becomes the finished level: gold all over, then gone into light
			local at = self.golem:GetPivot().Position + Vector3.new(0, 30, 0)
			Audio.play("GlitchCrackle", at, 2)
			CombatFx.Burst(at, { { "Stars", 60, 4, GOLD } }, GOLD, 40)
			TweenService:Create(self.calm, TweenInfo.new(1.5), { FillTransparency = 0 }):Play()
			task.delay(1.5, function()
				for _, d in self.golem:GetDescendants() do
					if d:IsA("BasePart") then
						d.CanCollide = false
					end
					if d:IsA("BasePart") and d.Transparency < 1 then
						TweenService:Create(d, TweenInfo.new(2), { Transparency = 1 }):Play()
					end
				end
				if self.calm then
					TweenService:Create(self.calm, TweenInfo.new(2), { FillTransparency = 1 }):Play()
				end
			end)
		end,
	},
}

return Boss
