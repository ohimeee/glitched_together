-- Ambient air (Config/Ambient.luau): drifting pollen, dust, fireflies, graphite flakes, menu sparkles around the camera,
-- per world. A local (client-made) invisible box part follows the camera; particles live in world space, so they stay put while
-- the camera moves through them. Purely visual and local.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Ambient = require(ReplicatedStorage.Shared.Config.Ambient)

local AmbientController = {}

local holder: Part? = nil

local function build(worldName: string?)
	if holder then
		holder:Destroy()
		holder = nil
	end
	local config = worldName and Ambient[worldName]
	if not config then
		return
	end
	local p = Instance.new("Part")
	p.Name = "AmbientAir"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = config.Box
	for _, layer in config.Layers do
		local e = Instance.new("ParticleEmitter")
		e.Texture = layer.Texture
		e.Color = ColorSequence.new(layer.Color)
		e.Rate = layer.Rate
		e.Size = NumberSequence.new(layer.Size.Min, layer.Size.Max)
		e.Lifetime = layer.Lifetime
		e.Speed = layer.Speed
		e.SpreadAngle = Vector2.new(180, 180)
		e.Acceleration = layer.Drift
		e.LightEmission = layer.Glow
		e.LightInfluence = layer.Light
		e.Shape = Enum.ParticleEmitterShape.Box
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		e.LockedToPart = false
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = if layer.Spin then NumberRange.new(-40, 40) else NumberRange.new(0)
		e.Transparency = if layer.Twinkle
			then NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.15, 0.1),
				NumberSequenceKeypoint.new(0.35, 0.8),
				NumberSequenceKeypoint.new(0.55, 0.15),
				NumberSequenceKeypoint.new(0.8, 0.7),
				NumberSequenceKeypoint.new(1, 1),
			})
			else NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.2, 0.35),
				NumberSequenceKeypoint.new(0.8, 0.35),
				NumberSequenceKeypoint.new(1, 1),
			})
		e.Parent = p
	end
	p.Parent = workspace -- created on the client, so it exists only here
	holder = p
end

function AmbientController.Init()
	build(workspace:GetAttribute("World"))
	workspace:GetAttributeChangedSignal("World"):Connect(function()
		build(workspace:GetAttribute("World"))
	end)
	RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if holder and camera then
			holder.CFrame = CFrame.new(camera.CFrame.Position + camera.CFrame.LookVector * 22)
		end
	end)
end

return AmbientController
