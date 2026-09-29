-- Ping (Q): raycast through the screen center, the server relays it, both players see a marker for 4 s.
-- The voiceless way to say "look here" (design.md §4).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Roles = require(ReplicatedStorage.Shared.Config.Roles)
local Net = require(ReplicatedStorage.Shared.Net)
local Input = require(script.Parent.Parent.Input)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local pingEvent = Net.event("Ping")

local PingController = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function marker(from: Player, pos: Vector3)
	local info = (Roles :: any)[from:GetAttribute("Role") or "Kai"]
	local anchor = Instance.new("Part")
	anchor.Name = "PingMarker"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.Position = pos
	anchor.Parent = workspace

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(90, 90)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.StudsOffset = Vector3.new(0, 2.5, 0)
	gui.Parent = anchor
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.fromScale(1, 0.65)
	icon.BackgroundTransparency = 1
	icon.Font = Enum.Font.FredokaOne
	icon.TextScaled = true
	icon.TextColor3 = info.Color
	icon.TextStrokeTransparency = 0.2
	icon.Text = if info.Shape == "Triangle" then "▼" else "●"
	icon.Parent = gui
	local name = icon:Clone()
	name.Size = UDim2.fromScale(1, 0.35)
	name.Position = UDim2.fromScale(0, 0.65)
	name.Text = info.Label
	name.Parent = gui

	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.Material = Enum.Material.Neon
	beam.Color = info.Color
	beam.Transparency = 0.4
	beam.Size = Vector3.new(0.3, 12, 0.3)
	beam.Position = pos + Vector3.new(0, 6, 0)
	beam.Parent = anchor

	Debris:AddItem(anchor, Tuning.PingLife)
end

function PingController.Init()
	Input.action("BaseContext", "Ping").Pressed:Connect(function()
		local character = player.Character
		rayParams.FilterDescendantsInstances = if character then { character } else {}
		local size = camera.ViewportSize
		local ray = camera:ViewportPointToRay(size.X / 2, size.Y / 2)
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, rayParams)
		pingEvent:FireServer(if hit then hit.Position else ray.Origin + ray.Direction * 60)
	end)

	pingEvent.OnClientEvent:Connect(function(from: Player, pos: Vector3)
		marker(from, pos)
	end)
end

return PingController
