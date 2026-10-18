-- FIND A PARTNER (user pick Oct 18: a solo joiner shouldn't stand alone at the capsules). One queue for every lobby
-- server in MemoryStore (SortedMap "MatchQueue", key = userId, sort = join time). Each server with searchers reads it
-- every Tuning.Matchmaking.Poll s: the OLDER entry of a pair starts the match (so two servers never chase each other),
-- claims both entries, reserves the Adventure server (DuoTeleport.Reserve), writes the access code into the
-- partner's entry and teleports its own player; the partner's server sees the code on its next read and sends theirs.
-- Roles: ANY / KAI / MIKO wish; KAI + KAI (or MIKO + MIKO) only pairs after both waited RoleFallback s (coin flip).
-- Studio / unpublished: matches inside this server only and skips the teleport (UI testable with 2 clients).
-- Client: lobby/client/MatchUI.client.luau.
local HttpService = game:GetService("HttpService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local DuoTeleport = require(script.Parent.DuoTeleport)

local T = Tuning.Matchmaking
local findEvent = Net.event("MatchFind") -- client → server: role wish ("Any" | "Kai" | "Miko")
local cancelEvent = Net.event("MatchCancel") -- client → server
local statusEvent = Net.event("MatchStatus") -- server → client: state, info

type Wish = "Any" | "Kai" | "Miko"
type Entry = {
	job: string,
	role: Wish,
	since: number,
	name: string,
	claim: { by: string, at: number }?,
	match: { code: string, partner: string, role: string }?,
}

local WISHES = { Any = true, Kai = true, Miko = true }
local searching: { [Player]: { role: Wish, since: number, refreshed: number } } = {}
local live = DuoTeleport.Live()

local queue: MemoryStoreSortedMap?
if live then
	local ok, err = pcall(function()
		queue = MemoryStoreService:GetSortedMap("MatchQueue")
	end)
	if not ok then
		warn("[Matchmaking] MemoryStore unavailable, matching inside this server only:", err)
		live = false
	end
end

local function status(p: Player, state: string, info: { [string]: any }?)
	if p.Parent then
		statusEvent:FireClient(p, state, info or {})
	end
end

-- which of a / b plays Kai: true = a, false = b, nil = they don't fit yet
local function kaiIsA(a: Entry, b: Entry, now: number): boolean?
	local aKai = a.role == "Kai" or b.role == "Miko"
	local aMiko = a.role == "Miko" or b.role == "Kai"
	if aKai and aMiko then -- both want the same character
		if now - a.since < T.RoleFallback or now - b.since < T.RoleFallback then
			return nil
		end
		return math.random() < 0.5
	end
	if aKai or aMiko then
		return aKai
	end
	return math.random() < 0.5
end

local function stop(p: Player)
	searching[p] = nil
	if live and queue then
		local q = queue :: MemoryStoreSortedMap
		task.spawn(pcall, q.RemoveAsync, q, tostring(p.UserId))
	end
end

-- atomically set / clear a claim; true if this server now holds it
local function claim(key: string, claimId: string?): boolean
	local q = queue :: MemoryStoreSortedMap
	local won = false
	local ok = pcall(function()
		q:UpdateAsync(key, function(old: Entry?, sortKey)
			if not old or old.match then
				return nil
			end
			if claimId then
				if old.claim then
					return nil
				end
				old.claim = { by = claimId, at = os.time() }
			else
				old.claim = nil
			end
			won = true
			return old, sortKey
		end, T.EntryTtl)
	end)
	return ok and won
end

local function writeMatch(key: string, match: { code: string, partner: string, role: string }): boolean
	local q = queue :: MemoryStoreSortedMap
	local done = false
	local ok = pcall(function()
		q:UpdateAsync(key, function(old: Entry?, sortKey)
			if not old then
				return nil
			end
			old.match = match
			done = true
			return old, sortKey
		end, T.EntryTtl)
	end)
	return ok and done
end

local function sendSelf(p: Player, code: string, partner: string, role: string)
	searching[p] = nil
	status(p, "Found", { partner = partner, role = role })
	local ok, err = pcall(DuoTeleport.Go, { p }, code)
	if not ok then
		warn("[Matchmaking] teleport failed:", err)
		status(p, "Failed")
	end
end

local function byUserId(key: string): Player?
	return Players:GetPlayerByUserId(tonumber(key) or 0)
end

-- Studio / unpublished: pair the two oldest fitting searchers of this server, no teleport
local function localTick()
	local now = os.time()
	local list = {}
	for p, s in searching do
		table.insert(list, { p = p, e = { job = "", role = s.role, since = s.since, name = p.DisplayName } :: Entry })
	end
	table.sort(list, function(x, y)
		return x.e.since < y.e.since
	end)
	for i, a in list do
		for j = i + 1, #list do
			local b = list[j]
			if searching[a.p] and searching[b.p] then
				local aKai = kaiIsA(a.e, b.e, now)
				if aKai ~= nil then
					searching[a.p], searching[b.p] = nil, nil
					status(a.p, "Found", { partner = b.p.DisplayName, role = if aKai then "Kai" else "Miko" })
					status(b.p, "Found", { partner = a.p.DisplayName, role = if aKai then "Miko" else "Kai" })
					print(`[Matchmaking] {a.p.Name} + {b.p.Name} matched. Teleport skipped (Studio / unpublished).`)
					task.delay(3, function()
						status(a.p, "Studio")
						status(b.p, "Studio")
					end)
				end
			end
		end
	end
end

local function liveTick()
	local q = queue :: MemoryStoreSortedMap
	local now = os.time()

	-- keep our own entries alive (a crashed server's entries expire on their own)
	for p, s in searching do
		if now - s.refreshed >= T.Refresh then
			s.refreshed = now
			pcall(function()
				q:UpdateAsync(tostring(p.UserId), function(old: Entry?)
					local e: Entry = old or { job = game.JobId, role = s.role, since = s.since, name = p.DisplayName }
					e.role = s.role
					return e, s.since
				end, T.EntryTtl)
			end)
		end
	end

	local ok, items = pcall(q.GetRangeAsync, q, Enum.SortDirection.Ascending, 100)
	if not ok then
		return
	end
	local entries: { { key: string, value: Entry } } = {}
	for _, item in items do
		table.insert(entries, { key = item.key, value = item.value })
	end

	-- 1. our players someone else matched: go; stale claims (their starter died): free them
	for _, it in entries do
		local p = byUserId(it.key)
		if p and searching[p] and it.value.job == game.JobId then
			local m = it.value.match
			if m then
				task.spawn(pcall, q.RemoveAsync, q, it.key)
				sendSelf(p, m.code, m.partner, m.role)
			elseif it.value.claim and now - it.value.claim.at > T.ClaimTimeout then
				claim(it.key, nil)
			end
		end
	end

	-- 2. start matches for our searchers, oldest first, with a newer free entry that fits
	for i, mine in entries do
		local me = byUserId(mine.key)
		if me and searching[me] and mine.value.job == game.JobId and not mine.value.claim and not mine.value.match then
			for j = i + 1, #entries do
				local other = entries[j]
				local them = other.value
				if not them.claim and not them.match and searching[me] then
					local aKai = kaiIsA(mine.value, them, now)
					if aKai ~= nil then
						local claimId = HttpService:GenerateGUID(false)
						if claim(mine.key, claimId) then
							if claim(other.key, claimId) then
								them.claim = { by = claimId, at = now } -- don't offer it to our next searcher
								local kaiId = tonumber(if aKai then mine.key else other.key) :: number
								local mikoId = tonumber(if aKai then other.key else mine.key) :: number
								local reserved, code = pcall(DuoTeleport.Reserve, kaiId, mikoId)
								if reserved then
									local myRole = if aKai then "Kai" else "Miko"
									local theirRole = if aKai then "Miko" else "Kai"
									local partner = byUserId(other.key)
									if partner and searching[partner] and them.job == game.JobId then
										-- both in this server: one teleport for the pair
										searching[me], searching[partner] = nil, nil
										task.spawn(pcall, q.RemoveAsync, q, mine.key)
										task.spawn(pcall, q.RemoveAsync, q, other.key)
										status(me, "Found", { partner = partner.DisplayName, role = myRole })
										status(partner, "Found", { partner = me.DisplayName, role = theirRole })
										local sent, err = pcall(DuoTeleport.Go, { me, partner }, code)
										if not sent then
											warn("[Matchmaking] teleport failed:", err)
											status(me, "Failed")
											status(partner, "Failed")
										end
									elseif
										writeMatch(
											other.key,
											{ code = code, partner = me.DisplayName, role = theirRole }
										)
									then
										task.spawn(pcall, q.RemoveAsync, q, mine.key)
										sendSelf(me, code, them.name, myRole)
									else
										claim(mine.key, nil) -- their entry vanished: keep searching
									end
								else
									warn("[Matchmaking] reserve failed:", code)
									claim(mine.key, nil)
									claim(other.key, nil)
								end
								break
							else
								claim(mine.key, nil) -- someone else got them first
							end
						end
					end
				end
			end
		end
	end
end

findEvent.OnServerEvent:Connect(function(p: Player, wish: unknown)
	local role: Wish = if type(wish) == "string" and WISHES[wish] then wish :: Wish else "Any"
	local s = searching[p]
	if s then
		s.role = role
		s.refreshed = 0 -- rewrite the entry with the new wish on the next tick
	else
		searching[p] = { role = role, since = os.time(), refreshed = 0 }
	end
	status(p, "Searching", { since = searching[p].since, role = role, live = live })
end)

cancelEvent.OnServerEvent:Connect(function(p: Player)
	if searching[p] then
		stop(p)
	end
	status(p, "Off")
end)

-- a teleport that fails after it started (only matters to a player this script told "Found"; the card ignores it otherwise)
game:GetService("TeleportService").TeleportInitFailed:Connect(function(p: Player)
	status(p, "Failed")
end)

Players.PlayerRemoving:Connect(function(p: Player)
	if searching[p] then
		stop(p)
	end
end)

task.spawn(function()
	while true do
		task.wait(T.Poll)
		if next(searching) then
			if live then
				liveTick()
			else
				localTick()
			end
		end
	end
end)
