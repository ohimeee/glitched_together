-- While you hold a Station (StationService), your forward / back input cranks it: forward along the camera = +1,
-- back = -1. MovementController roots you (the `Station` attribute blocks walking and jumping).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local StationController = {}

function StationController.Init()
	local inputEvent = Net.event("StationInput")
	local sent = 0
	RunService.Heartbeat:Connect(function()
		if player:GetAttribute("Station") == nil then
			sent = 0
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local axis = 0
		if humanoid then
			local look = camera.CFrame.LookVector * Vector3.new(1, 0, 1)
			local forward = if look.Magnitude > 0.01 then humanoid.MoveDirection:Dot(look.Unit) else 0
			axis = if forward > 0.3 then 1 elseif forward < -0.3 then -1 else 0
		end
		if axis ~= sent then
			sent = axis
			inputEvent:FireServer(axis)
		end
	end)
end

return StationController
