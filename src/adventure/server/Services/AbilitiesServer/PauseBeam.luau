-- Kai, World 1 (mechanics.md §4): Freeze a Freezable object for 4 s (one at a time), Release it early.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Net = require(ReplicatedStorage.Shared.Net)
local MoverService = require(script.Parent.Parent.MoverService)

local toolResult = Net.event("ToolResult") -- every client draws the beam / release (ToolFxController)

local PauseBeam = { BlockedBy = { "Downed", "InCutscene" }, Cooldowns = { [1] = 0.25, [2] = 0.25 } }
local frozenBy: { [Player]: Instance } = {}

function PauseBeam.Use(player: Player, useIndex: number, target: Instance?)
	if useIndex == 2 then -- Release
		local current = frozenBy[player]
		if current then
			MoverService.Resume(current)
			frozenBy[player] = nil
			toolResult:FireAllClients("Released", player, current)
		end
		return
	end

	local freezable = Tags.find(target, "Freezable")
	if not freezable then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	if (Tags.position(freezable) - root.Position).Magnitude > Tuning.PauseBeam.Range + Tuning.SlackRange then
		return
	end

	local old = frozenBy[player]
	if old and old ~= freezable then
		MoverService.Resume(old)
	end
	frozenBy[player] = freezable
	MoverService.Pause(freezable, Tuning.PauseBeam.Duration)
	toolResult:FireAllClients("Froze", player, freezable)
end

return PauseBeam
