-- Pip hints (implementation.md §11): 20 s without progress → hint 1, 45 s → hint 2.
-- A checkpoint can carry its section's hints in `Hint1` / `Hint2` attributes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Dialogue = require(ReplicatedStorage.Shared.Config.Dialogue)
local Net = require(ReplicatedStorage.Shared.Net)
local CheckpointService = require(script.Parent.CheckpointService)

local HintService = {}

local hintEvent = Net.event("Hint")
local lastProgress = os.clock()
local sent = 0
local enabled = true

function HintService.Progress()
	lastProgress = os.clock()
	sent = 0
end

function HintService.SetEnabled(on: boolean)
	enabled = on
	HintService.Progress()
end

function HintService.Say(text: string)
	hintEvent:FireAllClients(text)
end

local function hintText(index: number): string
	local cp = CheckpointService.CurrentPart()
	local custom = cp and cp:GetAttribute(`Hint{index}`)
	if type(custom) == "string" and custom ~= "" then
		return custom
	end
	local set = Dialogue.GenericHints[math.random(1, #Dialogue.GenericHints)]
	return set[index] or set[1]
end

function HintService.Init()
	task.spawn(function()
		while true do
			task.wait(1)
			if not enabled or workspace:GetAttribute("BossFight") then
				continue
			end
			local stuck = os.clock() - lastProgress
			local nextAt = Tuning.HintAfter[sent + 1]
			if nextAt and stuck >= nextAt then
				sent += 1
				HintService.Say(hintText(sent))
			end
		end
	end)
end

return HintService
