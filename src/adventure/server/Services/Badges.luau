-- Badges (LAUNCH.md §4): both players get each one. Ids in Config/Badges (0 = not created yet: skipped).
-- Hooks: WorldService.Advance → Badges.World, BossService.Finished → boss badge, ContinueYes (Main) → Badges.Finished.
local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ids = require(ReplicatedStorage.Shared.Config.Badges)
local DuoService = require(script.Parent.DuoService)

local Badges = {}

local function award(id: number?)
	if not id or id == 0 then
		return
	end
	for _, p in DuoService.Players() do
		task.spawn(function()
			local ok, err = pcall(BadgeService.AwardBadge, BadgeService, p.UserId, id)
			if not ok then
				warn("[Badges] award", id, "to", p.Name, "failed:", err)
			end
		end)
	end
end

function Badges.World(name: string)
	award(Ids.Worlds[name])
end

function Badges.Finished()
	award(Ids.Finished)
end

function Badges.Init()
	local BossService = require(script.Parent.BossService)
	BossService.Finished:Connect(function(name: string)
		award(Ids.Bosses[name])
	end)
end

return Badges
