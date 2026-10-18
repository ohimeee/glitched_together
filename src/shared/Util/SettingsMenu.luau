-- The settings menu (client, both places). A gear in the top bar's right corner opens it (gamepad: the View /
-- Back button); it rebuilds on every open in the current world's UI theme (UiTheme). Tabs: AUDIO, CAMERA, CONTROLS,
-- CO-OP, ACCESS. Every row edits Util/Settings, which saves through the server and tells the game (Settings.Changed).
--   SettingsMenu.Init({ editLayout = fn?, camera = bool?, onOpen = fn?, onClose = fn? })
--     editLayout: opens the touch button editor (Adventure TouchController.EditLayout); no fn = no EDIT BUTTONS row
--     camera = false: the place uses Roblox's own camera (lobby); the camera rows say they apply in the game
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Keys = require(ReplicatedStorage.Shared.Config.Keys)
local Glyphs = require(ReplicatedStorage.Shared.Util.Glyphs)
local Settings = require(ReplicatedStorage.Shared.Util.Settings)
local UiSkin = require(ReplicatedStorage.Shared.Util.UiSkin)
local UiFit = require(ReplicatedStorage.Shared.Util.UiFit)

local player = Players.LocalPlayer

local SettingsMenu = {}

type Opts = {
	editLayout: ((onDone: () -> ()) -> ())?,
	camera: boolean?,
	onOpen: (() -> ())?, -- e.g. the adventure sinks gameplay input (MenuContext) while the panel is up
	onClose: (() -> ())?,
}

local opts: Opts = {}
local gui: ScreenGui
local panel: Frame? = nil
local tab = "AUDIO"
local listening: { cancel: () -> () }? = nil -- a key bind waiting for its key
-- global input hooks of the rows on screen (slider drags): dropped whenever the tab or the panel goes
local rowConns: { RBXScriptConnection } = {}
local function dropRowConns()
	for _, c in rowConns do
		c:Disconnect()
	end
	table.clear(rowConns)
end

local W, H = 600, 470 -- design px (UiFit scales them)
local ROW = 44

local function pct(v: number): string
	return `{math.floor(v * 100 + 0.5)}%`
end
local function times(v: number): string
	return string.format("×%.1f", v)
end

local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local inst = Instance.new(class)
	for k, v in props do
		(inst :: any)[k] = v
	end
	inst.Parent = parent
	return inst
end

local function corner(inst: Instance, px: number)
	new("UICorner", { CornerRadius = UDim.new(0, px) }, inst)
end

-- Rows ----------------------------------------------------------------------------------------------------------

type Ctx = { list: Frame, theme: any, order: number }

local function rowBase(ctx: Ctx, label: string): (Frame, TextLabel)
	ctx.order += 1
	local row = new("Frame", {
		Name = label,
		Size = UDim2.new(1, -12, 0, ROW),
		BackgroundTransparency = 1,
		LayoutOrder = ctx.order,
	}, ctx.list)
	local text = new("TextLabel", {
		Size = UDim2.new(0.42, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = label,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 19,
		TextWrapped = true,
		Font = ctx.theme.Font,
		TextColor3 = ctx.theme.Ink,
	}, row)
	return row, text
end

local function chip(ctx: Ctx, parent: Instance, text: string, size: UDim2, pos: UDim2, fn: () -> ()): TextButton
	local b = new("TextButton", {
		Size = size,
		Position = pos,
		BackgroundColor3 = ctx.theme.Accent,
		Text = text,
		TextSize = 18,
		Font = ctx.theme.TitleFont,
		TextColor3 = UiSkin.InkOn(ctx.theme.Accent),
		AutoButtonColor = true,
	}, parent)
	corner(b, 8)
	b.Activated:Connect(fn)
	return b
end

local function header(ctx: Ctx, text: string)
	ctx.order += 1
	new("TextLabel", {
		Size = UDim2.new(1, -12, 0, 30),
		BackgroundTransparency = 1,
		Text = text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 16,
		Font = ctx.theme.TitleFont,
		TextColor3 = ctx.theme.SubInk,
		LayoutOrder = ctx.order,
	}, ctx.list)
end

local function slider(ctx: Ctx, label: string, key: string, step: number, fmt: (number) -> string)
	local spec = Settings.Specs[key]
	local lo, hi = spec.min :: number, spec.max :: number
	local row = rowBase(ctx, label)
	local valueText = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, 0, 0.5, 0),
		Size = UDim2.new(0, 64, 0, 28),
		BackgroundTransparency = 1,
		TextSize = 18,
		Font = ctx.theme.TitleFont,
		TextColor3 = ctx.theme.Ink,
	}, row)
	local track = new("TextButton", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0.42, 40, 0.5, 0),
		Size = UDim2.new(0.58, -40 - 34 - 72, 0, 12),
		BackgroundColor3 = ctx.theme.Shadow,
		BackgroundTransparency = 0.2,
		Text = "",
		AutoButtonColor = false,
		Selectable = false,
	}, row)
	corner(track, 6)
	local fill = new("Frame", { BackgroundColor3 = ctx.theme.Accent, Size = UDim2.fromScale(0, 1) }, track)
	corner(fill, 6)
	local knob = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = ctx.theme.Ink,
		Position = UDim2.fromScale(0, 0.5),
	}, track)
	corner(knob, 11)
	local function show(v: number)
		local k = (v - lo) / (hi - lo)
		fill.Size = UDim2.fromScale(k, 1)
		knob.Position = UDim2.fromScale(k, 0.5)
		valueText.Text = fmt(v)
	end
	local function set(v: number)
		v = math.clamp(math.floor((v - lo) / step + 0.5) * step + lo, lo, hi)
		Settings.Set(key, v)
		show(v)
	end
	show(Settings.Get(key))
	chip(ctx, row, "-", UDim2.fromOffset(32, 32), UDim2.new(0.42, 2, 0.5, -16), function()
		set((Settings.Get(key) :: number) - step)
	end)
	chip(ctx, row, "+", UDim2.fromOffset(32, 32), UDim2.new(1, -72 - 34, 0.5, -16), function()
		set((Settings.Get(key) :: number) + step)
	end)
	local dragging: InputObject? = nil
	local function at(x: number)
		local k = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		set(lo + k * (hi - lo))
	end
	track.InputBegan:Connect(function(input)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or t == Enum.UserInputType.Touch then
			dragging = input
			at(input.Position.X)
		end
	end)
	table.insert(
		rowConns,
		UserInputService.InputChanged:Connect(function(input)
			local d = dragging
			if not d or not track.Parent then
				return
			end
			if
				input == d
				or (
					input.UserInputType == Enum.UserInputType.MouseMovement
					and d.UserInputType == Enum.UserInputType.MouseButton1
				)
			then
				at(input.Position.X)
			end
		end)
	)
	table.insert(
		rowConns,
		UserInputService.InputEnded:Connect(function(input)
			local d = dragging
			if
				d
				and (
					input == d
					or (input.UserInputType == d.UserInputType and d.UserInputType == Enum.UserInputType.MouseButton1)
				)
			then
				dragging = nil
			end
		end)
	)
end

local function choice(ctx: Ctx, label: string, key: string, names: { [string]: string }?)
	local options = Settings.Specs[key].options :: { string }
	local row = rowBase(ctx, label)
	local function name(v: string): string
		return if names and names[v] then names[v] else string.upper(v)
	end
	local b: TextButton
	b = chip(ctx, row, name(Settings.Get(key)), UDim2.new(0.58, -4, 0, 34), UDim2.new(0.42, 4, 0.5, -17), function()
		local i = table.find(options, Settings.Get(key)) or 0
		local v = options[i % #options + 1]
		Settings.Set(key, v)
		b.Text = name(v)
	end)
end

local function toggle(ctx: Ctx, label: string, key: string)
	local row = rowBase(ctx, label)
	local b: TextButton
	b = chip(
		ctx,
		row,
		if Settings.Get(key) then "ON" else "OFF",
		UDim2.new(0, 110, 0, 34),
		UDim2.new(0.42, 4, 0.5, -17),
		function()
			local v = not Settings.Get(key)
			Settings.Set(key, v)
			b.Text = if v then "ON" else "OFF"
		end
	)
end

local function action(ctx: Ctx, label: string, text: string, fn: () -> ())
	local row = rowBase(ctx, label)
	chip(ctx, row, text, UDim2.new(0.58, -4, 0, 34), UDim2.new(0.42, 4, 0.5, -17), fn)
end

local function keyRow(ctx: Ctx, bind: Keys.Bind)
	local row = rowBase(ctx, bind.label)
	local b: TextButton
	local function show()
		local code = Keys.For(bind.action, Settings.Get("KeyBinds"))
		b.Text = if code then Keys.Name(code.Name) else "?"
	end
	b = chip(ctx, row, "", UDim2.new(0, 150, 0, 34), UDim2.new(0.42, 4, 0.5, -17), function()
		if listening then
			listening.cancel()
		end
		b.Text = "PRESS A KEY..."
		local conn: RBXScriptConnection
		local entry: { cancel: () -> () } = { cancel = function() end }
		entry.cancel = function()
			conn:Disconnect()
			listening = nil
			if b.Parent then
				show()
			end
		end
		listening = entry
		conn = UserInputService.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.Keyboard then
				return
			end
			local name = input.KeyCode.Name
			if name == "Escape" then
				entry.cancel()
				return
			end
			if Keys.Reserved[name] then
				b.Text = `{Keys.Name(name)} IS TAKEN`
				return
			end
			local binds = Settings.Get("KeyBinds") :: { [string]: any }
			-- a key used by another action swaps over to this one's old key
			local old = Keys.For(bind.action, binds)
			for _, other in Keys.Rebindable do
				if other.action ~= bind.action then
					local theirs = Keys.For(other.action, binds)
					if theirs and theirs.Name == name and old then
						binds[other.action] = old.Name
					end
				end
			end
			binds[bind.action] = name
			Settings.Set("KeyBinds", binds)
			entry.cancel()
			-- the swapped row shows its new key too
			for _, r in ctx.list:GetChildren() do
				local chipButton = r:FindFirstChildOfClass("TextButton")
				local refresh = chipButton and (chipButton :: any):GetAttribute("KeyAction")
				if refresh then
					local code = Keys.For(refresh, binds)
					chipButton.Text = if code then Keys.Name(code.Name) else "?"
				end
			end
		end)
	end)
	b:SetAttribute("KeyAction", bind.action)
	show()
end

-- Tabs ----------------------------------------------------------------------------------------------------------

local TABS = { "AUDIO", "CAMERA", "CONTROLS", "CO-OP", "ACCESS" }

local function fill(ctx: Ctx, name: string)
	if name == "AUDIO" then
		slider(ctx, "Music", "MusicVolume", 0.05, pct)
		slider(ctx, "Sound effects", "SfxVolume", 0.05, pct)
		slider(ctx, "Ambience", "AmbienceVolume", 0.05, pct)
		slider(ctx, "Interface", "UiVolume", 0.05, pct)
	elseif name == "CAMERA" then
		if opts.camera == false then
			header(ctx, "The bedroom uses Roblox's camera: these apply in the game.")
		end
		slider(ctx, "Mouse sensitivity", "MouseSensitivity", 0.1, times)
		slider(ctx, "Controller sensitivity", "GamepadSensitivity", 0.1, times)
		slider(ctx, "Touch sensitivity", "TouchSensitivity", 0.1, times)
		toggle(ctx, "Invert up / down", "InvertY")
		slider(ctx, "Field of view", "FovOffset", 1, function(v)
			return if v > 0 then `+{v}°` elseif v < 0 then `{v}°` else "0°"
		end)
	elseif name == "CONTROLS" then
		local touch = Glyphs.device() == "Touch" or UserInputService.TouchEnabled
		if opts.editLayout and touch then
			action(ctx, "Touch buttons", "EDIT BUTTONS", function()
				local edit = opts.editLayout :: (() -> ()) -> ()
				SettingsMenu.Close()
				edit(function()
					SettingsMenu.Open()
				end)
			end)
		end
		if opts.editLayout and touch then
			slider(ctx, "Touch button opacity", "TouchOpacity", 0.1, times)
		end
		choice(ctx, "Sprint key", "SprintMode", { Toggle = "PRESS TO TOGGLE", Hold = "HOLD TO RUN" })
		slider(ctx, "Aim assist", "AutoAim", 0.25, function(v)
			return if v <= 0 then "OFF" elseif v < 1 then "LOW" elseif v > 1 then "HIGH" else "NORMAL"
		end)
		header(ctx, "KEYBOARD  (Esc cancels; a used key swaps places)")
		for _, bind in Keys.Rebindable do
			keyRow(ctx, bind)
		end
		action(ctx, "", "RESET KEYS", function()
			Settings.Reset({ "KeyBinds" })
			SettingsMenu.Open()
		end)
	elseif name == "CO-OP" then
		choice(ctx, "Partner outline", "PartnerOutline", {
			Always = "ALWAYS",
			Hidden = "ONLY BEHIND WALLS",
			Off = "OFF",
		})
		slider(ctx, "Ping marker size", "PingSize", 0.1, times)
	elseif name == "ACCESS" then
		toggle(ctx, "Colorblind shapes on targets", "ColorblindIcons")
		slider(ctx, "Text size", "TextScale", 0.05, pct)
		slider(ctx, "Text speed", "TextSpeed", 0.25, times)
		toggle(ctx, "Pip's hints", "PipHints")
	end
end

-- Panel ---------------------------------------------------------------------------------------------------------

function SettingsMenu.Close()
	dropRowConns()
	if listening then
		listening.cancel()
	end
	if panel then
		panel:Destroy()
		panel = nil
		if opts.onClose then
			opts.onClose()
		end
	end
end

function SettingsMenu.Open()
	SettingsMenu.Close()
	local theme = UiSkin.Theme()
	if opts.onOpen then
		opts.onOpen()
	end

	local p = new("Frame", {
		Name = "SettingsPanel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(W, H),
		ZIndex = 2,
	}, gui)
	UiSkin.Panel(p)
	panel = p
	-- the panel never leaves a small phone screen
	local fit = new("UISizeConstraint", { MaxSize = Vector2.new(W, H) }, p)
	local function clampSize()
		local view = gui.AbsoluteSize / UiFit.scale(gui)
		fit.MaxSize = Vector2.new(math.min(W, view.X - 20), math.min(H, view.Y - 20))
	end
	clampSize()

	local title = new("TextLabel", {
		Position = UDim2.fromOffset(18, 10),
		Size = UDim2.new(1, -80, 0, 34),
		BackgroundTransparency = 1,
		Text = "SETTINGS",
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = 28,
	}, p)
	UiSkin.Text(title, "Title")
	local close = new("TextButton", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(38, 38),
		BackgroundColor3 = theme.Accent,
		Text = "X", -- the ✕ glyph doesn't render in the theme fonts
		TextSize = 24,
		Font = Enum.Font.GothamBlack,
		TextColor3 = UiSkin.InkOn(theme.Accent),
	}, p)
	corner(close, 10)
	close.Activated:Connect(SettingsMenu.Close)

	local tabs = new("Frame", {
		Position = UDim2.fromOffset(12, 52),
		Size = UDim2.new(1, -24, 0, 36),
		BackgroundTransparency = 1,
	}, p)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, tabs)
	local list = new("ScrollingFrame", {
		Position = UDim2.fromOffset(14, 98),
		Size = UDim2.new(1, -20, 1, -108),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = theme.Ink,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, p)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, list)

	local tabButtons: { [string]: TextButton } = {}
	local function showTab(name: string)
		dropRowConns()
		if listening then
			listening.cancel()
		end
		tab = name
		for _, c in list:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		for n, b in tabButtons do
			b.BackgroundTransparency = if n == name then 0 else 0.65
		end
		local ctx: Ctx = { list = list, theme = theme, order = 0 }
		fill(ctx, name)
		ctx.order += 1
		local footer =
			new("Frame", { Size = UDim2.new(1, -12, 0, 50), BackgroundTransparency = 1, LayoutOrder = ctx.order }, list)
		chip(ctx, footer, "RESET ALL", UDim2.fromOffset(150, 36), UDim2.new(0, 0, 0.5, -18), function()
			Settings.Reset()
			SettingsMenu.Open()
		end)
		list.CanvasPosition = Vector2.zero
	end
	for i, name in TABS do
		local b = new("TextButton", {
			Size = UDim2.new(1 / #TABS, -6, 1, 0),
			BackgroundColor3 = theme.Accent,
			Text = name,
			TextScaled = true,
			Font = theme.TitleFont,
			TextColor3 = UiSkin.InkOn(theme.Accent),
			LayoutOrder = i,
		}, tabs)
		corner(b, 8)
		new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }, b)
		tabButtons[name] = b
		b.Activated:Connect(function()
			showTab(name)
		end)
	end
	showTab(tab)
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = tabButtons[tab]
	end
end

function SettingsMenu.Toggle()
	if panel then
		SettingsMenu.Close()
	else
		SettingsMenu.Open()
	end
end

function SettingsMenu.Init(o: Opts?)
	opts = o or {}
	gui = Instance.new("ScreenGui")
	gui.Name = "Settings"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 30 -- over the HUD, touch buttons, credits
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling -- children draw over their panel (Global hid every row)
	gui.Parent = player:WaitForChild("PlayerGui")
	UiFit.attach(gui)

	-- gear: in the top bar's right corner (clear of every HUD / lobby button below it); no backing (user)
	local gear = new("TextButton", {
		Name = "Gear",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 2),
		Size = UDim2.fromOffset(54, 54),
		BackgroundTransparency = 1,
		Text = "",
	}, gui)
	-- plain white gear drawn from frames (the ⚙ character renders as a grey emoji that ignores TextColor):
	-- a thick ring with 8 square teeth round it
	local white = Color3.new(1, 1, 1)
	for i = 0, 7 do
		local a = math.rad(i * 45)
		local tooth = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5 + math.sin(a) * 0.36, 0.5 - math.cos(a) * 0.36),
			Size = UDim2.fromScale(0.18, 0.2),
			Rotation = i * 45,
			BackgroundColor3 = white,
			BorderSizePixel = 0,
		}, gear)
		corner(tooth, 2)
	end
	local ring = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
	}, gear)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, ring)
	new("UIStroke", { Color = white, Thickness = 8 }, ring)
	gear.Activated:Connect(SettingsMenu.Toggle)

	UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.ButtonSelect then
			SettingsMenu.Toggle()
		elseif input.KeyCode == Enum.KeyCode.ButtonB and panel and not processed then
			SettingsMenu.Close()
		end
	end)
end

return SettingsMenu
