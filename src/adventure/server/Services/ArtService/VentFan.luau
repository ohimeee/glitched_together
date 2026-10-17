-- Jump vents (every world): the air column was a bare pale-blue box. Now a steel floor fan sits at its foot (base
-- plate, riveted rim, four pitched blades under a grille) and white air streaks show which way it blows. The
-- blades spin on each client (FanController, tag "FanBlades"), forward while the vent lifts and backward while it
-- pushes down; the streaks swap ends with it. Nothing here collides or blocks aim rays.
local TweenService = game:GetService("TweenService")

local STEEL = Color3.fromHex("#8A8F99")
local DARK = Color3.fromHex("#2E3036")
local SPIN = 9 -- blade speed, radians per second
local v = Vector3.new

local function piece(
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	parent: Instance,
	shape: Enum.PartType?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = Enum.Material.Metal
	p.Color = color
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

local function streaks(at: BasePart, face: Enum.NormalId, speed: number, life: number): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.EmissionDirection = face
	e.Speed = NumberRange.new(speed * 0.8, speed)
	e.Lifetime = NumberRange.new(life * 0.8, life)
	e.Rate = 14
	e.Size = NumberSequence.new(0.18)
	e.Squash = NumberSequence.new(2.5) -- stretched along their flight: wind lines, not dots
	e.Orientation = Enum.ParticleOrientation.VelocityParallel
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.45),
		NumberSequenceKeypoint.new(0.8, 0.45),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Color = ColorSequence.new(Color3.new(1, 1, 1))
	e.LightEmission = 0.3
	e.Parent = at
	return e
end

return function(vent: BasePart, params: RaycastParams)
	local half = vent.Size / 2
	local foot = vent.CFrame * Vector3.new(0, -half.Y, 0)
	local hit = workspace:Raycast(foot + v(0, 1, 0), v(0, -4, 0), params)
	local ground = if hit then hit.Position.Y else foot.Y
	local d = math.min(vent.Size.X, vent.Size.Z)
	local r = d / 2
	local model = Instance.new("Model")
	model.Name = "VentFan"
	model.Parent = vent.Parent
	local upright = CFrame.Angles(0, 0, math.rad(90)) -- a cylinder's axis is X: stand it up
	local at = CFrame.new(foot.X, ground, foot.Z)
	piece(
		"BasePlate",
		v(0.4, d + 0.6, d + 0.6),
		at * CFrame.new(0, 0.2, 0) * upright,
		DARK,
		model,
		Enum.PartType.Cylinder
	)
	-- riveted rim: twelve curved-looking segments around the blades
	local seg = 2 * math.pi * (r + 0.3) / 12 + 0.15
	for i = 0, 11 do
		local a = i * math.pi / 6
		piece("Rim", v(seg, 1.8, 0.5), at * CFrame.Angles(0, a, 0) * CFrame.new(0, 1.1, r + 0.3), STEEL, model)
	end
	-- the blades turn around their hub
	local blades = Instance.new("Model")
	blades.Name = "FanBlades"
	local hub =
		piece("Hub", v(0.7, 1.4, 1.4), at * CFrame.new(0, 0.9, 0) * upright, DARK, blades, Enum.PartType.Cylinder)
	blades.PrimaryPart = hub
	for i = 0, 3 do
		local a = i * math.pi / 2
		piece(
			"Blade",
			v(1.4, 0.15, r - 0.9),
			at * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.9, (r - 0.9) / 2 + 0.6) * CFrame.Angles(0, 0, math.rad(28)),
			STEEL,
			blades
		)
	end
	blades.Parent = model
	-- the pivot the client spins about: with StreamingEnabled the Model can reach a client before its parts, and an
	-- empty Model's pivot is the world origin (the blades spun on Prologue SAVE SLOT 1, user Oct 4)
	blades:SetAttribute("Home", blades:GetPivot())
	blades:AddTag("FanBlades")
	-- grille: parallel bars across the top of the rim
	for k = -2, 2 do
		local z = k * r / 2.6
		local chord = 2 * math.sqrt(math.max(r * r - z * z, 0)) + 0.4
		piece("Grille", v(chord, 0.2, 0.2), at * CFrame.new(0, 2, z), DARK, model)
	end
	-- air streaks: up from the fan, or down from the top of the column
	local speed = 40
	local life = vent.Size.Y / speed
	local low = piece("AirLow", v(d * 0.8, 0.2, d * 0.8), at * CFrame.new(0, 2.2, 0), STEEL, model)
	local high = piece("AirHigh", v(d * 0.8, 0.2, d * 0.8), vent.CFrame * CFrame.new(0, half.Y - 0.2, 0), STEEL, model)
	low.Transparency = 1
	high.Transparency = 1
	local up = streaks(low, Enum.NormalId.Top, speed, life)
	local down = streaks(high, Enum.NormalId.Bottom, speed, life)
	vent.Transparency = math.max(vent.Transparency, 0.93) -- a faint column; the streaks show the air
	local column = vent.Transparency
	local flips = 0
	local function refresh(flipped: boolean?)
		local dir = (vent:GetAttribute("Direction") or 1) :: number
		up.Enabled = dir > 0
		down.Enabled = dir < 0
		blades:SetAttribute("Speed", SPIN * dir)
		if not flipped then
			return
		end
		-- the flip has to read (user, Oct 17: "no animation that the wind changes"): a gust of streaks the new way,
		-- the air column flashes, and the blades race for a moment before settling
		flips += 1
		local mine = flips
		local gust = if dir > 0 then up else down
		gust:Emit(40)
		blades:SetAttribute("Speed", SPIN * dir * 4)
		vent.Transparency = 0.55
		TweenService:Create(vent, TweenInfo.new(0.8), { Transparency = column }):Play()
		task.delay(0.9, function()
			if flips == mine then
				blades:SetAttribute("Speed", SPIN * dir)
			end
		end)
	end
	vent:GetAttributeChangedSignal("Direction"):Connect(function()
		refresh(true)
	end)
	refresh()
end
