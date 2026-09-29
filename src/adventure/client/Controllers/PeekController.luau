-- Partner Peek (hold Tab): see through your partner's camera, snap back on release (design.md §7).
-- Each client streams its camera CFrame 10x a second on an unreliable remote; the server relays it.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Net = require(ReplicatedStorage.Shared.Net)
local Input = require(script.Parent.Parent.Input)
local CameraController = require(script.Parent.CameraController)

local camera = workspace.CurrentCamera
local camSync = Net.event("CamSync") :: any

local PeekController = {}

local partnerCam: CFrame? = nil

function PeekController.Init()
	task.spawn(function()
		while true do
			task.wait(1 / Tuning.CamSyncRate)
			camSync:FireServer(camera.CFrame)
		end
	end)

	camSync.OnClientEvent:Connect(function(cf: CFrame)
		partnerCam = cf
	end)

	local peek = Input.action("BaseContext", "Peek")
	peek.Pressed:Connect(function()
		CameraController.SetOverride(function()
			return partnerCam
		end)
	end)
	peek.Released:Connect(function()
		CameraController.SetOverride(nil)
	end)
end

return PeekController
