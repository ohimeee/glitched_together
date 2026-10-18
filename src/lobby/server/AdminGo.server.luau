-- Admin solo teleport for testing the published game (the capsules need two players):
--   /go                     → a private Adventure server of your own, starting where your save is
--   /go <world> [checkpoint] → straight to that world (pp, castle, core, epi, pro or a full name; Adventure resolves it)
-- Only Config/Admins + the experience owner. The Adventure's AdminCommands reads the teleport data, re-checks the
-- player is an admin (teleport data passes through the client), skips the partner wait and jumps.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Admins = require(ReplicatedStorage.Shared.Config.Admins)
local Places = require(ReplicatedStorage.Shared.Config.Places)

local function go(player: Player, args: { string })
	local data = { AdminGo = true, World = args[1], Checkpoint = tonumber(args[2]) or 0 }
	if RunService:IsStudio() or Places.Adventure == 0 then
		print(`[AdminGo] {player.Name} → Adventure {data.World or "(save)"} {data.Checkpoint}: skipped in Studio`)
		return
	end
	local ok, err = pcall(function()
		local options = Instance.new("TeleportOptions")
		options.ReservedServerAccessCode = TeleportService:ReserveServer(Places.Adventure)
		options:SetTeleportData(data)
		TeleportService:TeleportAsync(Places.Adventure, { player }, options)
	end)
	if not ok then
		warn("[AdminGo] teleport failed:", err)
	end
end

local function watch(player: Player)
	player.Chatted:Connect(function(message)
		if not Admins.Allowed(player.UserId) then
			return
		end
		local args = string.split(message, " ")
		for i = #args, 1, -1 do
			if args[i] == "" then
				table.remove(args, i)
			end
		end
		if args[1] and args[1]:lower() == "/go" then
			table.remove(args, 1)
			go(player, args)
		end
	end)
end

Players.PlayerAdded:Connect(watch)
for _, player in Players:GetPlayers() do
	watch(player)
end
