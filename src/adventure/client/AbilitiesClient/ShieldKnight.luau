-- Miko's Shield Knight, client half. M3: sword combo, charge, rally and aim arrive with the castle combat layer.
-- For now: hold Tool2 to raise the shield (Blocking), which already slows movement and feeds enemy taunt.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local Input = require(script.Parent.Parent.Input)

local toolUse = Net.event("ToolUse")

local ShieldKnight = {}
local trove = Trove.new()

function ShieldKnight:Start()
	local block = Input.action("CastleTools", "Tool2")
	trove:Add(block.Pressed:Connect(function()
		toolUse:FireServer(2, nil, true)
	end))
	trove:Add(block.Released:Connect(function()
		toolUse:FireServer(2, nil, false)
	end))
end

function ShieldKnight:Stop()
	toolUse:FireServer(2, nil, false)
	trove:Clean()
end

return ShieldKnight
