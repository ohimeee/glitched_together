-- Duo save (implementation.md §10). UpdateAsync with retries; saves on checkpoint, world complete and shutdown.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunIndex = require(ReplicatedStorage.Shared.Util.RunIndex)

local SaveService = {}

export type Save = {
	world: string,
	checkpoint: number,
	unlocked: { string },
	complete: boolean?,
	version: number,
}

local VERSION = 1
local RETRIES = 3

local key: string? = nil
local current: Save = { world = "Prologue", checkpoint = 0, unlocked = { "Prologue" }, version = VERSION }
local dirty = false
local ids: { kai: number, miko: number }? = nil
local names: { [number]: string } = {} -- display names, kept after a player leaves (the index still needs them)
local indexed = "" -- world/checkpoint last written to the players' run lists
local overwrite = false -- NEW GAME over an old save: the next write replaces it whatever it held

local function duoKey(a: number, b: number): string
	return `duo_{math.min(a, b)}_{math.max(a, b)}`
end

local function store(): DataStore?
	local ok, ds = pcall(DataStoreService.GetDataStore, DataStoreService, "DuoSaves")
	return if ok then ds else nil
end

local function withRetry(fn: () -> any): (boolean, any)
	local ok, result
	for attempt = 1, RETRIES do
		ok, result = pcall(fn)
		if ok then
			return true, result
		end
		task.wait(attempt)
	end
	warn("[SaveService]", result)
	return false, result
end

-- Loads the duo's save. Studio test players have ids <= 0, so they run without saving. `fresh` (NEW GAME chosen by
-- both in the lobby) skips the old save and replaces it on the first flush.
function SaveService.Load(kaiId: number?, mikoId: number?, fresh: boolean?): Save
	if not (kaiId and mikoId and kaiId > 0 and mikoId > 0) then
		return current
	end
	key = duoKey(kaiId, mikoId)
	ids = { kai = kaiId, miko = mikoId }
	if fresh then
		overwrite = true
		dirty = true
		return current
	end
	local ds = store()
	if not ds then
		return current
	end
	local ok, data = withRetry(function()
		return ds:GetAsync(key :: string)
	end)
	if ok and type(data) == "table" then
		current = data
	end
	return current
end

function SaveService.Get(): Save
	return current
end

function SaveService.Set(patch: { [string]: any })
	for k, v in patch do
		(current :: any)[k] = v
	end
	dirty = true
end

function SaveService.Unlock(world: string)
	if not table.find(current.unlocked, world) then
		table.insert(current.unlocked, world)
		dirty = true
	end
end

function SaveService.Flush()
	if not (key and dirty) then
		return
	end
	local ds = store()
	if not ds then
		return
	end
	local snapshot = table.clone(current)
	local ok = withRetry(function()
		return ds:UpdateAsync(key :: string, function(old)
			-- Never move a save backwards if another server wrote a later checkpoint in the same world.
			if
				not overwrite
				and type(old) == "table"
				and old.world == snapshot.world
				and (old.checkpoint or 0) > snapshot.checkpoint
			then
				return nil
			end
			return snapshot
		end)
	end)
	if ok then
		dirty = false
		overwrite = false
		SaveService.Index(snapshot)
	end
end

local function nameOf(id: number): string
	local p = Players:GetPlayerByUserId(id)
	if p then
		names[id] = p.DisplayName
	end
	return names[id] or "Partner"
end

-- Each player's saved-runs list (Lobby "Continue with <partner>"): one entry per partner, written only when the
-- world, checkpoint or finish changed.
function SaveService.Index(snapshot: Save)
	local pair = ids
	if not pair then
		return
	end
	local stamp = `{snapshot.world}/{snapshot.checkpoint}/{snapshot.complete}`
	if stamp == indexed then
		return
	end
	indexed = stamp
	local now = os.time()
	for _, side in { { pair.kai, pair.miko, "Kai" }, { pair.miko, pair.kai, "Miko" } } do
		local me, partner, role = side[1] :: number, side[2] :: number, side[3] :: string
		task.spawn(RunIndex.Put, me, {
			partner = partner,
			name = nameOf(partner),
			role = role,
			world = snapshot.world,
			checkpoint = snapshot.checkpoint,
			complete = snapshot.complete,
			t = now,
		})
	end
end

function SaveService.Init()
	for _, p in Players:GetPlayers() do
		names[p.UserId] = p.DisplayName
	end
	Players.PlayerAdded:Connect(function(p)
		names[p.UserId] = p.DisplayName
	end)
	game:BindToClose(SaveService.Flush)
end

return SaveService
