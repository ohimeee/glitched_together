-- Closed beta gate (Config/Beta), server only, both places: a player below the tester rank in the community is kicked
-- with the beta note. A failed rank lookup lets the player in (a Roblox hiccup must not lock testers out).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Admins = require(ReplicatedStorage.Shared.Config.Admins)
local Beta = require(ReplicatedStorage.Shared.Config.Beta)

local BetaGate = {}

local function check(p: Player)
	if not Beta.Enabled or Admins.Allowed(p.UserId) then
		return
	end
	local ok, rank = pcall(p.GetRankInGroup, p, Beta.GroupId)
	if ok and rank < Beta.MinRank then
		p:Kick(Beta.Message)
	end
end

function BetaGate.Init()
	Players.PlayerAdded:Connect(check)
	for _, p in Players:GetPlayers() do
		task.spawn(check, p)
	end
end

return BetaGate
