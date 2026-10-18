-- Sends a duo into its own reserved Adventure server (used by the capsules and by "Continue with <partner>").
-- The Adventure's DuoService reads the roles from the "Duos" map; "Rejoin" lets a dropped player jump back in.
local TeleportService = game:GetService("TeleportService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Places = require(ReplicatedStorage.Shared.Config.Places)

local DUO_TTL = 60 * 60 -- seconds the duo record lives in MemoryStore

local DuoTeleport = {}

-- MemoryStore throws in an unpublished place; keep going so lock-ins can still be tested in Studio.
local duoMap: MemoryStoreHashMap, rejoinMap: MemoryStoreHashMap
local storeOk, storeErr = pcall(function()
	duoMap = MemoryStoreService:GetHashMap("Duos")
	rejoinMap = MemoryStoreService:GetHashMap("Rejoin")
end)
if not storeOk then
	warn(`[DuoTeleport] MemoryStore unavailable ({storeErr}); duo teleport and rejoin are off`)
end

-- false + "STUDIO" where teleports can't run (Studio, no place id); false + the error when the teleport failed.
-- `fresh` = both chose NEW GAME: the Adventure replaces their old duo save.
function DuoTeleport.Send(kai: Player, miko: Player, fresh: boolean?): (boolean, string?)
	if RunService:IsStudio() or Places.Adventure == 0 or not storeOk then
		print(
			`[DuoTeleport] {kai.Name} (Kai) + {miko.Name} (Miko) locked in{if fresh then " (NEW GAME)" else ""}. Teleport skipped in Studio.`
		)
		return false, "STUDIO"
	end
	local ok, err = pcall(function()
		DuoTeleport.Go({ kai, miko }, DuoTeleport.Reserve(kai.UserId, miko.UserId, fresh))
	end)
	if not ok then
		warn("Duo teleport failed:", err)
	end
	return ok, if ok then nil else tostring(err)
end

-- Reserves the duo's Adventure server and writes its Duos / Rejoin records; returns the access code. Throws on
-- failure. Split from Send so FIND A PARTNER can pair players in two lobby servers: each server then Go()es its own.
function DuoTeleport.Reserve(kaiId: number, mikoId: number, fresh: boolean?): string
	assert(storeOk and Places.Adventure ~= 0 and not RunService:IsStudio(), "teleports are off here")
	local accessCode, privateServerId = TeleportService:ReserveServer(Places.Adventure)
	duoMap:SetAsync(privateServerId, { kai = kaiId, miko = mikoId, fresh = fresh == true }, DUO_TTL)
	rejoinMap:SetAsync(tostring(kaiId), { code = accessCode, server = privateServerId }, DUO_TTL)
	rejoinMap:SetAsync(tostring(mikoId), { code = accessCode, server = privateServerId }, DUO_TTL)
	return accessCode
end

-- Teleports players of this server into a reserved server (from Reserve). Throws on failure.
function DuoTeleport.Go(players: { Player }, accessCode: string)
	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = accessCode
	TeleportService:TeleportAsync(Places.Adventure, players, options)
end

-- false where teleports can't run (Studio, no place id, no MemoryStore)
function DuoTeleport.Live(): boolean
	return storeOk and Places.Adventure ~= 0 and not RunService:IsStudio()
end

-- The rejoin entry of a player who dropped out of a duo run (nil = none / unreadable).
function DuoTeleport.RejoinEntry(userId: number): { code: string, server: string }?
	if not storeOk or Places.Adventure == 0 or RunService:IsStudio() then
		return nil
	end
	local ok, entry = pcall(function()
		return rejoinMap:GetAsync(tostring(userId))
	end)
	return if ok then entry else nil
end

return DuoTeleport
