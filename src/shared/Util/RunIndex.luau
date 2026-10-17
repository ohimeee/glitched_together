-- Saved runs per player (server only, both places): DataStore "PlayerRuns", key `runs_<userId>`, one entry per
-- partner. The Adventure writes it next to the duo save (SaveService.Flush); the Lobby reads it for the
-- "Continue with <partner>" list. The duo save itself stays in "DuoSaves" (key duo_<min>_<max>).
local DataStoreService = game:GetService("DataStoreService")

export type Entry = {
	partner: number, -- the partner's user id
	name: string, -- the partner's display name when last saved
	role: string, -- this player's role in that run ("Kai" / "Miko")
	world: string,
	checkpoint: number,
	complete: boolean?,
	t: number, -- os.time() of the last save
}

local RunIndex = {}

RunIndex.Max = 12 -- partners kept per player (oldest dropped)

local function store(): DataStore?
	local ok, ds = pcall(DataStoreService.GetDataStore, DataStoreService, "PlayerRuns")
	return if ok then ds else nil
end

-- Newest first. Studio test ids (<= 0) and DataStore errors give an empty list.
function RunIndex.Get(userId: number): { Entry }
	local ds = store()
	if userId <= 0 or not ds then
		return {}
	end
	local ok, data = pcall(function()
		return (ds :: DataStore):GetAsync(`runs_{userId}`)
	end)
	local list: { Entry } = {}
	if ok and type(data) == "table" then
		for _, e in data do
			if type(e) == "table" and type(e.partner) == "number" then
				table.insert(list, e)
			end
		end
	end
	table.sort(list, function(a, b)
		return (a.t or 0) > (b.t or 0)
	end)
	return list
end

-- Writes (or refreshes) this player's entry for one partner.
function RunIndex.Put(userId: number, entry: Entry)
	local ds = store()
	if userId <= 0 or entry.partner <= 0 or not ds then
		return
	end
	pcall(function()
		(ds :: DataStore):UpdateAsync(`runs_{userId}`, function(old)
			local map = if type(old) == "table" then old else {}
			map[tostring(entry.partner)] = entry
			local keys = {}
			for k in map do
				table.insert(keys, k)
			end
			if #keys > RunIndex.Max then
				table.sort(keys, function(a, b)
					return (map[a].t or 0) > (map[b].t or 0)
				end)
				for i = RunIndex.Max + 1, #keys do
					map[keys[i]] = nil
				end
			end
			return map
		end)
	end)
end

-- The duo save of a pair (Lobby: "CONTINUE: <world>" on the capsule screen). nil = no save yet / not readable.
function RunIndex.DuoSave(a: number, b: number): { [string]: any }?
	if a <= 0 or b <= 0 then
		return nil
	end
	local ok, ds = pcall(DataStoreService.GetDataStore, DataStoreService, "DuoSaves")
	if not ok then
		return nil
	end
	local got, data = pcall(function()
		return ds:GetAsync(`duo_{math.min(a, b)}_{math.max(a, b)}`)
	end)
	return if got and type(data) == "table" then data else nil
end

return RunIndex
