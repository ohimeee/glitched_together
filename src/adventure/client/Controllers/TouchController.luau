-- On-screen buttons for phones and tablets (mobile pass, LAUNCH.md §3). Shown only while the last input was touch.
-- Round buttons sit in two rings round Roblox's own jump button (bottom right; its size follows the screen), so
-- the right thumb rolls from JUMP to DASH / POUND / GRAB and out to the tools. Each world shows only what its kit
-- uses: tool buttons say what they do (FREEZE, GRAPPLE, FIRE...) with a small 1 / 2 badge (Pip's hints say
-- "TOOL 1"), IGNITE for Kai in the castle, ROTATE for the copier, ULT once the castle ultimate is full.
-- PING / PEEK sit small at the top right, SKIP shows during cutscenes; downed = tap anywhere (ReviveController).
-- Buttons bind to the same Input actions as keys, so holds (block, auto-fire, crouch) work the same.
-- Look (user Oct 17: "search for references for other games in roblox for their mobile buttons ui"; DevForum "The
-- Correct Way to Design Mobile Buttons", Arsenal, BedWars): see-through circles with a thin white ring and a white
-- icon only (user: "remove the word ... make it like transparent like this", Arsenal's look), built off the jump
-- button's two size presets; the main tool button is bigger (BedWars' sword). Captions stay as hidden labels.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Glyphs = require(ReplicatedStorage.Shared.Util.Glyphs)
local Input = require(script.Parent.Parent.Input)
local TopDownAim = require(script.Parent.Parent.TopDownAim)

local player = Players.LocalPlayer

local TouchController = {}

local INK = Color3.fromRGB(24, 26, 40)
local WHITE = Color3.new(1, 1, 1) -- rings + badges (Arsenal-style, user reference)
local TOOL_CONTEXTS = { "W1Tools", "CastleTools", "W3Tools" }

-- icon sheet: 8 x 8 cells of 128 px, white icons (tools/ui/touch_icons.js -> textures/ui/touch_icons.png)
local ICON_SHEET = "rbxassetid://124834076029614"
local ICON_CELL = 128
local ICON: { [string]: number } = {
	Dash = 0,
	Blink = 1,
	Charge = 2,
	Pound = 3,
	Grab = 4,
	Freeze = 5,
	Release = 6,
	Grapple = 7,
	Pull = 8,
	Fire = 9,
	Wall = 10,
	Sword = 11,
	Block = 12,
	Copy = 13,
	Paste = 14,
	Shift = 15,
	PullOut = 16,
	Ignite = 17,
	Rotate = 18,
	Meteor = 19,
	Rally = 20,
	Ping = 21,
	Peek = 22,
	Skip = 23,
}

-- per kit: { Tool1, Tool2, Dash? } as { caption, icon }
local KIT_LABELS: { [string]: { { string } } } = {
	PauseBeam = { { "FREEZE", "Freeze" }, { "RELEASE", "Release" } },
	GrappleLine = { { "GRAPPLE", "Grapple" }, { "PULL", "Pull" } },
	FireMage = { { "FIRE", "Fire" }, { "WALL", "Wall" }, { "BLINK", "Blink" } },
	ShieldKnight = { { "SWORD", "Sword" }, { "BLOCK", "Block" }, { "CHARGE", "Charge" } },
	CopyPaste = { { "COPY", "Copy" }, { "PASTE", "Paste" } },
	LayerShift = { { "SHIFT", "Shift" }, { "PULL", "PullOut" } },
}

type Button = {
	button: TextButton,
	label: TextLabel,
	icon: ImageLabel,
	badge: TextLabel?,
	ring: number?,
	angle: number?,
	topDown: { number }?, -- { ring, angle } with no jump button (castle); DASH sits in the jump button's spot
	small: boolean?,
	big: boolean?,
}

local gui: ScreenGui
local buttons: { [string]: Button } = {}
-- top-down (castle) has no jump: DASH takes the jump button's spot and the tools close in (Button.topDown)
local noJump = false

local function setIcon(entry: Button, key: string)
	local index = ICON[key] or 0
	entry.icon.ImageRectOffset = Vector2.new(index % 8, index // 8) * ICON_CELL
end

local function make(name: string, text: string, iconKey: string, small: boolean?): Button
	local b = Instance.new("TextButton")
	b.Name = name
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.BackgroundColor3 = INK
	b.BackgroundTransparency = Tuning.Touch.Fill
	b.AutoButtonColor = false
	b.Text = ""
	b.Visible = false
	b.Parent = gui
	Instance.new("UICorner", b).CornerRadius = UDim.new(0.5, 0)
	local rim = Instance.new("UIStroke")
	rim.Name = "Rim"
	rim.Color = WHITE
	rim.Thickness = 2
	rim.Transparency = Tuning.Touch.Rim
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Parent = b
	local icon = Instance.new("ImageLabel")
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromScale(0.58, 0.58)
	icon.BackgroundTransparency = 1
	icon.ImageTransparency = Tuning.Touch.Icon
	icon.Image = ICON_SHEET
	icon.ImageRectSize = Vector2.new(ICON_CELL, ICON_CELL)
	icon.Parent = b
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.78)
	label.Size = UDim2.fromScale(0.7, 0.17)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(240, 240, 232)
	label.Text = text
	label.Visible = false -- icon only (user); the caption still names the button for code and checks
	label.Parent = b
	local press = Instance.new("UIScale")
	press.Parent = b
	b.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			press.Scale = 0.9
			b.BackgroundTransparency = Tuning.Touch.FillPressed
		end
	end)
	b.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			press.Scale = 1
			b.BackgroundTransparency = Tuning.Touch.Fill
		end
	end)
	local entry: Button = { button = b, label = label, icon = icon, small = small }
	setIcon(entry, iconKey)
	buttons[name] = entry
	return entry
end

local function badge(entry: Button, text: string)
	local t = Instance.new("TextLabel")
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.86, 0.14)
	t.Size = UDim2.fromScale(0.28, 0.28)
	t.BackgroundColor3 = WHITE
	t.BackgroundTransparency = 0.3
	t.TextColor3 = INK
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.Text = text
	t.Parent = entry.button
	Instance.new("UICorner", t).CornerRadius = UDim.new(0.5, 0)
	entry.badge = t
end

-- shows the word under the icon (user asked for it on IGNITE: a fire icon alone reads as FIRE)
local function caption(entry: Button)
	entry.icon.Position = UDim2.fromScale(0.5, 0.4)
	entry.icon.Size = UDim2.fromScale(0.46, 0.46)
	entry.label.Position = UDim2.fromScale(0.5, 0.76)
	entry.label.Size = UDim2.fromScale(0.72, 0.2)
	entry.label.Visible = true
end

-- Roblox's jump button: centre + size in screen pixels (its layout rule when it isn't built yet)
local function jumpRect(): (Vector2, number)
	local touchGui = player.PlayerGui:FindFirstChild("TouchGui")
	local frame = touchGui and touchGui:FindFirstChild("TouchControlFrame")
	local jump = frame and frame:FindFirstChild("JumpButton") :: GuiObject?
	if jump and jump.AbsoluteSize.X > 0 then
		local at = jump.AbsolutePosition + jump.AbsoluteSize / 2
		if not (touchGui :: ScreenGui).IgnoreGuiInset then
			at += GuiService:GetGuiInset() -- ours ignores the top bar inset, Roblox's may not
		end
		return at, jump.AbsoluteSize.X
	end
	local view = gui.AbsoluteSize
	if math.min(view.X, view.Y) <= 500 then
		return Vector2.new(view.X - 60, view.Y - 55), 70
	end
	return Vector2.new(view.X - 110, view.Y - 150), 120
end

local function layout()
	local center, jumpSize = jumpRect()
	local size = math.clamp(jumpSize * 0.9, Tuning.Touch.Button, Tuning.Touch.Button * 1.5)
	local small = math.clamp(size * 0.75, Tuning.Touch.Small, Tuning.Touch.Small * 1.5)
	local gap = size * 0.16
	local radius = { jumpSize / 2 + gap + size / 2 }
	radius[2] = radius[1] + size + gap
	local view = gui.AbsoluteSize
	local edge = Tuning.Touch.Edge
	for _, entry in buttons do
		local px = if entry.small then small elseif entry.big then size * Tuning.Touch.BigScale else size
		entry.button.Size = UDim2.fromOffset(px, px)
		if entry.ring and entry.angle then
			local p = center
			local spot = if noJump then entry.topDown else { entry.ring, entry.angle }
			if spot then
				local ring = spot[1]
				local a = math.rad(spot[2])
				local r = radius[ring] + (px - size) / 2 -- a bigger button steps outward, clear of the inner ring
				p = center + Vector2.new(math.cos(a) * r, -math.sin(a) * r)
			end
			-- never past the screen's edge (a big button low on the outer ring sank off a phone's bottom)
			p = Vector2.new(
				math.clamp(p.X, px / 2 + edge, view.X - px / 2 - edge),
				math.clamp(p.Y, px / 2 + edge, view.Y - px / 2 - edge)
			)
			entry.button.Position = UDim2.fromOffset(p.X, p.Y)
		end
	end
	-- top right, in a row under the top bar (clear of the rings); SKIP takes the same corner in cutscenes
	local top = GuiService:GetGuiInset().Y + small * 0.75
	buttons.Ping.button.Position = UDim2.fromOffset(view.X - small * 0.75, top)
	buttons.Peek.button.Position = UDim2.fromOffset(view.X - small * 2, top)
	buttons.Skip.button.Position = UDim2.fromOffset(view.X - small * 0.9, top)
end

-- ULT (castle): Meteor drags to aim (Brawl Stars-style; the icon follows the finger, the floor ring shows the
-- blast), let go to cast. Meteor lands on the ring (a tap = auto-aim); Miko leaps to the ring and Rallies there
-- (a tap = in place).
local function bindUltDrag(entry: Button)
	local held: InputObject? = nil
	local start = Vector2.zero
	local function finish(cast: boolean)
		held = nil
		entry.icon.Position = UDim2.fromScale(0.5, 0.5)
		if cast then
			TopDownAim.ReleaseUlt()
		else
			TopDownAim.Drag(nil)
		end
	end
	entry.button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch or held then
			return
		end
		held = input
		start = Vector2.new(input.Position.X, input.Position.Y)
		if player:GetAttribute("Kit") == "ShieldKnight" then
			local rally = Tuning.ShieldKnight.Rally
			TopDownAim.Drag(Vector2.zero, rally.LeapReach, rally.Radius)
		else
			TopDownAim.Drag(Vector2.zero, Tuning.Touch.UltReach, Tuning.FireMage.Meteor.Radius)
		end
	end)
	UserInputService.TouchMoved:Connect(function(input)
		if input ~= held then
			return
		end
		local offset = Vector2.new(input.Position.X, input.Position.Y) - start
		TopDownAim.Drag(offset)
		local px = entry.button.AbsoluteSize.X
		local knob = if offset.Magnitude > 0 then offset.Unit * math.min(offset.Magnitude, px * 0.45) else offset
		entry.icon.Position = UDim2.new(0.5, knob.X, 0.5, knob.Y)
	end)
	UserInputService.TouchEnded:Connect(function(input)
		if input == held then
			finish(entry.button.Visible)
		end
	end)
	entry.button:GetPropertyChangedSignal("Visible"):Connect(function()
		if held and not entry.button.Visible then
			finish(false) -- downed / cutscene mid-drag
		end
	end)
end

local function place(entry: Button, ring: number, angle: number)
	entry.ring, entry.angle = ring, angle
end

local function refresh()
	local touch = Glyphs.device() == "Touch"
	local cutscene = player:GetAttribute("InCutscene") == true or Input.isEnabled("MenuContext")
	local downed = player:GetAttribute("Downed") == true
	local play = touch and not cutscene and not downed
	local kit = player:GetAttribute("Kit") :: string?
	local labels = kit and KIT_LABELS[kit]
	local topDown = player:GetAttribute("CameraMode") == "TopDown"
	local castle = kit == "FireMage" or kit == "ShieldKnight"
	local ultReady = ((player:GetAttribute("Ultimate") or 0) :: number) >= 1

	buttons.Dash.button.Visible = play
	local dash = labels and labels[3]
	buttons.Dash.label.Text = if dash then dash[1] else "DASH"
	setIcon(buttons.Dash, if dash then dash[2] else "Dash")
	Glyphs.SetTouch("Dash", if dash then dash[1] else nil)
	buttons.Pound.button.Visible = play and not topDown
	buttons.Grab.button.Visible = play and not topDown
	buttons.Tool1.button.Visible = play and labels ~= nil
	buttons.Tool2.button.Visible = play and labels ~= nil
	if labels then
		buttons.Tool1.label.Text, buttons.Tool2.label.Text = labels[1][1], labels[2][1]
		setIcon(buttons.Tool1, labels[1][2])
		setIcon(buttons.Tool2, labels[2][2])
	end
	buttons.Ignite.button.Visible = play and kit == "FireMage"
	buttons.Rotate.button.Visible = play and kit == "CopyPaste"
	buttons.Ultimate.button.Visible = play and castle and ultReady
	buttons.Ultimate.label.Text = if kit == "FireMage" then "METEOR" else "RALLY"
	setIcon(buttons.Ultimate, if kit == "FireMage" then "Meteor" else "Rally")
	buttons.Ping.button.Visible = play
	buttons.Peek.button.Visible = play
	buttons.Skip.button.Visible = touch and cutscene and not downed
	if noJump ~= topDown then
		noJump = topDown
		layout()
	end
end

function TouchController.Init()
	gui = Instance.new("ScreenGui")
	gui.Name = "TouchButtons"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 5
	gui.Parent = player:WaitForChild("PlayerGui")

	place(make("Dash", "DASH", "Dash"), 1, 180)
	place(make("Pound", "POUND", "Pound"), 1, 135)
	place(make("Grab", "GRAB", "Grab"), 1, 90)
	local tool1 = make("Tool1", "TOOL 1", "Freeze")
	tool1.big = true -- the main action, like BedWars' sword
	badge(tool1, "1")
	place(tool1, 2, 185)
	tool1.topDown = { 1, 180 }
	local tool2 = make("Tool2", "TOOL 2", "Release")
	badge(tool2, "2")
	place(tool2, 2, 152)
	tool2.topDown = { 1, 118 }
	local ignite = make("Ignite", "IGNITE", "Ignite")
	caption(ignite)
	place(ignite, 2, 120)
	ignite.topDown = { 2, 150 }
	place(make("Rotate", "ROTATE", "Rotate"), 2, 120)
	local ult = make("Ultimate", "ULT", "Meteor")
	place(ult, 2, 92)
	ult.topDown = { 2, 105 }
	make("Ping", "PING", "Ping", true)
	make("Peek", "PEEK", "Peek", true)
	make("Skip", "SKIP", "Skip", true)

	Input.bindButton("BaseContext", "Dash", buttons.Dash.button)
	Input.bindButton("BaseContext", "GroundPound", buttons.Pound.button)
	Input.bindButton("BaseContext", "Swing", buttons.Grab.button)
	Input.bindButton("BaseContext", "Ping", buttons.Ping.button)
	Input.bindButton("BaseContext", "Peek", buttons.Peek.button)
	for _, ctx in TOOL_CONTEXTS do
		Input.bindButton(ctx, "Tool1", buttons.Tool1.button)
		Input.bindButton(ctx, "Tool2", buttons.Tool2.button)
	end
	Input.bindButton("CastleTools", "Ignite", buttons.Ignite.button)
	bindUltDrag(buttons.Ultimate)
	Input.bindButton("W3Tools", "Rotate", buttons.Rotate.button)
	Input.bindButton("MenuContext", "Skip", buttons.Skip.button)

	layout()
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	-- the jump button is built (and resized) by Roblox's touch module after us
	task.spawn(function()
		local touchGui = player.PlayerGui:WaitForChild("TouchGui", 30)
		local frame = touchGui and touchGui:WaitForChild("TouchControlFrame", 10)
		local jump = frame and frame:WaitForChild("JumpButton", 10) :: GuiObject?
		if jump then
			jump:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
			jump:GetPropertyChangedSignal("AbsolutePosition"):Connect(layout)
			layout()
		end
	end)

	Glyphs.Changed:Connect(refresh)
	for _, attr in { "Kit", "CameraMode", "Ultimate", "InCutscene", "Downed", "Role" } do
		player:GetAttributeChangedSignal(attr):Connect(refresh)
	end
	-- MenuContext (cutscene skip / picker) has no attribute of its own: a cheap poll
	local last = false
	RunService.Heartbeat:Connect(function()
		local now = Input.isEnabled("MenuContext")
		if now ~= last then
			last = now
			refresh()
		end
	end)
	refresh()
end

return TouchController
