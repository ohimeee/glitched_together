-- Key names per input device (mobile + console pass, LAUNCH.md §3): every key prompt, Pip hint, sign and tool card
-- names the key of the device you're playing on. On the server it always answers the keyboard names (sign defaults).
--   Glyphs.device()          "Keyboard" | "Gamepad" | "Touch" (follows the last input used)
--   Glyphs.key("Dash")       "SHIFT" / "B" / "DASH"
--   Glyphs.format(text)      replaces {Action} tokens: "{Jump} to jump" -> "SPACE to jump" / "A to jump" / "JUMP to jump"
--   Glyphs.Changed           fires (device) when the device changes
-- Touch names are the on-screen button labels (TouchController); DASH is renamed per kit (BLINK, CHARGE: SetTouch).
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Keys = require(ReplicatedStorage.Shared.Config.Keys)
local isClient = game:GetService("RunService"):IsClient()
local Settings = if isClient then require(ReplicatedStorage.Shared.Util.Settings) else nil

local Glyphs = {}

export type Device = "Keyboard" | "Gamepad" | "Touch"

-- { keyboard, gamepad, touch }; gamepad bindings live in client/Input.luau
local KEYS: { [string]: { string } } = {
	Jump = { "SPACE", "A", "JUMP" },
	Dash = { "SHIFT", "B", "DASH" },
	GroundPound = { "CTRL", "R3", "POUND" },
	Swing = { "F", "RB", "GRAB" },
	Sprint = { "C", "L3", "RUN" },
	Ping = { "Q", "D-PAD UP", "PING" },
	Peek = { "TAB", "D-PAD DOWN", "PEEK" },
	Tool1 = { "LMB", "RT", "TOOL 1" },
	Tool2 = { "RMB", "LT", "TOOL 2" },
	Ultimate = { "LMB + RMB", "RT + LT", "ULT" },
	Ignite = { "E", "Y", "IGNITE" },
	Rotate = { "R", "Y", "ROTATE" },
	Skip = { "SPACE", "A", "SKIP" },
	Mash = { "SPACE", "A", "TAP" },
	Interact = { "E", "X", "TAP" },
	Throttle = { "W / S", "L STICK", "STICK" },
	Aim = { "MOUSE", "R STICK", "AUTO-AIM" },
}

local touchNames: { [string]: string? } = {}

local changed = Instance.new("BindableEvent")
Glyphs.Changed = changed.Event

local function fromInput(kind: Enum.UserInputType): Device?
	if kind == Enum.UserInputType.Touch then
		return "Touch"
	elseif kind.Name:find("Gamepad") then
		return "Gamepad"
	elseif
		kind == Enum.UserInputType.Keyboard
		or kind == Enum.UserInputType.MouseButton1
		or kind == Enum.UserInputType.MouseButton2
		or kind == Enum.UserInputType.MouseWheel
	then
		return "Keyboard"
	end
	return nil -- MouseMovement, Focus, TextInput: no switch (a resting mouse shouldn't flip a gamepad player back)
end

local current: Device = "Keyboard"
if game:GetService("RunService"):IsServer() then
	current = "Keyboard"
elseif GuiService:IsTenFootInterface() then
	current = "Gamepad"
elseif UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	current = "Touch"
else
	current = fromInput(UserInputService:GetLastInputType()) or "Keyboard"
end

-- Studio only: workspace `DebugDevice` = "Touch" / "Gamepad" / "Keyboard" pins the device (UI checks without a phone)
local function debugDevice(): Device?
	local RunService = game:GetService("RunService")
	local d = RunService:IsStudio() and workspace:GetAttribute("DebugDevice")
	return if d == "Touch" or d == "Gamepad" or d == "Keyboard" then d else nil
end

if game:GetService("RunService"):IsClient() then
	current = debugDevice() or current
	workspace:GetAttributeChangedSignal("DebugDevice"):Connect(function()
		local d = debugDevice()
		if d and d ~= current then
			current = d
			changed:Fire(d)
		end
	end)
	if Settings then
		Settings.Changed:Connect(function(key)
			if key == "KeyBinds" and current == "Keyboard" then
				changed:Fire(current) -- every key text re-formats with the new key
			end
		end)
	end
	UserInputService.LastInputTypeChanged:Connect(function(kind)
		local d = fromInput(kind)
		if debugDevice() then
			return
		end
		if d and d ~= current then
			current = d
			changed:Fire(d)
		end
	end)
end

function Glyphs.device(): Device
	return current
end

function Glyphs.key(action: string): string
	local keys = KEYS[action]
	if not keys then
		return string.upper(action)
	end
	if current == "Gamepad" then
		return keys[2]
	elseif current == "Touch" then
		return touchNames[action] or keys[3]
	end
	-- a key the player rebound in the settings menu (Config/Keys)
	local binds = Settings and Settings.Get("KeyBinds")
	local bound = binds and binds[action]
	if type(bound) == "string" and Keys.Default(action) then
		local code = Keys.For(action, binds)
		return if code then Keys.Name(code.Name) else keys[1]
	end
	return keys[1]
end

function Glyphs.format(text: string): string
	return (
		text:gsub("{(%w+)}", function(name)
			return if KEYS[name] then Glyphs.key(name) else `\{{name}\}` -- unknown token: left as it was
		end)
	)
end

-- The touch label of an action's on-screen button (the tool buttons say what the kit does: FREEZE, GRAPPLE...).
function Glyphs.SetTouch(action: string, label: string?)
	if touchNames[action] ~= label then
		touchNames[action] = label
		if current == "Touch" then
			changed:Fire(current)
		end
	end
end

return Glyphs
