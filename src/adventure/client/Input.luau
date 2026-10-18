-- Input layer built on Roblox's Input Action System (InputContext > InputAction > InputBinding).
-- If that API is unavailable it falls back to UserInputService with the same interface, so
-- controllers only ever see: Input.action(context, name).Pressed / .Released / :IsDown().
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Keys = require(ReplicatedStorage.Shared.Config.Keys)
local Settings = require(ReplicatedStorage.Shared.Util.Settings)

type Binding = Enum.KeyCode
type ActionSpec = { name: string, keys: { Binding } }
type ContextSpec = { name: string, priority: number, sink: boolean, enabled: boolean, actions: { ActionSpec } }

export type Action = {
	Pressed: RBXScriptSignal,
	Released: RBXScriptSignal,
	IsDown: (self: Action) -> boolean,
}

local K = Enum.KeyCode

local SPECS: { ContextSpec } = {
	{
		name = "BaseContext",
		priority = 0,
		sink = false,
		enabled = true,
		actions = {
			{ name = "Dash", keys = { K.LeftShift, K.ButtonB } },
			{ name = "GroundPound", keys = { K.LeftControl, K.ButtonR3 } },
			{ name = "Swing", keys = { K.F, K.ButtonR1 } },
			{ name = "Sprint", keys = { K.C, K.ButtonL3 } },
			{ name = "Ping", keys = { K.Q, K.DPadUp } },
			{ name = "Peek", keys = { K.Tab, K.DPadDown } },
			{ name = "Mash", keys = { K.Space, K.ButtonA } },
		},
	},
	{
		name = "W1Tools",
		priority = 1,
		sink = false,
		enabled = false,
		actions = {
			{ name = "Tool1", keys = { K.MouseLeftButton, K.ButtonR2 } },
			{ name = "Tool2", keys = { K.MouseRightButton, K.ButtonL2 } },
		},
	},
	{
		name = "CastleTools",
		priority = 1,
		sink = false,
		enabled = false,
		actions = {
			{ name = "Tool1", keys = { K.MouseLeftButton, K.ButtonR2 } },
			{ name = "Tool2", keys = { K.MouseRightButton, K.ButtonL2 } },
			-- Y, not X: X is every ProximityPrompt's gamepad key (both fired at a lever near a brazier)
			{ name = "Ignite", keys = { K.E, K.ButtonY } },
			-- touch only (the ULT button): keyboard / gamepad hold both tool buttons instead
			{ name = "Ultimate", keys = {} },
		},
	},
	{
		name = "W3Tools",
		priority = 1,
		sink = false,
		enabled = false,
		actions = {
			{ name = "Tool1", keys = { K.MouseLeftButton, K.ButtonR2 } },
			{ name = "Tool2", keys = { K.MouseRightButton, K.ButtonL2 } },
			{ name = "Rotate", keys = { K.R, K.ButtonY } },
		},
	},
	{
		-- Cutscenes and the level-up picker: sinks every gameplay input below it.
		name = "MenuContext",
		priority = 100,
		sink = true,
		enabled = false,
		actions = {
			{ name = "Skip", keys = { K.Space, K.ButtonA } },
		},
	},
}

local Input = {}
Input.UsingActionSystem = false

local actions: { [string]: { [string]: Action } } = {}
local contextEnabled: { [string]: boolean } = {}
local contextInstances: { [string]: Instance } = {}
-- the keyboard binding of each action (the first key in its spec), so the settings menu can rebind it
local keyboardBinding: { [string]: { [string]: any } } = {}

local function isKeyboard(key: Binding): boolean
	return not key.Name:find("^Button") and not key.Name:find("^DPad") and not key.Name:find("^Thumbstick")
end

-- Input Action System path --------------------------------------------------------------

local function buildActionSystem(): boolean
	local ok, err = pcall(function()
		local folder = Instance.new("Folder")
		folder.Name = "InputContexts"

		for _, spec in SPECS do
			local ctx = Instance.new("InputContext") :: any
			ctx.Name = spec.name
			ctx.Priority = spec.priority
			ctx.Sink = spec.sink
			ctx.Enabled = spec.enabled
			ctx.Parent = folder
			contextInstances[spec.name] = ctx
			contextEnabled[spec.name] = spec.enabled
			actions[spec.name] = {}

			for _, a in spec.actions do
				local act = Instance.new("InputAction") :: any
				act.Name = a.name
				act.Type = (Enum :: any).InputActionType.Bool
				act.Parent = ctx
				for _, key in a.keys do
					local b = Instance.new("InputBinding") :: any
					b.KeyCode = key
					b.Parent = act
					if isKeyboard(key) and not (keyboardBinding[spec.name] and keyboardBinding[spec.name][a.name]) then
						keyboardBinding[spec.name] = keyboardBinding[spec.name] or {}
						keyboardBinding[spec.name][a.name] = b
					end
				end
				actions[spec.name][a.name] = {
					Pressed = act.Pressed,
					Released = act.Released,
					IsDown = function()
						return act:GetState() == true
					end,
				} :: any
			end
		end
		folder.Parent = ReplicatedStorage -- created on this client only
	end)
	if not ok then
		warn("[Input] Input Action System unavailable, using fallback:", err)
		table.clear(actions)
		table.clear(contextInstances)
		table.clear(keyboardBinding)
	end
	return ok
end

-- Fallback path ------------------------------------------------------------------------

local MOUSE_KEYS = {
	[Enum.UserInputType.MouseButton1] = K.MouseLeftButton,
	[Enum.UserInputType.MouseButton2] = K.MouseRightButton,
}

type FallbackAction = { pressed: BindableEvent, released: BindableEvent, down: boolean, keys: { [Binding]: boolean } }
local fallback: { [string]: { [string]: FallbackAction } } = {}

local function topSinkActive(priority: number): boolean
	for _, spec in SPECS do
		if spec.sink and contextEnabled[spec.name] and spec.priority > priority then
			return true
		end
	end
	return false
end

local function buildFallback()
	for _, spec in SPECS do
		contextEnabled[spec.name] = spec.enabled
		actions[spec.name] = {}
		fallback[spec.name] = {}
		for _, a in spec.actions do
			local fa: FallbackAction = {
				pressed = Instance.new("BindableEvent"),
				released = Instance.new("BindableEvent"),
				down = false,
				keys = {},
			}
			for _, key in a.keys do
				fa.keys[key] = true
				if isKeyboard(key) and not (keyboardBinding[spec.name] and keyboardBinding[spec.name][a.name]) then
					keyboardBinding[spec.name] = keyboardBinding[spec.name] or {}
					keyboardBinding[spec.name][a.name] = { fallback = fa, key = key }
				end
			end
			fallback[spec.name][a.name] = fa
			actions[spec.name][a.name] = {
				Pressed = fa.pressed.Event,
				Released = fa.released.Event,
				IsDown = function()
					return fa.down
				end,
			} :: any
		end
	end

	local function route(input: InputObject, isDown: boolean, processed: boolean)
		local key = MOUSE_KEYS[input.UserInputType] or input.KeyCode
		for _, spec in SPECS do
			if contextEnabled[spec.name] and not topSinkActive(spec.priority) then
				for _, fa in fallback[spec.name] do
					if fa.keys[key] and fa.down ~= isDown then
						if isDown and processed then
							continue -- typing in chat or clicking UI
						end
						fa.down = isDown;
						(if isDown then fa.pressed else fa.released):Fire()
					end
				end
			end
		end
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		route(input, true, processed)
	end)
	UserInputService.InputEnded:Connect(function(input, processed)
		route(input, false, processed)
	end)
end

-- Public API ---------------------------------------------------------------------------

-- Settings menu key binds (Config/Keys): swaps each rebindable action's keyboard key, in every context that has it.
function Input.ApplyBinds(binds: { [string]: any }?)
	for _, bind in Keys.Rebindable do
		local code = Keys.For(bind.action, binds)
		if code then
			for _, ctx in keyboardBinding do
				local b = ctx[bind.action]
				-- an InputBinding instance (Input Action System) or a fallback table; indexing a missing field
				-- of an Instance throws, so check the type first
				if typeof(b) == "Instance" then
					b.KeyCode = code
				elseif b and b.fallback then
					b.fallback.keys[b.key] = nil
					b.key = code
					b.fallback.keys[code] = true
				end
			end
		end
	end
end

function Input.Init()
	Input.UsingActionSystem = buildActionSystem()
	if not Input.UsingActionSystem then
		buildFallback()
	end
	Input.ApplyBinds(Settings.Get("KeyBinds"))
	Settings.Changed:Connect(function(key, value)
		if key == "KeyBinds" then
			Input.ApplyBinds(value)
		end
	end)
end

function Input.action(context: string, name: string): Action
	local ctx = actions[context]
	assert(ctx and ctx[name], `Unknown input action {context}.{name}`)
	return ctx[name]
end

function Input.setEnabled(context: string, enabled: boolean)
	contextEnabled[context] = enabled
	local inst = contextInstances[context] :: any
	if inst then
		inst.Enabled = enabled
	end
end

function Input.isEnabled(context: string): boolean
	return contextEnabled[context] == true
end

-- Binds an on-screen button (mobile) to an action.
function Input.bindButton(context: string, name: string, button: GuiButton)
	local inst = contextInstances[context]
	if inst then
		local act = inst:FindFirstChild(name)
		if act then
			local b = Instance.new("InputBinding") :: any
			b.UIButton = button
			b.Parent = act
		end
		return
	end
	local fa = fallback[context] and fallback[context][name]
	if not fa then
		return
	end
	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and not fa.down and contextEnabled[context] then
			fa.down = true
			fa.pressed:Fire()
		end
	end)
	button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and fa.down then
			fa.down = false
			fa.released:Fire()
		end
	end)
end

return Input
