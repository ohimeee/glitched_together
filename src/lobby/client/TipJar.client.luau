-- The lobby tip jar on the desk: its [E] opens the shared tip panel (Util/TipPanel; receipts: server Util/TipJar).
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TipPanel = require(ReplicatedStorage.Shared.Util.TipPanel)

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
	if prompt.Name == "SupportPrompt" then
		TipPanel.Open()
	end
end)
