-- Duo save (implementation.md §10). UpdateAsync with retries; saves on checkpoint, world complete and shutdown.
local DataStoreService = game:GetService("DataStoreService")

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

-- Loads the duo's save. Studio test players have ids <= 0, so they run without saving.
function SaveService.Load(kaiId: number?, mikoId: number?): Save
	if not (kaiId and mikoId and kaiId > 0 and mikoId > 0) then
		return current
	end
	key = duoKey(kaiId, mikoId)
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
			if type(old) == "table" and old.world == snapshot.world and (old.checkpoint or 0) > snapshot.checkpoint then
				return nil
			end
			return snapshot
		end)
	end)
	if ok then
		dirty = false
	end
end

function SaveService.Init()
	game:BindToClose(SaveService.Flush)
end

return SaveService
