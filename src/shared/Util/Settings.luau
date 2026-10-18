-- Per-player settings (both places): one table per player, saved in DataStore "PlayerSettings" (key `s_<userId>`) so
-- it follows the player across the Lobby, the Adventure and every device.
--   Server: Settings.InitServer()             loads on join, sends it down, saves on change (throttled) + on leave
--   Client: Settings.Get(key)                 current value (defaults until the server's copy arrives)
--           Settings.Set(key, value)          changes it here at once, saves through the server
--           Settings.Changed                  fires (key, value); a load fires it for every key
--           Settings.Reset(keys?)             back to the defaults (all, or the listed keys)
-- Menu: shared/Util/SettingsMenu. Keys are only what the menu offers; the server clamps and drops anything else.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = require(ReplicatedStorage.Shared.Net)

local Settings = {}

type Spec = { default: any, min: number?, max: number?, options: { string }? }

-- number = clamped slider, boolean = toggle, options = one of, table = free map (validated by its owner)
local SPECS: { [string]: Spec } = {
	-- Audio (× the SoundGroup's own volume)
	MusicVolume = { default = 1, min = 0, max = 1 },
	SfxVolume = { default = 1, min = 0, max = 1 },
	AmbienceVolume = { default = 1, min = 0, max = 1 },
	UiVolume = { default = 1, min = 0, max = 1 },
	-- Camera (× Tuning.Camera sensitivities)
	MouseSensitivity = { default = 1, min = 0.2, max = 3 },
	GamepadSensitivity = { default = 1, min = 0.2, max = 3 },
	TouchSensitivity = { default = 1, min = 0.2, max = 3 },
	InvertY = { default = false },
	FovOffset = { default = 0, min = -14, max = 20 }, -- degrees on top of Tuning.Camera.FOV
	-- Controls
	SprintMode = { default = "Toggle", options = { "Toggle", "Hold" } },
	AutoAim = { default = 1, min = 0, max = 1.5 }, -- × aim assist cones / range (0 = off)
	KeyBinds = { default = {} }, -- { [action] = KeyCode name } keyboard only (client/Input.luau validates)
	-- Co-op
	PartnerOutline = { default = "Always", options = { "Always", "Hidden", "Off" } }, -- Hidden = only behind walls
	PingSize = { default = 1, min = 0.6, max = 1.8 },
	-- Accessibility
	ColorblindIcons = { default = false }, -- shape icons on owner-colored targets (orange ▲, teal ●, magenta ✕)
	TextScale = { default = 1, min = 0.8, max = 1.4 }, -- × UiFit
	TextSpeed = { default = 1, min = 0.5, max = 4 }, -- × typewriter speed (4 = near instant)
	PipHints = { default = true },
	-- Touch layout editor (TouchController): { [button] = { x, y, s } } x/y = screen fractions, s = size ×
	TouchLayout = { default = {} },
	TouchOpacity = { default = 1, min = 0.3, max = 1.6 }, -- × how solid the buttons are (fill/ring)
}
Settings.Specs = SPECS

local MAX_BYTES = 6000 -- a settings table never needs more (DataStore keys allow 4 MB; this stops abuse)
local SAVE_EVERY = 20 -- s between DataStore writes of a changed table

local function copy(v: any): any
	if type(v) ~= "table" then
		return v
	end
	local t = {}
	for k, x in v do
		t[k] = copy(x)
	end
	return t
end

-- nil = not allowed; otherwise the value to keep
local function clean(key: string, value: any): any
	local spec = SPECS[key]
	if not spec then
		return nil
	end
	local d = spec.default
	if spec.options then
		return if type(value) == "string" and table.find(spec.options, value) then value else nil
	elseif type(d) == "number" then
		if type(value) ~= "number" or value ~= value then
			return nil
		end
		return math.clamp(value, spec.min or -math.huge, spec.max or math.huge)
	elseif type(d) == "boolean" then
		return if type(value) == "boolean" then value else nil
	elseif type(d) == "table" then
		return if type(value) == "table" then value else nil
	end
	return nil
end

local function cleanAll(data: any): { [string]: any }
	local out = {}
	if type(data) == "table" then
		for key, value in data do
			if type(key) == "string" then
				local v = clean(key, value)
				if v ~= nil then
					out[key] = v
				end
			end
		end
	end
	return out
end

-- Server --------------------------------------------------------------------------------------------------------

function Settings.InitServer()
	local HttpService = game:GetService("HttpService")
	local DataStoreService = game:GetService("DataStoreService")
	local loadEvent = Net.event("SettingsLoad")
	local saveEvent = Net.event("SettingsSave")
	local okStore, ds = pcall(DataStoreService.GetDataStore, DataStoreService, "PlayerSettings")
	local store: DataStore? = if okStore then ds else nil

	local data: { [Player]: { [string]: any } } = {}
	local dirty: { [Player]: boolean } = {}
	local lastSave: { [Player]: number } = {}

	local function write(p: Player)
		local t = data[p]
		if not (store and t and dirty[p]) or p.UserId <= 0 then
			return
		end
		dirty[p] = nil
		lastSave[p] = os.clock()
		local ok, err = pcall(function()
			(store :: DataStore):SetAsync(`s_{p.UserId}`, t)
		end)
		if not ok then
			dirty[p] = true
			warn("[Settings] save failed:", err)
		end
	end

	local function load(p: Player)
		local t = {}
		if store and p.UserId > 0 then
			local ok, got = pcall(function()
				return (store :: DataStore):GetAsync(`s_{p.UserId}`)
			end)
			if ok then
				t = cleanAll(got)
			end
		end
		if p.Parent then
			data[p] = t
			loadEvent:FireClient(p, t)
		end
	end

	saveEvent.OnServerEvent:Connect(function(p, incoming)
		local t = data[p]
		if not t or type(incoming) ~= "table" then
			return
		end
		local ok, encoded = pcall(HttpService.JSONEncode, HttpService, incoming)
		if not ok or #encoded > MAX_BYTES then
			return
		end
		for key, value in incoming do
			if type(key) == "string" and SPECS[key] then
				local v = clean(key, value)
				if v ~= nil then
					t[key] = v
					dirty[p] = true
				end
			end
		end
	end)

	Players.PlayerAdded:Connect(load)
	for _, p in Players:GetPlayers() do
		task.spawn(load, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		write(p)
		data[p], dirty[p], lastSave[p] = nil, nil, nil
	end)
	task.spawn(function()
		while true do
			task.wait(5)
			for p in dirty do
				if os.clock() - (lastSave[p] or 0) >= SAVE_EVERY then
					task.spawn(write, p)
				end
			end
		end
	end)
	game:BindToClose(function()
		for p in data do
			task.spawn(write, p)
		end
		task.wait(2)
	end)
end

-- Client --------------------------------------------------------------------------------------------------------

local values: { [string]: any } = {}
local changed = Instance.new("BindableEvent")
Settings.Changed = changed.Event
Settings.Loaded = false
local loadedEvent = Instance.new("BindableEvent")
Settings.LoadedSignal = loadedEvent.Event

function Settings.Get(key: string): any
	local v = values[key]
	if v == nil then
		local spec = SPECS[key]
		return if spec then copy(spec.default) else nil
	end
	return copy(v)
end

local pending: { [string]: any } = {}
local flushQueued = false

local function queueSave(key: string, value: any)
	pending[key] = if value == nil then copy(SPECS[key].default) else value
	if flushQueued then
		return
	end
	flushQueued = true
	task.delay(0.5, function() -- sliders fire many changes: one message per half second
		flushQueued = false
		local batch = pending
		pending = {}
		Net.event("SettingsSave"):FireServer(batch)
	end)
end

function Settings.Set(key: string, value: any)
	local v = clean(key, value)
	if v == nil then
		return
	end
	values[key] = copy(v)
	changed:Fire(key, copy(v))
	queueSave(key, copy(v))
end

function Settings.Reset(keys: { string }?)
	local list = keys
	if not list then
		list = {}
		for key in SPECS do
			table.insert(list, key)
		end
	end
	for _, key in list :: { string } do
		if SPECS[key] then
			values[key] = nil
			changed:Fire(key, Settings.Get(key))
			queueSave(key, nil)
		end
	end
end

if RunService:IsClient() then
	task.spawn(function()
		Net.event("SettingsLoad").OnClientEvent:Connect(function(t)
			values = cleanAll(t)
			Settings.Loaded = true
			for key in SPECS do
				changed:Fire(key, Settings.Get(key))
			end
			loadedEvent:Fire()
		end)
	end)
end

return Settings
