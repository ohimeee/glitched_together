-- Miko's Layer Shift, client half: Tool1 toggles the Code Layer (CodeLayerController handles the look),
-- Tool2 pulls the aimed Code Layer object out into the real world.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Net = require(ReplicatedStorage.Shared.Net)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local Input = require(script.Parent.Parent.Input)
local Aim = require(script.Parent.Parent.Aim)

local toolUse = Net.event("ToolUse")
local T = Tuning.LayerShift

local LayerShift = {}
local trove = Trove.new()

function LayerShift:Start()
	trove:Add(Input.action("W3Tools", "Tool1").Pressed:Connect(function()
		toolUse:FireServer(1)
	end))
	trove:Add(Input.action("W3Tools", "Tool2").Pressed:Connect(function()
		local target = Aim.best({ "CodeLayer" }, T.PullRange, 8, function(inst)
			return inst:GetAttribute("PulledOut") ~= true
		end, "MikoShifted") -- Code Layer pieces only stop rays that act as shifted Miko
		if target then
			toolUse:FireServer(2, target)
		end
	end))
end

function LayerShift:Stop()
	trove:Clean()
end

return LayerShift
