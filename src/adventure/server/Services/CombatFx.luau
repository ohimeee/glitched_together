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

-- Kai's fire: flame + star sparks + warm light on a moving part (fireball, meteor rock)
function CombatFx.Fire(part: BasePart, scale: number)
	CombatFx.Emit(part, "Flame", scale, 45)
	CombatFx.Emit(part, "Stars", scale, 14, GOLD)
	local light = Instance.new("PointLight")
	light.Name = "FxLight"
	light.Color = ToolFx.Fire
	light.Range = 10 + scale * 4
	light.Brightness = 2.5
	light.Parent = part
end

-- Re-tints every tinted emitter + light on a part (a fireball turned into Miko's shot by her shield)
function CombatFx.Tint(part: BasePart, color: Color3)
	for _, d in part:GetChildren() do
		if d:IsA("ParticleEmitter") then
			if d.Name == "FxFlame" then
				d.Enabled = false -- painted fire can't be recolored: swap it for tinted stars
			else
				d.Color = ColorSequence.new(color)
			end
		elseif d:IsA("PointLight") then
			d.Color = color
		end
	end
	if not part:FindFirstChild("FxRetinted") then
		local e = CombatFx.Emit(part, "Stars", 1.4, 30, color)
		e.Name = "FxRetinted"
	end
end

function CombatFx.Impact(pos: Vector3, fire: boolean, color: Color3)
	if fire then
		CombatFx.Burst(
			pos,
			{ { "Flame", 8, 1.6 }, { "Stars", 14, 1.4, GOLD }, { "Smoke", 4, 1.4, WHITE } },
			ToolFx.Fire
		)
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

return CombatFx
