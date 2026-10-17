-- On-screen buttons for phones and tablets (mobile pass, LAUNCH.md §3). Shown only while the last input was touch.
-- Round buttons sit in two rings round Roblox's own jump button (bottom right; its size follows the screen), so
-- the right thumb rolls from JUMP to DASH / POUND / GRAB and out to the tools. Each world shows only what its kit
-- uses: tool buttons say what they do (FREEZE, GRAPPLE, FIRE...) with a small 1 / 2 badge (Pip's hints say
-- "TOOL 1"), IGNITE for Kai in the castle, ROTATE for the copier, ULT once the castle ultimate is full.
-- PING / PEEK sit small at the top right, SKIP shows during cutscenes; downed = tap anywhere (ReviveController).
-- Buttons bind to the same Input actions as keys, so holds (block, auto-fire, crouch) work the same.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local Roles = require(ReplicatedStorage.Shared.Config.Roles)
local Glyphs = require(ReplicatedStorage.Shared.Util.Glyphs)
local Input = require(script.Parent.Parent.Input)

local player = Players.LocalPlayer

local TouchController = {}

local INK = Color3.fromRGB(24, 26, 40)
local TOOL_CONTEXTS = { "W1Tools", "CastleTools", "W3Tools" }

-- per kit: { Tool1 label, Tool2 label, Dash label }
local KIT_LABELS: { [string]: { string } } = {
	PauseBeam = { "FREEZE", "RELEASE" },
	GrappleLine = { "GRAPPLE", "PULL" },
	FireMage = { "FIRE", "WALL", "BLINK" },
	ShieldKnight = { "SWORD", "BLOCK", "CHARGE" },
	CopyPaste = { "COPY", "PASTE" },
	LayerShift = { "SHIFT", "PULL" },
}

type Button =
	{ button: TextButton, label: TextLabel, badge: TextLabel?, ring: number?, angle: number?, small: boolean? }

local gui: ScreenGui
local buttons: { [string]: Button } = {}

local function make(name: string, text: string, small: boolean?): Button
	local b = Instance.new("TextButton")
	b.Name = name
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.BackgroundColor3 = INK
	b.BackgroundTransparency = 0.35
	b.AutoButtonColor = false
	b.Text = ""
	b.Visible = false
	b.Parent = gui
	Instance.new("UICorner", b).CornerRadius = UDim.new(0.5, 0)
	local rim = Instance.new("UIStroke")
	rim.Name = "Rim"
	rim.Color = Palette.Neutral
	rim.Thickness = 2
	rim.Transparency = 0.2
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Parent = b
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.Size = UDim2.fromScale(0.78, 0.36)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(240, 240, 232)
	label.Text = text
	label.Parent = b
	local press = Instance.new("UIScale")
	press.Parent = b
	b.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			press.Scale = 0.9
			b.BackgroundTransparency = 0.15
		end
	end)
	b.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			press.Scale = 1
			b.BackgroundTransparency = 0.35
		end
	end)
	local entry: Button = { button = b, label = label, small = small }
	buttons[name] = entry
	return entry
end

local function badge(entry: Button, text: string)
	local t = Instance.new("TextLabel")
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = UDim2.fromScale(0.85, 0.15)
	t.Size = UDim2.fromScale(0.32, 0.32)
	t.BackgroundColor3 = Palette.Neutral
	t.TextColor3 = INK
	t.Font = Enum.Font.GothamBlack
	t.TextScaled = true
	t.Text = text
	t.Parent = entry.button
	Instance.new("UICorner", t).CornerRadius = UDim.new(0.5, 0)
	entry.badge = t
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
	for _, entry in buttons do
		local px = if entry.small then small else size
		entry.button.Size = UDim2.fromOffset(px, px)
		if entry.ring and entry.angle then
			local a = math.rad(entry.angle)
			local r = radius[entry.ring]
			local p = center + Vector2.new(math.cos(a) * r, -math.sin(a) * r)
			entry.button.Position = UDim2.fromOffset(p.X, p.Y)
		end
	end
	local view = gui.AbsoluteSize
	-- top right, in a row under the top bar (clear of the rings); SKIP takes the same corner in cutscenes
	local top = GuiService:GetGuiInset().Y + small * 0.75
	buttons.Ping.button.Position = UDim2.fromOffset(view.X - small * 0.75, top)
	buttons.Peek.button.Position = UDim2.fromOffset(view.X - small * 2, top)
	buttons.Skip.button.Position = UDim2.fromOffset(view.X - small * 0.9, top)
end

local function place(entry: Button, ring: number, angle: number)
	entry.ring, entry.angle = ring, angle
end

local function roleColor(): Color3
	local info = (Roles :: any)[player:GetAttribute("Role") or ""]
	return if info then info.Color else Palette.Neutral
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
	buttons.Dash.label.Text = if labels and labels[3] then labels[3] else "DASH"
	Glyphs.SetTouch("Dash", if labels and labels[3] then labels[3] else nil)
	buttons.Pound.button.Visible = play and not topDown
	buttons.Grab.button.Visible = play and not topDown
	buttons.Tool1.button.Visible = play and labels ~= nil
	buttons.Tool2.button.Visible = play and labels ~= nil
	if labels then
		buttons.Tool1.label.Text = labels[1]
		buttons.Tool2.label.Text = labels[2]
	end
	local tint = roleColor()
	for _, name in { "Tool1", "Tool2", "Ultimate" } do
		(buttons[name].button :: any).Rim.Color = tint
	end
	buttons.Ignite.button.Visible = play and kit == "FireMage"
	buttons.Rotate.button.Visible = play and kit == "CopyPaste"
	buttons.Ultimate.button.Visible = play and castle and ultReady
	buttons.Ultimate.label.Text = if kit == "FireMage" then "METEOR" else "RALLY"
	buttons.Ping.button.Visible = play
	buttons.Peek.button.Visible = play
	buttons.Skip.button.Visible = touch and cutscene and not downed
end

function TouchController.Init()
	gui = Instance.new("ScreenGui")
	gui.Name = "TouchButtons"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 5
	gui.Parent = player:WaitForChild("PlayerGui")

	place(make("Dash", "DASH"), 1, 180)
	place(make("Pound", "POUND"), 1, 135)
	place(make("Grab", "GRAB"), 1, 90)
	local tool1 = make("Tool1", "TOOL 1")
	badge(tool1, "1")
	place(tool1, 2, 185)
	local tool2 = make("Tool2", "TOOL 2")
	badge(tool2, "2")
	place(tool2, 2, 152)
	place(make("Ignite", "IGNITE"), 2, 120)
	place(make("Rotate", "ROTATE"), 2, 120)
	place(make("Ultimate", "ULT"), 2, 92)
	make("Ping", "PING", true)
	make("Peek", "PEEK", true)
	make("Skip", "SKIP", true)

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
	Input.bindButton("CastleTools", "Ultimate", buttons.Ultimate.button)
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
