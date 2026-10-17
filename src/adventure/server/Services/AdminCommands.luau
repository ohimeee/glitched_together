-- Admin chat commands for testing the published game (a phone has no command bar). They only set the same workspace
-- Debug* attributes the Studio command bar uses (Main / BossService listen for them); clients can't set workspace
-- attributes, so only these commands and Studio can drive them. Allowed: Config/Admins + the experience owner.
--   /world <name> [checkpoint]   /cp <checkpoint>   /kai   /miko   /swap (= /role [Kai|Miko])   /phase <n>   /ult
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Admins = require(ReplicatedStorage.Shared.Config.Admins)
local Worlds = require(ReplicatedStorage.Shared.Config.Worlds)

local AdminCommands = {}

local ALIAS = {
	pro = "Prologue",
	pp = "PixelPlains",
	plains = "PixelPlains",
	castle = "StarfallCastle",
	sc = "StarfallCastle",
	core = "GlitchedCore",
	gc = "GlitchedCore",
	epi = "Epilogue",
	ep = "Epilogue",
}

local function allowed(userId: number): boolean
	if game.CreatorType == Enum.CreatorType.User and userId == game.CreatorId then
		return true
	end
	return table.find(Admins.Ids, userId) ~= nil
end

local function worldName(text: string): string?
	local low = text:lower()
	if ALIAS[low] then
		return ALIAS[low]
	end
	for _, name in Worlds.Order do
		if name:lower() == low then
			return name
		end
	end
	return nil
end

local function jump(world: string, checkpoint: number)
	workspace:SetAttribute("DebugCheckpoint", checkpoint)
	workspace:SetAttribute("DebugWorld", nil) -- nil first: reloads even when already in that world
	workspace:SetAttribute("DebugWorld", world)
end

local handlers: { [string]: (args: { string }) -> () } = {
	world = function(args)
		local world = args[1] and worldName(args[1])
		if not world then
			warn(`[Admin] /world <name> [checkpoint]: names {table.concat(Worlds.Order, ", ")} (or pp, castle, core)`)
			return
		end
		jump(world, tonumber(args[2]) or 0)
	end,
	cp = function(args)
		local world = workspace:GetAttribute("World")
		local n = tonumber(args[1])
		if type(world) == "string" and n then
			jump(world, n)
		end
	end,
	role = function(args)
		-- solo: Kai / Miko; with two players any change swaps them (Main's DebugRole)
		local want = args[1] and (args[1]:sub(1, 1):upper() .. args[1]:sub(2):lower())
		workspace:SetAttribute("DebugRole", if want == "Kai" or want == "Miko" then want else tostring(os.clock()))
	end,
	kai = function()
		workspace:SetAttribute("DebugRole", "Kai")
	end,
	miko = function()
		workspace:SetAttribute("DebugRole", "Miko")
	end,
	swap = function()
		workspace:SetAttribute("DebugRole", tostring(os.clock()))
	end,
	phase = function(args)
		local n = tonumber(args[1])
		if n then
			workspace:SetAttribute("DebugBossPhase", nil)
			workspace:SetAttribute("DebugBossPhase", n)
		end
	end,
	ult = function()
		for _, p in Players:GetPlayers() do
			p:SetAttribute("Ultimate", 1)
		end
	end,
}

-- Player.Chatted (not TextChatCommand): it fires with both chat systems, and this place still runs the legacy one
local function onChat(player: Player, message: string)
	if message:sub(1, 1) ~= "/" or not allowed(player.UserId) then
		return
	end
	local args = string.split(message:sub(2), " ")
	for i = #args, 1, -1 do
		if args[i] == "" then
			table.remove(args, i)
		end
	end
	local handler = args[1] and handlers[args[1]:lower()]
	if handler then
		table.remove(args, 1)
		handler(args)
	end
end

function AdminCommands.Init()
	local function watch(player: Player)
		player.Chatted:Connect(function(message)
			onChat(player, message)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
end

return AdminCommands
