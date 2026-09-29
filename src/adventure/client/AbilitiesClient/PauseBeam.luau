-- Kai's Pause Beam, client half: soft lock-on (6°) to Freezable objects, Tool1 = Freeze, Tool2 = Release.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Net = require(ReplicatedStorage.Shared.Net)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local Input = require(script.Parent.Parent.Input)
local Aim = require(script.Parent.Parent.Aim)

local toolUse = Net.event("ToolUse")
local T = Tuning.PauseBeam

local PauseBeam = {}
local trove = Trove.new()

function PauseBeam:Start()
	local lockHighlight = trove:Add(Instance.new("Highlight"))
	lockHighlight.FillTransparency = 0.7
	lockHighlight.FillColor = Color3.fromRGB(90, 170, 255)
	lockHighlight.OutlineColor = Color3.fromRGB(90, 170, 255)
	lockHighlight.Enabled = false
	lockHighlight.Parent = workspace

	local target: Instance? = nil
	trove:Add(RunService.RenderStepped:Connect(function()
		target = Aim.best({ "Freezable" }, T.Range, T.AimCone)
		lockHighlight.Adornee = target :: any
		lockHighlight.Enabled = target ~= nil
	end))

	trove:Add(Input.action("W1Tools", "Tool1").Pressed:Connect(function()
		if target then
			toolUse:FireServer(1, target)
		end
	end))
	trove:Add(Input.action("W1Tools", "Tool2").Pressed:Connect(function()
		toolUse:FireServer(2)
	end))
end

function PauseBeam:Stop()
	trove:Clean()
end

return PauseBeam
