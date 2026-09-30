-- Starfall Castle combat layer (mechanics.md §4 World 2, implementation.md §8 "Starfall Castle").
--   Enemies: Parts tagged `Enemy` whose `Type` is in Tuning.Enemies. Anchored, moved by CFrame on the server:
--            Idle → Chase → Windup → Recover (+ Stunned), HP bar, XP on death. Castle floors are flat.
--   Targeting: a blocking Miko within Taunt radius wins; otherwise the nearest standing player.
--   Projectiles: simulated here (Heartbeat raycast old → new). A blocking Miko's shield redirects any shot that
--            reaches it along her facing: enemy shots from the front and every one of Kai's fireballs. Redirected
--            shots are friendly and deal ×1.5 (×2 with Reflect Boost).
--   Area effects used by the tools: flame walls, meteor, rally burst, sword box, shield-charge line, ignite.
--   Ultimate charge: player attribute `Ultimate` 0..1 (Kai from damage dealt, Miko from damage blocked).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local HealthService = require(script.Parent.HealthService)
local DuoService = require(script.Parent.DuoService)
local InteractableService = require(script.Parent.InteractableService)
local XpService = require(script.Parent.XpService)

local C = Tuning.Combat
local ENEMIES = Tuning.Enemies :: any

local CombatService = {}

type Foe = {
	part: BasePart,
	kind: string,
	spec: any,
	hp: number,
	maxHp: number,
	state: string, -- "Idle" | "Chase" | "Windup" | "Recover"
	stateUntil: number,
	awake: boolean,
	nextShot: number,
	teleportNext: boolean,
	stunUntil: number,
	chargedUntil: number,
	shieldDownUntil: number,
	color: Color3,
	fill: Frame?,
	dead: boolean,
}

type Shot = {
	part: BasePart,
	dir: Vector3,
	speed: number,
	damage: number,
	friendly: boolean,
	owner: Player?,
	kind: string,
	travelled: number,
	reflectedBy: Player?,
	slow: boolean,
}

type Wall = { part: BasePart, owner: Player?, untilTime: number, nextTick: number }

local foes: { [BasePart]: Foe } = {}
local shots: { Shot } = {}
local walls: { Wall } = {}
local fx: Folder

local FIRE = Palette.Kai -- Kai's fire (art-direction.md §12)
local DANGER = Palette.Danger -- enemy attacks and warnings only
local MAX_SHOT_DISTANCE = 160

-- helpers -------------------------------------------------------------------------------------

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function unitOr(v: Vector3, fallback: Vector3): Vector3
	return if v.Magnitude > 1e-3 then v.Unit else fallback
end

local function rootOf(p: Player?): BasePart?
	local c = p and p.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function standing(p: Player): BasePart?
	if p:GetAttribute("Downed") then
		return nil
	end
	return rootOf(p)
end

local function paused(): boolean
	for _, p in DuoService.Players() do
		if p:GetAttribute("Picking") then
			return true
		end
	end
	return false
end

local function facing(p: Player): Vector3
	local r = rootOf(p)
	return if r then unitOr(flat(r.CFrame.LookVector), Vector3.zAxis) else Vector3.zAxis
end

local function effect(props: { [string]: any }, life: number?): Part
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	for k, v in props do
		(part :: any)[k] = v
	end
	if part.Material == Enum.Material.Neon then
		part.Color = Palette.ForNeon(part.Color)
	end
	part.Parent = fx
	if life then
		TweenService:Create(part, TweenInfo.new(life), { Transparency = 1 }):Play()
		task.delay(life, part.Destroy, part)
	end
	return part
end

local function worldParams(exclude: { Instance }): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = true
	params.FilterDescendantsInstances = exclude
	return params
end

local function characters(): { Instance }
	local list: { Instance } = { fx }
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(list, p.Character)
		end
	end
	return list
end

-- ultimate charge ------------------------------------------------------------------------------

function CombatService.AddCharge(p: Player, amount: number)
	local need = if p:GetAttribute("Role") == "Kai"
		then Tuning.FireMage.Meteor.Charge
		else Tuning.ShieldKnight.Rally.Charge
	p:SetAttribute("Ultimate", math.min(1, ((p:GetAttribute("Ultimate") or 0) :: number) + amount / need))
end

function CombatService.SpendUltimate(p: Player): boolean
	if ((p:GetAttribute("Ultimate") or 0) :: number) < 1 then
		return false
	end
	p:SetAttribute("Ultimate", 0)
	return true
end

-- players ----------------------------------------------------------------------------------------

local function shieldArc(p: Player): number
	return if p:GetAttribute("Up_WiderBlock") then C.WiderBlock else Tuning.Castle.ShieldArc
end

-- Is this blocking player's shield facing `fromPos`?
local function shieldCovers(p: Player, fromPos: Vector3): boolean
	if not p:GetAttribute("Blocking") then
		return false
	end
	local r = rootOf(p)
	if not r then
		return false
	end
	local to = flat(fromPos - r.Position)
	if to.Magnitude < 0.1 then
		return true
	end
	return facing(p):Dot(to.Unit) >= math.cos(math.rad(shieldArc(p) / 2))
end

local function shieldFlash(p: Player)
	local r = rootOf(p)
	if r then
		effect({
			Size = Vector3.new(5, 5, 0.3),
			CFrame = CFrame.lookAt(r.Position + facing(p) * 2.2, r.Position + facing(p) * 4),
			Color = Palette.Miko,
			Transparency = 0.3,
		}, 0.25)
	end
end

function CombatService.HitPlayer(p: Player, amount: number, fromPos: Vector3)
	if p:GetAttribute("Downed") or p:GetAttribute("Picking") then
		return
	end
	if shieldCovers(p, fromPos) then
		CombatService.AddCharge(p, amount)
		shieldFlash(p)
		return
	end
	HealthService.Damage(p, amount)
end

-- enemies ----------------------------------------------------------------------------------------

-- Colors an enemy: the part itself, or (when ArtService skinned it and the part is invisible) a Highlight
-- over its meshes. nil = back to normal.
local function tint(part: BasePart, color: Color3?, fallback: Color3)
	if part.Transparency < 1 then
		part.Color = color or fallback
		return
	end
	local hl = part:FindFirstChild("Tint") :: Highlight?
	if not color then
		if hl then
			hl:Destroy()
		end
		return
	end
	if not hl then
		local newHl = Instance.new("Highlight")
		newHl.Name = "Tint"
		newHl.OutlineTransparency = 1
		newHl.DepthMode = Enum.HighlightDepthMode.Occluded
		newHl.Adornee = part:FindFirstChildWhichIsA("MeshPart") or part
		newHl.Parent = part
		hl = newHl
	end
	local h = hl :: Highlight
	h.FillColor = color
	h.FillTransparency = 0.45
end

local function makeBar(foe: Foe)
	local gui = Instance.new("BillboardGui")
	gui.Name = "HPBar"
	gui.Size = UDim2.fromOffset(64, 8)
	gui.StudsOffsetWorldSpace = Vector3.new(0, foe.part.Size.Y / 2 + 1.5, 0)
	gui.LightInfluence = 0
	gui.MaxDistance = 150
	gui.Parent = foe.part
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	back.BorderSizePixel = 0
	back.Parent = gui
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = DANGER
	fill.BorderSizePixel = 0
	fill.Parent = back
	foe.fill = fill
end

local function register(inst: Instance)
	local kind = inst:GetAttribute("Type")
	local spec = kind and ENEMIES[kind]
	if not spec or not inst:IsA("BasePart") then
		return
	end
	local part = inst :: BasePart
	part.Anchored = true
	local hp = (part:GetAttribute("StartHP") or spec.HP) :: number
	local foe: Foe = {
		part = part,
		kind = kind,
		spec = spec,
		hp = hp,
		maxHp = hp,
		state = "Idle",
		stateUntil = 0,
		awake = false,
		nextShot = os.clock() + math.random() * 1.5,
		teleportNext = false,
		stunUntil = 0,
		chargedUntil = 0,
		shieldDownUntil = 0,
		color = part.Color,
		fill = nil,
		dead = false,
	}
	foes[part] = foe
	part:SetAttribute("HP", hp)
	makeBar(foe)
end

local function setShieldVisible(foe: Foe, up: boolean)
	local shield = foe.part:FindFirstChild("Shield")
	if shield and shield:IsA("BasePart") then
		local skinned = shield:GetAttribute("Skinned") ~= nil
		if not skinned then
			shield.Transparency = if up then 0 else 0.8
		end
		for _, d in shield:GetChildren() do
			if d:IsA("MeshPart") then
				d.Transparency = if up then 0 else 0.8
			end
		end
	end
end

local function kill(foe: Foe)
	foe.dead = true
	foes[foe.part] = nil
	local part = foe.part
	XpService.Drop(part.Position, foe.spec.XP)
	if foe.kind == "SplitSlime" and not part:GetAttribute("Small") then
		for _, side in { -1, 1 } do
			local small = part:Clone()
			for _, child in small:GetChildren() do
				if child:IsA("MeshPart") then
					-- keep the art: shrink it around the new, smaller body
					local rel = part.CFrame:ToObjectSpace(child.CFrame)
					child.Size *= 0.6
					child.CFrame = part.CFrame * (rel - rel.Position + rel.Position * 0.6)
				else
					child:Destroy()
				end
			end
			small.Size = part.Size * 0.6
			small:SetAttribute("Small", true)
			small:SetAttribute("StartHP", foe.spec.SplitHP)
			small.CFrame = part.CFrame * CFrame.new(side * 2.2, -part.Size.Y * 0.2, 0)
			small.Transparency = 0
			small.Parent = part.Parent -- still tagged Enemy → registers itself
		end
	end
	part:SetAttribute("HP", 0)
	part.CanCollide = false
	part.CanQuery = false
	TweenService:Create(part, TweenInfo.new(0.35), { Transparency = 1, Size = part.Size * 0.3 }):Play()
	task.delay(0.4, part.Destroy, part)
end

-- Returns the damage actually dealt (0 when a Shield Guard blocks it).
function CombatService.DamageEnemy(part: BasePart, amount: number, source: Player?, fromPos: Vector3?): number
	local foe = foes[part]
	if not foe or foe.dead or amount <= 0 then
		return 0
	end
	if foe.kind == "ShieldGuard" and fromPos and os.clock() >= foe.shieldDownUntil then
		local to = flat(fromPos - part.Position)
		if
			to.Magnitude > 0.5
			and flat(part.CFrame.LookVector).Unit:Dot(to.Unit) >= math.cos(math.rad(foe.spec.Arc / 2))
		then
			effect({ Size = Vector3.new(2, 2, 2), CFrame = CFrame.new(fromPos), Color = Color3.new(1, 1, 1) }, 0.2)
			foe.awake = true
			return 0
		end
	end
	foe.hp -= amount
	foe.awake = true
	part:SetAttribute("HP", math.max(0, foe.hp))
	if foe.fill then
		foe.fill.Size = UDim2.fromScale(math.clamp(foe.hp / foe.maxHp, 0, 1), 1)
	end
	tint(part, Color3.new(1, 1, 1), foe.color)
	task.delay(0.08, function()
		if not foe.dead then
			tint(part, if foe.state == "Windup" then DANGER else nil, foe.color)
		end
	end)
	if source and source:GetAttribute("Role") == "Kai" then
		CombatService.AddCharge(source, amount)
	end
	if foe.hp <= 0 then
		kill(foe)
	end
	return amount
end

function CombatService.Stun(pos: Vector3, radius: number, duration: number)
	for part, foe in foes do
		if (part.Position - pos).Magnitude <= radius + part.Size.X / 2 then
			foe.stunUntil = math.max(foe.stunUntil, os.clock() + duration)
			foe.state = "Recover"
			foe.stateUntil = foe.stunUntil
		end
	end
end

local function flameBlocks(pos: Vector3, radius: number): boolean
	for _, w in walls do
		local localPos = w.part.CFrame:PointToObjectSpace(pos)
		if
			math.abs(localPos.X) <= w.part.Size.X / 2 + radius
			and math.abs(localPos.Z) <= w.part.Size.Z / 2 + radius
		then
			return true
		end
	end
	return false
end

-- Moves an enemy along the floor; stops at walls (and flame walls unless `ignoreFlame`).
local function tryMove(foe: Foe, dir: Vector3, dist: number, ignoreFlame: boolean?)
	if dist <= 0 or dir.Magnitude < 1e-3 then
		return
	end
	local part = foe.part
	local radius = math.max(part.Size.X, part.Size.Z) / 2
	local pos = part.Position
	local params = worldParams(characters())
	local hit = workspace:Raycast(pos, dir * (dist + radius), params)
	if hit then
		dist = math.max(0, hit.Distance - radius - 0.1)
	end
	local newPos = pos + dir * dist
	if not ignoreFlame and flameBlocks(newPos, radius) and not flameBlocks(pos, radius) then
		return
	end
	part.CFrame = CFrame.lookAt(newPos, newPos + flat(part.CFrame.LookVector)) -- keep facing
end

local function face(foe: Foe, target: Vector3)
	local pos = foe.part.Position
	local to = flat(target - pos)
	if to.Magnitude > 0.1 then
		foe.part.CFrame = CFrame.lookAt(pos, pos + to)
	end
end

function CombatService.Knock(part: BasePart, dir: Vector3, dist: number)
	local foe = foes[part]
	if not foe then
		return
	end
	tryMove(foe, unitOr(flat(dir), Vector3.zAxis), dist, true) -- shoved right through flame walls
	foe.chargedUntil = os.clock() + C.ChargedWindow
	if foe.kind == "ShieldGuard" then
		foe.shieldDownUntil = os.clock() + C.ShieldDown
		setShieldVisible(foe, false)
	end
end

local function pickTarget(foe: Foe): (Player?, number)
	local pos = foe.part.Position
	local best: Player?, bestD = nil, math.huge
	for _, p in DuoService.Players() do
		local r = standing(p)
		if r then
			local d = flat(r.Position - pos).Magnitude
			if p:GetAttribute("Blocking") and d <= Tuning.Castle.TauntRadius then
				return p, d -- taunt
			end
			if d < bestD then
				best, bestD = p, d
			end
		end
	end
	return best, bestD
end

-- projectiles ----------------------------------------------------------------------------------

export type ShotSpec = {
	origin: Vector3,
	dir: Vector3,
	speed: number,
	damage: number,
	friendly: boolean,
	owner: Player?,
	kind: string, -- "Fireball" | "Arrow" | "Orb"
	size: number?,
	color: Color3?,
	slow: boolean?,
}

function CombatService.Fire(spec: ShotSpec)
	local size = spec.size or 1.2
	local part = effect({
		Name = spec.kind,
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * size,
		CFrame = CFrame.new(spec.origin),
		Color = spec.color or FIRE,
	})
	table.insert(shots, {
		part = part,
		dir = unitOr(flat(spec.dir), Vector3.zAxis),
		speed = spec.speed,
		damage = spec.damage,
		friendly = spec.friendly,
		owner = spec.owner,
		kind = spec.kind,
		travelled = 0,
		reflectedBy = nil,
		slow = spec.slow == true,
	})
end

local function reflect(shot: Shot, miko: Player, at: Vector3)
	if not shot.friendly then
		CombatService.AddCharge(miko, shot.damage) -- blocked damage feeds Rally
	end
	local mult = if miko:GetAttribute("Up_ReflectBoost") then C.ReflectBoost else Tuning.Castle.ReflectMult
	shot.dir = facing(miko)
	shot.friendly = true
	shot.damage *= mult
	shot.reflectedBy = miko
	shot.travelled = 0
	if shot.owner == nil or shot.owner == miko then
		shot.owner = miko
	end
	shot.part.Color = Palette.Glow.Miko -- reflected: now Miko's shot
	shot.part.Name = shot.kind .. "Reflected"
	shot.part.CFrame = CFrame.new(at + shot.dir * 1.5)
	shieldFlash(miko)
end

local function stepShot(shot: Shot, dt: number): boolean -- false = remove
	local pos = shot.part.Position
	local move = shot.dir * shot.speed * dt

	for _, p in DuoService.Players() do
		if p:GetAttribute("Role") == "Miko" and p:GetAttribute("Blocking") and shot.reflectedBy ~= p then
			local r = rootOf(p)
			if r then
				local shieldPoint = r.Position + facing(p) * 1.5
				local near = (flat(pos + move - shieldPoint)).Magnitude <= C.ShieldHitRadius
				if near and (shot.friendly or shieldCovers(p, pos)) then
					reflect(shot, p, shieldPoint)
					return true
				end
			end
		end
	end

	local exclude = { fx }
	if shot.friendly then
		exclude = characters() -- friendly shots pass through players
	end
	local hit = workspace:Raycast(pos, move, worldParams(exclude))
	if hit then
		local inst = hit.Instance
		local model = inst:FindFirstAncestorOfClass("Model")
		local victim = model and Players:GetPlayerFromCharacter(model)
		if victim then
			if not shot.friendly then
				CombatService.HitPlayer(victim, shot.damage, pos)
				if shot.slow then
					victim:SetAttribute("SlowUntil", workspace:GetServerTimeNow() + 2)
				end
			end
		elseif shot.friendly then
			local enemy = Tags.find(inst, "Enemy")
			if enemy and enemy:IsA("BasePart") then
				CombatService.DamageEnemy(enemy, shot.damage, shot.owner, pos)
			end
			local switch = Tags.find(inst, "FireSwitch")
			if switch then
				InteractableService.Activate(switch)
			end
			local brazier = Tags.find(inst, "Brazier")
			if brazier then
				CombatService.Ignite(brazier)
			end
		end
		effect({ Size = Vector3.one * 2, CFrame = CFrame.new(hit.Position), Color = shot.part.Color }, 0.2)
		return false
	end
	shot.part.CFrame = CFrame.new(pos + move)
	shot.travelled += move.Magnitude
	return shot.travelled < MAX_SHOT_DISTANCE
end

-- area effects used by the tools ---------------------------------------------------------------

function CombatService.FlameWall(cf: CFrame, owner: Player?)
	local T = Tuning.FireMage.FlameWall
	local part = effect({
		Name = "FlameWall",
		Size = Vector3.new(T.Length, 3, 1.5),
		CFrame = cf,
		Color = FIRE,
		Transparency = 0.25,
	})
	table.insert(walls, { part = part, owner = owner, untilTime = os.clock() + T.Life, nextTick = os.clock() })
end

-- Short-lived fire patches (Ember Trail): damage only, no blocking.
function CombatService.Embers(from: Vector3, to: Vector3, owner: Player?)
	local E = C.EmberTrail
	local mid = (from + to) / 2
	local len = (to - from).Magnitude
	if len < 1 then
		return
	end
	local part = effect({
		Name = "Embers",
		Size = Vector3.new(2, 0.4, len),
		CFrame = CFrame.lookAt(mid, to) * CFrame.new(0, -2.5, 0),
		Color = FIRE,
		Transparency = 0.4,
	}, E.Life)
	task.spawn(function()
		local stop = os.clock() + E.Life
		while os.clock() < stop and part.Parent do
			for p, _ in foes do
				local lp = part.CFrame:PointToObjectSpace(p.Position)
				if math.abs(lp.X) <= 1 + p.Size.X / 2 and math.abs(lp.Z) <= len / 2 + p.Size.Z / 2 then
					CombatService.DamageEnemy(p, E.Damage, owner, nil)
				end
			end
			task.wait(0.5)
		end
	end)
end

function CombatService.Radial(pos: Vector3, radius: number, damage: number, owner: Player?): number
	local hits = 0
	for part in foes do
		if flat(part.Position - pos).Magnitude <= radius + part.Size.X / 2 then
			if CombatService.DamageEnemy(part, damage, owner, nil) > 0 then
				hits += 1
			end
		end
	end
	return hits
end

function CombatService.Meteor(pos: Vector3, owner: Player?)
	local T = Tuning.FireMage.Meteor
	local marker = effect({
		Name = "MeteorMarker",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.3, T.Radius * 2, T.Radius * 2),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = FIRE, -- Kai's own attack area: orange, not danger red
		Transparency = 0.6,
	})
	task.delay(T.Cast, function()
		marker:Destroy()
		effect({
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * T.Radius * 2,
			CFrame = CFrame.new(pos),
			Color = FIRE,
			Transparency = 0.3,
		}, 0.5)
		CombatService.Radial(pos, T.Radius, T.Damage, owner)
	end)
end

function CombatService.Rally(pos: Vector3, owner: Player?)
	local T = Tuning.ShieldKnight.Rally
	effect({
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.5, T.Radius * 2, T.Radius * 2),
		CFrame = CFrame.new(pos - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Palette.Miko,
		Transparency = 0.2,
	}, 0.5)
	CombatService.Radial(pos, T.Radius, T.Damage, owner)
	CombatService.Stun(pos, T.Radius, T.Stun)
end

-- Sword arc: a box in front of the attacker. Returns how many enemies it hit.
function CombatService.MeleeBox(cf: CFrame, size: Vector3, damage: number, owner: Player?): number
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = characters()
	local hits = 0
	local seen: { [Instance]: boolean } = {}
	for _, part in workspace:GetPartBoundsInBox(cf, size, params) do
		local enemy = Tags.find(part, "Enemy")
		if enemy and enemy:IsA("BasePart") and not seen[enemy] then
			seen[enemy] = true
			if CombatService.DamageEnemy(enemy, damage, owner, cf.Position) > 0 then
				hits += 1
			end
		end
	end
	effect({ Size = size * Vector3.new(1, 0.2, 1), CFrame = cf, Color = Color3.new(1, 1, 1), Transparency = 0.6 }, 0.12)
	return hits
end

-- Shield Charge path: damage + shove enemies near the segment, break CrackedWall parts on it.
function CombatService.ChargeLine(from: Vector3, dir: Vector3, length: number, damage: number, owner: Player?)
	dir = unitOr(flat(dir), Vector3.zAxis)
	for part in foes do
		local rel = flat(part.Position - from)
		local along = rel:Dot(dir)
		if along >= -1 and along <= length + 2 and (rel - dir * along).Magnitude <= 3 + part.Size.X / 2 then
			CombatService.DamageEnemy(part, damage, owner, nil) -- a charge knocks shields aside: never blocked
			CombatService.Knock(part, dir, C.Knockback)
		end
	end
	-- the box reaches 4 studs past where Miko stopped: she stops AT the wall's face, the wall is beyond it
	local reach = length + 4
	local cf = CFrame.lookAt(from + dir * (reach / 2), from + dir * reach)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = characters()
	for _, part in workspace:GetPartBoundsInBox(cf, Vector3.new(5, 6, reach), params) do
		local wall = Tags.find(part, "CrackedWall")
		if wall and wall:IsA("BasePart") and wall.Parent then
			wall.CanCollide = false
			wall.CanQuery = false
			TweenService:Create(wall, TweenInfo.new(0.3), { Transparency = 1 }):Play()
			task.delay(0.35, wall.Destroy, wall)
			InteractableService.Evaluate()
		end
	end
end

-- Ignite (Kai, E): braziers light up, webs and wooden doors burn away.
function CombatService.Ignite(inst: Instance)
	if Tags.has(inst, "Brazier") and inst:IsA("BasePart") then
		if inst:GetAttribute("Lit") then
			return
		end
		inst:SetAttribute("Lit", true)
		local flame = effect({
			Name = "Flame",
			Size = Vector3.new(1.6, 2.2, 1.6),
			CFrame = inst.CFrame * CFrame.new(0, inst.Size.Y / 2 + 1, 0),
			Color = FIRE,
			Transparency = 0.1,
		})
		flame.Parent = inst
		local light = Instance.new("PointLight")
		light.Color = FIRE
		light.Range = 24
		light.Brightness = 3
		light.Parent = flame
		local switch = Tags.find(inst, "FireSwitch")
		if switch then
			InteractableService.Activate(switch)
		end
	elseif Tags.has(inst, "Burnable") and inst:IsA("BasePart") and inst.Parent then
		inst.Color = FIRE
		inst.Material = Enum.Material.Neon
		inst:SetAttribute("Burning", true)
		TweenService:Create(inst, TweenInfo.new(1), { Transparency = 1 }):Play()
		task.delay(1, function()
			inst:Destroy()
			InteractableService.Evaluate()
		end)
	end
end

-- enemy AI ---------------------------------------------------------------------------------------

local function stepMelee(foe: Foe, target: Player, dist: number, now: number, dt: number)
	local r = rootOf(target) :: BasePart
	if foe.state == "Windup" then
		if now >= foe.stateUntil then
			local to = flat(r.Position - foe.part.Position)
			if
				dist <= foe.spec.Reach + 1.5
				and flat(foe.part.CFrame.LookVector):Dot(unitOr(to, Vector3.zAxis)) > 0.3
			then
				CombatService.HitPlayer(target, foe.spec.Damage, foe.part.Position)
			end
			effect({
				Size = Vector3.new(foe.part.Size.X + 2, 0.3, foe.spec.Reach),
				CFrame = foe.part.CFrame * CFrame.new(0, -foe.part.Size.Y / 2 + 0.2, -foe.spec.Reach / 2),
				Color = DANGER,
				Transparency = 0.5,
			}, 0.2)
			tint(foe.part, nil, foe.color)
			foe.state = "Recover"
			foe.stateUntil = now + foe.spec.Recover
		end
	elseif foe.state == "Recover" then
		if now >= foe.stateUntil then
			foe.state = "Chase"
		end
	else
		face(foe, r.Position)
		if dist <= foe.spec.Reach then
			foe.state = "Windup"
			foe.stateUntil = now + foe.spec.Windup
			tint(foe.part, DANGER, foe.color:Lerp(Color3.new(1, 1, 1), 0.5)) -- telegraph (red = danger)
		else
			tryMove(foe, unitOr(flat(r.Position - foe.part.Position), Vector3.zAxis), foe.spec.Speed * dt)
		end
	end
end

local function stepArcher(foe: Foe, target: Player, dist: number, now: number, dt: number)
	local r = rootOf(target) :: BasePart
	local to = unitOr(flat(r.Position - foe.part.Position), Vector3.zAxis)
	face(foe, r.Position)
	if dist < foe.spec.KeepAway then
		tryMove(foe, -to, foe.spec.Speed * dt)
		face(foe, r.Position)
	elseif dist > foe.spec.Range then
		tryMove(foe, to, foe.spec.Speed * dt)
	end
	if now >= foe.nextShot and dist <= foe.spec.Range + 6 then
		foe.nextShot = now + foe.spec.Every
		CombatService.Fire({
			origin = foe.part.Position + to * (foe.part.Size.Z / 2 + 1),
			dir = to,
			speed = foe.spec.ArrowSpeed,
			damage = foe.spec.Damage,
			friendly = false,
			kind = "Arrow",
			size = 0.8,
			color = DANGER,
		})
	end
end

local function stepMage(foe: Foe, target: Player, dist: number, now: number)
	local r = rootOf(target) :: BasePart
	face(foe, r.Position)
	if now < foe.nextShot or dist > foe.spec.Range then
		return
	end
	foe.nextShot = now + foe.spec.Every / 2
	if foe.teleportNext then
		local angle = math.random() * math.pi * 2
		local dir = Vector3.new(math.cos(angle), 0, math.sin(angle))
		effect({ Size = foe.part.Size, CFrame = foe.part.CFrame, Color = foe.color, Transparency = 0.5 }, 0.3)
		tryMove(foe, dir, foe.spec.Teleport, true)
	else
		local to = unitOr(flat(r.Position - foe.part.Position), Vector3.zAxis)
		CombatService.Fire({
			origin = foe.part.Position + to * (foe.part.Size.Z / 2 + 1),
			dir = to,
			speed = foe.spec.OrbSpeed,
			damage = foe.spec.Damage,
			friendly = false,
			kind = "Orb",
			size = 1.6,
			color = DANGER:Lerp(Color3.fromRGB(150, 60, 255), 0.4),
			slow = true,
		})
	end
	foe.teleportNext = not foe.teleportNext
end

local function stepFoes(dt: number)
	local now = os.clock()
	for part, foe in foes do
		if not part.Parent then
			foes[part] = nil
			continue
		end
		if foe.kind == "ShieldGuard" and foe.shieldDownUntil > 0 and now >= foe.shieldDownUntil then
			foe.shieldDownUntil = 0
			setShieldVisible(foe, true)
		end
		if now < foe.stunUntil then
			continue
		end
		local target, dist = pickTarget(foe)
		if not target then
			foe.state = "Chase"
			continue
		end
		if not foe.awake then
			if dist > Tuning.Combat.Aggro then
				continue
			end
			foe.awake = true
		end
		if foe.kind == "StaticArcher" then
			stepArcher(foe, target, dist, now, dt)
		elseif foe.kind == "StaticMage" then
			stepMage(foe, target, dist, now)
		else
			stepMelee(foe, target, dist, now, dt)
		end
	end
end

local function stepWalls()
	local now = os.clock()
	local T = Tuning.FireMage.FlameWall
	for i = #walls, 1, -1 do
		local w = walls[i]
		if now >= w.untilTime or not w.part.Parent then
			w.part:Destroy()
			table.remove(walls, i)
			continue
		end
		if now >= w.nextTick then
			w.nextTick = now + T.TickEvery
			for part, foe in foes do
				local lp = w.part.CFrame:PointToObjectSpace(part.Position)
				local r = part.Size.X / 2
				if math.abs(lp.X) <= w.part.Size.X / 2 + r and math.abs(lp.Z) <= w.part.Size.Z / 2 + r then
					local dmg = if now < foe.chargedUntil then T.Tick * 2 else T.Tick
					CombatService.DamageEnemy(part, dmg, w.owner, nil)
				end
			end
		end
	end
end

-- Clear everything when a world unloads.
function CombatService.Clear()
	for _, shot in shots do
		shot.part:Destroy()
	end
	table.clear(shots)
	for _, w in walls do
		w.part:Destroy()
	end
	table.clear(walls)
end

function CombatService.Init()
	fx = Instance.new("Folder")
	fx.Name = "CombatFX"
	fx.Parent = workspace

	Tags.each("Enemy", register, function(inst)
		if inst:IsA("BasePart") then
			foes[inst] = nil
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		if paused() then
			return
		end
		stepFoes(dt)
		for i = #shots, 1, -1 do
			local shot = shots[i]
			if not shot.part.Parent or not stepShot(shot, dt) then
				shot.part:Destroy()
				table.remove(shots, i)
			end
		end
		stepWalls()
	end)
end

return CombatService
