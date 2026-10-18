-- Keyboard keys the player can rebind in the settings menu (Settings.KeyBinds = { [action] = KeyCode name }).
-- Gamepad buttons and touch buttons stay fixed; Jump stays Roblox's (Space). client/Input.luau applies the binds,
-- Util/Glyphs names them, the lobby's LobbyMoves reads Dash.
local Keys = {}

export type Bind = { action: string, label: string, default: string }

Keys.Rebindable = {
	{ action = "Dash", label = "Dash", default = "LeftShift" },
	{ action = "GroundPound", label = "Ground pound / crouch", default = "LeftControl" },
	{ action = "Swing", label = "Swing / grind / grab", default = "F" },
	{ action = "Sprint", label = "Sprint", default = "C" },
	{ action = "Ping", label = "Ping", default = "Q" },
	{ action = "Peek", label = "Partner peek", default = "Tab" },
	{ action = "Ignite", label = "Ignite (castle)", default = "E" },
	{ action = "Rotate", label = "Rotate paste (core)", default = "R" },
} :: { Bind }

-- keys a bind may not take: movement, jump, menus, chat and Roblox's own shortcuts
Keys.Reserved = {
	W = true,
	A = true,
	S = true,
	D = true,
	Up = true,
	Down = true,
	Left = true,
	Right = true,
	Space = true,
	Escape = true,
	Slash = true,
	Backquote = true,
	F9 = true,
	F11 = true,
	F12 = true,
	Unknown = true,
}

local NAMES: { [string]: string } = {
	LeftShift = "SHIFT",
	RightShift = "R-SHIFT",
	LeftControl = "CTRL",
	RightControl = "R-CTRL",
	LeftAlt = "ALT",
	RightAlt = "R-ALT",
	Tab = "TAB",
	Return = "ENTER",
	CapsLock = "CAPS",
	Backspace = "BACKSPACE",
	One = "1",
	Two = "2",
	Three = "3",
	Four = "4",
	Five = "5",
	Six = "6",
	Seven = "7",
	Eight = "8",
	Nine = "9",
	Zero = "0",
}

function Keys.Default(action: string): string?
	for _, b in Keys.Rebindable do
		if b.action == action then
			return b.default
		end
	end
	return nil
end

-- The key name a player sees ("LeftShift" -> "SHIFT")
function Keys.Name(keyCode: string): string
	return NAMES[keyCode] or string.upper(keyCode)
end

-- The KeyCode an action uses for this binds table (a bad or reserved name falls back to the default)
function Keys.For(action: string, binds: { [string]: any }?): Enum.KeyCode?
	local default = Keys.Default(action)
	if not default then
		return nil
	end
	local name = binds and binds[action]
	if type(name) == "string" and not Keys.Reserved[name] then
		local ok, code = pcall(function()
			return (Enum.KeyCode :: any)[name]
		end)
		if ok and code then
			return code
		end
	end
	return (Enum.KeyCode :: any)[default]
end

return Keys
