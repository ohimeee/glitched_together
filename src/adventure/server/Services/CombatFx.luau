-- Starfall Castle effects (art-direction.md §12): painted storybook fire with star sparks (Kai's motif), teal
-- rings for Miko's shield, a white sword slash, dashed rings on the floor for area attacks (read from the top-down
-- camera). CombatService keeps its invisible gameplay parts; this only hangs particles, lights and decals on them.
-- Server-side so every client sees the same thing. Textures: textures/make_castlefx.py (ids in Config/ToolFx).
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ToolFx = require(ReplicatedStorage.Shared.Config.ToolFx)

local TEX = ToolFx.Textures
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 214, 110) -- star sparks: warm gold, so Kai's orange stays on the flames

local CombatFx = { Gold = GOLD }

local function seq(a: number, b: number): NumberSequence
	return NumberSequence.new(a, b)
end

local FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.75, 0.15),
	NumberSequenceKeypoint.new(1, 1),
})

-- Emitter presets. `scale` sizes everything (a fireball vs a meteor).
type Preset = (scale: number, color: Color3) -> { [string]: any }

local Presets: { [string]: Preset } = {
	-- the painted flame texture already carries its colors: keep the emitter white
	Flame = function(scale, _)
		return {
			Texture = TEX.Flame,
			Color = ColorSequence.new(WHITE),
			Size = seq(scale * 1.3, scale * 0.2),
			Transparency = FADE,
			Lifetime = NumberRange.new(0.25, 0.45),
			Speed = NumberRange.new(scale * 1.5, scale * 3),
			SpreadAngle = Vector2.new(25, 25),
			Rotation = NumberRange.new(-15, 15),
			RotSpeed = NumberRange.new(-40, 40),
			LightEmission = 0.35,
			EmissionDirection = Enum.NormalId.Top,
		}
	end,
	Stars = function(scale, color)
		return {
			Texture = TEX.StarSpark,
			Color = ColorSequence.new(color),
			Size = seq(scale * 0.45, 0),
			Transparency = FADE,
			Lifetime = NumberRange.new(0.4, 0.7),
			Speed = NumberRange.new(scale * 3, scale * 6),
			SpreadAngle = Vector2.new(180, 180),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-200, 200),
			Drag = 4,
			LightEmission = 0.6,
		}
	end,
	Smoke = function(scale, color)
		return {
			Texture = TEX.Smoke,
			Color = ColorSequence.new(color),
			Size = seq(scale * 0.8, scale * 2),
			Transparency = NumberSequence.new(0.45, 1),
			Lifetime = NumberRange.new(0.6, 1.1),
			Speed = NumberRange.new(scale * 0.8, scale * 1.6),
			SpreadAngle = Vector2.new(35, 35),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-30, 30),
			EmissionDirection = Enum.NormalId.Top,
			LightInfluence = 1,
		}
	end,
	-- Kai's fireball body: a looping volumetric fire flipbook (colors baked in) locked to the ball
	FireBody = function(scale, _)
		return {
			Texture = TEX.FireBurst, -- each particle blooms as fire and cools to smoke over its life
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Color = ColorSequence.new(WHITE),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, scale * 1.6),
				NumberSequenceKeypoint.new(0.3, scale * 2.1),
				NumberSequenceKeypoint.new(1, scale * 1.8),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.15, 0),
				NumberSequenceKeypoint.new(0.8, 0.1),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(0.3, 0.45),
			Speed = NumberRange.new(0),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-120, 120),
			LightEmission = 0.55,
			LockedToPart = true,
			ZOffset = 1,
		}
	end,
	-- the flames it sheds behind it: the same fire left in the air, shrinking and cooling
	FireTrail = function(scale, _)
		return {
			Texture = TEX.FireBurst, -- each particle blooms as fire and cools to smoke over its life
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Color = ColorSequence.new(WHITE, Color3.fromRGB(255, 120, 70)),
			Size = seq(scale * 1.5, scale * 0.2),
			Transparency = NumberSequence.new(0.1, 1),
			Lifetime = NumberRange.new(0.2, 0.38),
			Speed = NumberRange.new(scale * 0.5, scale * 1.5),
			SpreadAngle = Vector2.new(180, 180),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-90, 90),
			Acceleration = Vector3.new(0, 6, 0),
			LightEmission = 0.45,
		}
	end,
	-- fire blooming and cooling to smoke (one-shot flipbook): impacts, the cast flash, burning wood
	FireBurst = function(scale, _)
		return {
			Texture = TEX.FireBurst,
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Color = ColorSequence.new(WHITE),
			Size = seq(scale * 2.4, scale * 3.4),
			Transparency = NumberSequence.new(0),
			Lifetime = NumberRange.new(0.8, 1),
			Speed = NumberRange.new(scale * 0.3, scale * 1.2),
			SpreadAngle = Vector2.new(180, 180),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-30, 30),
			Acceleration = Vector3.new(0, 3, 0),
			Drag = 2,
			LightEmission = 0.3,
		}
	end,
	-- flames licking up off burning wood (rising, not locked)
	WoodFire = function(scale, _)
		return {
			Texture = TEX.FireBurst, -- each particle blooms as fire and cools to smoke over its life
			FlipbookLayout = Enum.ParticleFlipbookLayout.Grid8x8,
			FlipbookMode = Enum.ParticleFlipbookMode.OneShot,
			Color = ColorSequence.new(WHITE, Color3.fromRGB(255, 110, 60)),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, scale * 0.8),
				NumberSequenceKeypoint.new(0.3, scale * 1.4),
				NumberSequenceKeypoint.new(1, scale * 0.3),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.12, 0.05),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Lifetime = NumberRange.new(0.5, 0.85),
			Speed = NumberRange.new(scale * 1.5, scale * 3),
			SpreadAngle = Vector2.new(12, 12),
			Rotation = NumberRange.new(0, 360),
			RotSpeed = NumberRange.new(-60, 60),
			Acceleration = Vector3.new(0, scale * 2, 0),
			EmissionDirection = Enum.NormalId.Top,
			LightEmission = 0.5,
		}
	end,
	-- glowing round embers (white texture, tinted from pale gold to `color`)
	Embers = function(scale, color)
		return {
			Texture = TEX.Ember,
			Color = ColorSequence.new(Color3.fromRGB(255, 236, 160), color),
			Size = seq(scale * 0.22, 0),
			Transparency = NumberSequence.new(0, 0.3),
			Lifetime = NumberRange.new(0.4, 0.9),
			Speed = NumberRange.new(scale * 2, scale * 6),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 4, 0),
			Drag = 2.5,
			LightEmission = 1,
		}
	end,
	-- a flat shockwave on the floor (readable from the top-down camera)
	Ring = function(scale, color)
		return {
			Texture = TEX.FreezeRing,
			Color = ColorSequence.new(color),
			Size = seq(scale * 0.2, scale),
			Transparency = FADE,
			Lifetime = NumberRange.new(0.4),
			Speed = NumberRange.new(0.01),
			SpreadAngle = Vector2.zero,
			EmissionDirection = Enum.NormalId.Top,
			Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			LockedToPart = true,
		}
	end,
}

local function makeEmitter(parent: Instance, preset: string, scale: number, color: Color3?): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.Name = "Fx" .. preset
	e.LightInfluence = 0
	for k, v in Presets[preset](scale, color or WHITE) do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

-- A continuous emitter on a part (fireball trail, flame wall, brazier). `rate` particles per second.
function CombatFx.Emit(parent: Instance, preset: string, scale: number, rate: number, color: Color3?): ParticleEmitter
	local e = makeEmitter(parent, preset, scale, color)
	e.Rate = rate
	return e
end

-- One-shot bursts at a point: { { preset, count, scale, color? }, ... }
function CombatFx.Burst(pos: Vector3, parts: { { any } }, lightColor: Color3?, lightRange: number?)
	local host = Instance.new("Part")
	host.Name = "FxBurst"
	host.Anchored = true
	host.CanCollide = false
	host.CanQuery = false
	host.CanTouch = false
	host.Transparency = 1
	host.Size = Vector3.one * 0.2
	host.CFrame = CFrame.new(pos)
	host.Parent = workspace
	for _, item in parts do
		local e = makeEmitter(host, item[1], item[3], item[4])
		e.Enabled = false
		e:Emit(item[2])
	end
	if lightColor then
		local light = Instance.new("PointLight")
		light.Color = lightColor
		light.Range = lightRange or 14
		light.Brightness = 4
		light.Parent = host
		TweenService:Create(light, TweenInfo.new(0.4), { Brightness = 0 }):Play()
	end
	Debris:AddItem(host, 1.5)
end

-- Kai's fire on a moving part (fireball, meteor rock): a looping volumetric fire body, flames shed behind it, a
-- flame streak (Trail), embers, a few of his gold star sparks and a flickering warm light.
local FIRE_ORANGE = Color3.fromRGB(255, 120, 40)
function CombatFx.Fire(part: BasePart, scale: number)
	CombatFx.Emit(part, "FireBody", scale, 28)
	CombatFx.Emit(part, "FireTrail", scale, 70)
	CombatFx.Emit(part, "Embers", scale, 22, FIRE_ORANGE)
	CombatFx.Emit(part, "Stars", scale * 0.7, 5, GOLD)
	local a0 = Instance.new("Attachment")
	a0.Name = "FxTrailA"
	a0.Position = Vector3.new(0, scale * 0.45, 0)
	a0.Parent = part
	local a1 = Instance.new("Attachment")
	a1.Name = "FxTrailB"
	a1.Position = Vector3.new(0, -scale * 0.45, 0)
	a1.Parent = part
	local trail = Instance.new("Trail")
	trail.Name = "FxTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Texture = TEX.FireTrail
	trail.TextureMode = Enum.TextureMode.Stretch
	trail.FaceCamera = true
	trail.Lifetime = 0.16
	trail.LightEmission = 0.6
	trail.LightInfluence = 0
	trail.Transparency = NumberSequence.new(0.05, 1)
	trail.WidthScale = NumberSequence.new(1, 0.25)
	trail.Parent = part
	local light = Instance.new("PointLight")
	light.Name = "FxLight"
	light.Color = ToolFx.Fire
	light.Range = 10 + scale * 4
	light.Brightness = 2.5
	light.Parent = part
	task.spawn(function() -- firelight flickers (ends with the part)
		while light.Parent and part.Parent do
			light.Brightness = 2.1 + math.random() * 0.9
			light.Range = 10 + scale * (3.4 + math.random() * 1.2)
			task.wait(0.06)
		end
	end)
end

-- The flash at Kai's hand as a fireball leaves it.
function CombatFx.CastFlash(pos: Vector3, scale: number)
	CombatFx.Burst(
		pos,
		{ { "FireBurst", 1, scale * 0.45 }, { "Embers", 6, scale * 0.7, FIRE_ORANGE } },
		ToolFx.Fire,
		10
	)
end

-- Ignite's spark: a small fireball flicked from Kai's hand to `to` along a low arc. Returns its flight time.
function CombatFx.IgniteBolt(from: Vector3, to: Vector3): number
	local flight = math.clamp((to - from).Magnitude / 120, 0.08, 0.3)
	local p = Instance.new("Part")
	p.Name = "FxIgniteBolt"
	p.Shape = Enum.PartType.Ball
	p.Size = Vector3.one * 0.6
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.CFrame = CFrame.new(from)
	p.Parent = workspace
	CombatFx.Emit(p, "FireBody", 0.55, 30)
	CombatFx.Emit(p, "FireTrail", 0.6, 90)
	CombatFx.Emit(p, "Embers", 0.6, 30, FIRE_ORANGE)
	local start = os.clock()
	task.spawn(function()
		while p.Parent do
			local k = math.min(1, (os.clock() - start) / flight)
			p.CFrame = CFrame.new(from:Lerp(to, k) + Vector3.new(0, math.sin(k * math.pi) * 2, 0))
			if k >= 1 then
				break
			end
			task.wait()
		end
		for _, e in p:GetChildren() do
			if e:IsA("ParticleEmitter") then
				e.Enabled = false
			end
		end
		CombatFx.Burst(to, { { "FireBurst", 1, 0.7 }, { "Embers", 10, 0.9, FIRE_ORANGE } }, ToolFx.Fire, 12)
		Debris:AddItem(p, 0.5)
	end)
	return flight
end

-- Kai's Flame Wall on its (invisible) gameplay part, local X = its length (user, Oct 11: "remake the firewall
-- animation", then "doesn't feel like a wall of fire"). A continuous curtain: a sheet of tall flames packed along the
-- whole length (box emitters, ~7 studs high) standing on a molten line in the floor, flame tongues licking higher,
-- an ember stream and dark smoke over the top. It erupts from the middle outward, roars, then dies down over the last
-- 0.9 s of `life` (CombatService removes the part).
function CombatFx.FlameWall(part: BasePart, life: number)
	local length = part.Size.X
	local floorY = -part.Size.Y / 2
	local segments = math.max(3, math.round(length / 3)) -- the curtain lights segment by segment from the middle
	local emitters: { { e: ParticleEmitter, full: number } } = {}
	local segs = {}
	for i = 1, segments do
		local x = ((i - 0.5) / segments - 0.5) * length
		local seg = Instance.new("Part")
		seg.Name = "FxWallSeg"
		seg.Anchored = true
		seg.CanCollide = false
		seg.CanQuery = false
		seg.CanTouch = false
		seg.Transparency = 1
		seg.Size = Vector3.new(length / segments, 0.6, 0.9)
		seg.CFrame = part.CFrame * CFrame.new(x, floorY + 0.4, 0)
		seg.Parent = part
		local function add(preset: string, scale: number, rate: number, color: Color3?): ParticleEmitter
			local e = makeEmitter(seg, preset, scale, color)
			e.Shape = Enum.ParticleEmitterShape.Box
			e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
			e.Rate = 0
			table.insert(emitters, { e = e, full = rate })
			return e
		end
		-- the curtain: dense, tall, rising fast so the flames join into one sheet
		local sheet = add("WoodFire", 2, 34)
		sheet.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1.8),
			NumberSequenceKeypoint.new(0.35, 3),
			NumberSequenceKeypoint.new(1, 0.8),
		})
		sheet.Speed = NumberRange.new(6, 9)
		sheet.Lifetime = NumberRange.new(0.55, 0.8)
		sheet.SpreadAngle = Vector2.new(6, 6)
		-- tongues: fewer, faster, licking above the sheet
		local tongues = add("WoodFire", 1.4, 8)
		tongues.Speed = NumberRange.new(10, 14)
		tongues.Lifetime = NumberRange.new(0.5, 0.7)
		-- base fire: big rolling flames low on the line, so the wall has a solid foot
		local base = add("FireBurst", 0.9, 10)
		base.Speed = NumberRange.new(0.5, 1.5)
		base.Lifetime = NumberRange.new(0.5, 0.7)
		base.EmissionDirection = Enum.NormalId.Top
		add("Embers", 1.3, 10, FIRE_ORANGE).EmissionDirection = Enum.NormalId.Top
		local smoke = add("Smoke", 2.2, 1.5, Color3.fromRGB(60, 50, 56))
		smoke.Speed = NumberRange.new(5, 7)
		smoke.Lifetime = NumberRange.new(1, 1.4)
		table.insert(segs, { seg = seg, x = x, from = #emitters - 4, to = #emitters })
	end
	-- the molten line it stands on: a glowing crack in a scorch mark
	local line = Instance.new("Part")
	line.Name = "FxWallLine"
	line.Anchored = true
	line.CanCollide = false
	line.CanQuery = false
	line.CanTouch = false
	line.Material = Enum.Material.Neon
	line.Color = Color3.fromRGB(255, 140, 50)
	line.Transparency = 1
	line.Size = Vector3.new(0.05, 0.08, 0.05)
	line.CFrame = part.CFrame * CFrame.new(0, floorY + 0.05, 0)
	line.Parent = workspace
	local scorch = Instance.new("Part")
	scorch.Name = "FxWallScorch"
	scorch.Anchored = true
	scorch.CanCollide = false
	scorch.CanQuery = false
	scorch.CanTouch = false
	scorch.Transparency = 1
	scorch.Size = Vector3.new(length + 2.5, 0.05, 3.6)
	scorch.CFrame = part.CFrame * CFrame.new(0, floorY + 0.03, 0)
	local decal = Instance.new("Decal")
	decal.Face = Enum.NormalId.Top
	decal.Texture = TEX.Scorch
	decal.Transparency = 1
	decal.Parent = scorch
	scorch.Parent = workspace
	TweenService:Create(decal, TweenInfo.new(0.3), { Transparency = 0 }):Play()
	TweenService:Create(line, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(length, 0.08, 0.5),
		Transparency = 0.15,
	}):Play()

	local lights = {}
	for _, x in { -length / 3, 0, length / 3 } do
		local at = Instance.new("Attachment")
		at.Position = Vector3.new(x, floorY + 3, 0)
		at.Parent = part
		local light = Instance.new("PointLight")
		light.Color = ToolFx.Fire
		light.Range = 4
		light.Brightness = 0
		light.Shadows = false
		light.Parent = at
		table.insert(lights, light)
		TweenService:Create(light, TweenInfo.new(0.35), { Range = length * 0.6 + 6, Brightness = 2.4 }):Play()
	end

	-- erupt: segments light from the middle outward, each with a whoosh of fire
	local half = length / 2
	for _, s in segs do
		task.delay(math.abs(s.x) / half * 0.25, function()
			if not part.Parent then
				return
			end
			for i = s.from, s.to do
				local item = emitters[i]
				item.e.Rate = item.full
				item.e:Emit(math.ceil(item.full / 6))
			end
			CombatFx.Burst((part.CFrame * CFrame.new(s.x, floorY + 1, 0)).Position, { { "FireBurst", 2, 1.1 } })
		end)
	end
	task.spawn(function()
		local born = os.clock()
		while part.Parent and os.clock() < born + life - 0.9 do
			task.wait(0.07)
			if os.clock() - born > 0.4 then -- flicker once the eruption tweens are done
				for _, light in lights do
					light.Brightness = 2 + math.random() * 1
				end
			end
		end
		-- die down: flames shrink back into the line
		for _, item in emitters do
			item.e.Rate = item.full * 0.3
		end
		for _, light in lights do
			TweenService:Create(light, TweenInfo.new(0.8), { Brightness = 0 }):Play()
		end
		TweenService:Create(line, TweenInfo.new(0.9), { Transparency = 1, Size = Vector3.new(length, 0.08, 0.1) })
			:Play()
		task.wait(0.5)
		for _, item in emitters do
			item.e.Rate = 0
		end
		local fade = TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 1)
		TweenService:Create(decal, fade, { Transparency = 1 }):Play()
		Debris:AddItem(line, 1)
		Debris:AddItem(scorch, 3)
	end)
end

-- A burnt splat on the floor under `pos` that cools and fades (fireball and meteor impacts).
function CombatFx.Scorch(pos: Vector3, radius: number)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { workspace:FindFirstChild("CombatFX") :: Instance }
	params.RespectCanCollide = true
	local hit = workspace:Raycast(pos + Vector3.new(0, 1, 0), Vector3.new(0, -6, 0), params)
	if not hit or hit.Normal.Y < 0.7 then
		return
	end
	local p = Instance.new("Part")
	p.Name = "FxScorch"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(radius * 2, 0.05, radius * 2)
	p.CFrame = CFrame.new(hit.Position + Vector3.new(0, 0.04, 0)) * CFrame.Angles(0, math.random() * math.pi * 2, 0)
	local decal = Instance.new("Decal")
	decal.Face = Enum.NormalId.Top
	decal.Texture = TEX.Scorch
	decal.Parent = p
	p.Parent = workspace
	local fade = TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 2)
	TweenService:Create(decal, fade, { Transparency = 1 }):Play()
	Debris:AddItem(p, 4.6)
end

-- Re-tints every tinted emitter + light on a part (a fireball turned into Miko's shot by her shield)
function CombatFx.Tint(part: BasePart, color: Color3)
	for _, d in part:GetChildren() do
		if d:IsA("ParticleEmitter") then
			if d.Name == "FxFlame" or d.Name == "FxFireBody" or d.Name == "FxFireTrail" then
				d.Enabled = false -- painted fire can't be recolored: swap it for tinted stars
			else
				d.Color = ColorSequence.new(color)
			end
		elseif d:IsA("PointLight") then
			d.Color = color
		elseif d:IsA("Trail") then
			d.Texture = TEX.Ember -- a white streak that takes the new color
			d.Color = ColorSequence.new(color)
		end
	end
	if not part:FindFirstChild("FxRetinted") then
		local e = CombatFx.Emit(part, "Stars", 1.4, 30, color)
		e.Name = "FxRetinted"
	end
end

function CombatFx.Impact(pos: Vector3, fire: boolean, color: Color3)
	if fire then
		CombatFx.Burst(pos, {
			{ "FireBurst", 3, 1.3 },
			{ "Embers", 18, 1.3, FIRE_ORANGE },
			{ "Stars", 6, 1.2, GOLD },
			{ "Smoke", 3, 1.4, WHITE },
		}, ToolFx.Fire, 18)
		CombatFx.Scorch(pos, 2.2)
	else
		CombatFx.Burst(pos, { { "Stars", 12, 1.2, color }, { "Smoke", 3, 1, WHITE } })
	end
end

-- A dashed ring on the floor: meteor target (Kai orange: his own attack, never danger red), returns the part
function CombatFx.AreaMarker(pos: Vector3, radius: number, color: Color3): Part
	local p = Instance.new("Part")
	p.Name = "FxAreaMarker"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(radius * 2, 0.1, radius * 2)
	p.CFrame = CFrame.new(pos)
	local decal = Instance.new("Decal")
	decal.Face = Enum.NormalId.Top
	decal.Texture = TEX.AreaRing
	decal.Color3 = color
	decal.Parent = p
	p.Parent = workspace
	return p
end

-- The sword's arc: a white crescent decal lying in the swing's box, gone in a blink
function CombatFx.Slash(cf: CFrame, size: Vector3)
	local p = Instance.new("Part")
	p.Name = "FxSlash"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(size.X * 1.3, 0.1, size.Z * 1.3)
	p.CFrame = cf
	local decal = Instance.new("Decal")
	decal.Face = Enum.NormalId.Top
	decal.Texture = TEX.Slash
	decal.Parent = p
	p.Parent = workspace
	TweenService:Create(decal, TweenInfo.new(0.18), { Transparency = 1 }):Play()
	Debris:AddItem(p, 0.25)
end

-- Burnable wood catching fire (Kai's Ignite): flames spread across it from the bottom middle over `spread` s, the
-- wood chars dark, and at `burnTime` the planks tip over and drop away in a burst of fire and embers. Visual only:
-- the caller removes the gameplay part (its skin meshes are its children and go with it).
local CHAR = Color3.fromRGB(46, 30, 24)
function CombatFx.BurnAway(part: BasePart, spread: number, burnTime: number)
	local size = part.Size
	local skins = {}
	for _, d in part:GetChildren() do
		if d:IsA("BasePart") then
			table.insert(skins, d)
		end
	end
	if #skins == 0 then
		table.insert(skins, part) -- a bare grey-box part: burn the part itself
	end
	-- flame sources in a grid over the wood, lit outward from the bottom middle
	local cols = math.clamp(math.round(size.X / 2.2), 2, 7)
	local rows = math.clamp(math.round(size.Y / 2.5), 1, 3)
	local scale = math.clamp(math.min(size.X / cols, size.Y / rows) * 0.9, 1.2, 2.6)
	local sources = {}
	for c = 1, cols do
		for r = 1, rows do
			local x = (c - 0.5) / cols - 0.5
			local y = (r - 0.5) / rows - 0.5
			local at = Instance.new("Attachment")
			at.Name = "FxBurn"
			at.Position = Vector3.new(x * size.X * 0.92, y * size.Y * 0.85, 0)
			at.Parent = part
			local fire = makeEmitter(at, "WoodFire", scale, nil)
			fire.Rate = 0
			local embers = makeEmitter(at, "Embers", scale * 0.8, Color3.fromRGB(255, 110, 40))
			embers.Rate = 0
			local smoke = makeEmitter(at, "Smoke", scale * 1.2, Color3.fromRGB(60, 52, 56))
			smoke.Rate = 0
			local dist = math.sqrt(x * x + (y + 0.5) * (y + 0.5)) -- from the bottom middle
			table.insert(sources, { fire = fire, embers = embers, smoke = smoke, delay = dist / 1.12 * spread })
		end
	end
	for _, src in sources do
		task.delay(src.delay, function()
			if part.Parent then
				src.fire.Rate = 16
				src.embers.Rate = 6
				src.smoke.Rate = 2.5
				src.fire:Emit(2)
			end
		end)
	end
	local light = Instance.new("PointLight")
	light.Color = ToolFx.Fire
	light.Range = 4
	light.Brightness = 1
	light.Parent = part
	TweenService:Create(light, TweenInfo.new(spread + 0.3), { Range = size.X + 10, Brightness = 3.5 }):Play()
	for _, p in skins do
		local info = TweenInfo.new(burnTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(p, info, { Color = CHAR }):Play()
	end
	-- the fall: a copy of each plank (the real ones leave with the part) tips back, drops and fades
	task.delay(burnTime - 0.05, function()
		if not part.Parent then
			return
		end
		local base = part.CFrame * CFrame.new(0, -size.Y / 2, 0)
		local away = if math.random() < 0.5 then 1 else -1
		for _, p in skins do
			local piece = p:Clone()
			piece:ClearAllChildren()
			piece.Anchored = true
			piece.CanCollide = false
			piece.CanQuery = false
			piece.CanTouch = false
			piece.Transparency = 0
			piece.Color = CHAR
			piece.Parent = workspace
			local rel = base:ToObjectSpace(p.CFrame)
			local tip = base * CFrame.Angles(math.rad(80) * away, 0, math.rad(math.random(-12, 12))) * rel
			local info = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			TweenService:Create(piece, info, { CFrame = tip - Vector3.new(0, 0.6, 0) }):Play()
			TweenService
				:Create(piece, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0.4), {
					Transparency = 1,
				})
				:Play()
			Debris:AddItem(piece, 1)
		end
		for c = 1, cols do
			local x = ((c - 0.5) / cols - 0.5) * size.X
			local pos = (part.CFrame * CFrame.new(x, -size.Y * 0.1, 0)).Position
			CombatFx.Burst(pos, {
				{ "FireBurst", 1, scale * 0.8 },
				{ "Embers", 10, scale, Color3.fromRGB(255, 110, 40) },
				{ "Smoke", 3, scale * 1.4, Color3.fromRGB(60, 52, 56) },
			}, if c == 1 then ToolFx.Fire else nil, size.X + 8)
		end
		CombatFx.Scorch((part.CFrame * CFrame.new(0, -size.Y / 2, 0)).Position, math.max(size.X, 3) * 0.45)
	end)
end

return CombatFx
