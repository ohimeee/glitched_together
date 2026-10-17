-- Low-end device pass (mobile pass, LAUNCH.md §3): on a phone / tablet, or with the graphics slider low, every
-- particle emitter in the world (ambient dust, fire, embers, sparkles) runs at Tuning.Perf.LowParticles of its rate
-- on this client only. Big one-shot bursts (Emit) are left alone: they read as the hit itself.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)

local PerfController = {}

local function qualityLow(): boolean
	local ok, level = pcall(function()
		return UserSettings().GameSettings.SavedQualityLevel
	end)
	if not ok or level == Enum.SavedQualitySetting.Automatic then
		return false
	end
	return level.Value <= Tuning.Perf.LowQualityLevel
end

function PerfController.Low(): boolean
	return (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) or qualityLow()
end

local scaled: { [Instance]: boolean } = {}
setmetatable(scaled, { __mode = "k" }) -- emitters that go away drop out

local function scale(d: Instance)
	if d:IsA("ParticleEmitter") and not scaled[d] then
		scaled[d] = true
		d.Rate *= Tuning.Perf.LowParticles
	end
end

function PerfController.Init()
	if not PerfController.Low() then
		return
	end
	for _, d in workspace:GetDescendants() do
		scale(d)
	end
	workspace.DescendantAdded:Connect(function(d)
		if d:IsA("ParticleEmitter") then
			task.defer(scale, d) -- after its creator has set the rate
		end
	end)
	Players.LocalPlayer:SetAttribute("LowPerf", true) -- for checks in Studio
end

return PerfController
