-- Dust motes drifting in the desk lamp's light (Config/Ambient.luau "Lobby"): a fixed local emitter volume over the
-- capsule ring. Purely visual.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ambient = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Ambient"))

local config = Ambient.Lobby
local box = Instance.new("Part")
box.Name = "LobbyDust"
box.Anchored = true
box.CanCollide = false
box.CanQuery = false
box.CanTouch = false
box.Transparency = 1
box.Size = config.Box
box.CFrame = CFrame.new(0, config.Box.Y / 2, -10)
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
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.3),
		NumberSequenceKeypoint.new(0.8, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Parent = box
end
box.Parent = workspace
