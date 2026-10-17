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
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Glyphs = require(ReplicatedStorage.Shared.Util.Glyphs)
local Net = require(ReplicatedStorage.Shared.Net)
local Input = require(script.Parent.Parent.Input)
local TopDownAim = require(script.Parent.Parent.TopDownAim)

local player = Players.LocalPlayer

local TouchController = {}

local INK = Color3.fromRGB(24, 26, 40)
local WHITE = Color3.new(1, 1, 1) -- rings + badges (Arsenal-style, user reference)
local TOOL_CONTEXTS = { "W1Tools", "CastleTools", "W3Tools" }

-- one 128 px white icon per image (cells of tools/ui/touch_icons.js -> textures/ui/touch_icons.png). Not a sprite
-- sheet + ImageRectOffset: the 1024 px sheet showed blank buttons on a real phone (Oct 17, published test).
local ICON: { [string]: string } = {
	Dash = "rbxassetid://129855379396466",
	Blink = "rbxassetid://85378013547834",
	Charge = "rbxassetid://128884989172941",
	Pound = "rbxassetid://103293551589754",
	Grab = "rbxassetid://134355715190127",
	Freeze = "rbxassetid://127732944365423",
	Release = "rbxassetid://76013034027883",
	Grapple = "rbxassetid://134355715190127", -- same art as Grab
	Pull = "rbxassetid://97314025279661",
	Fire = "rbxassetid://128417590995307",
	Wall = "rbxassetid://110550751590185",
	Sword = "rbxassetid://78711004576914",
	Block = "rbxassetid://116616288451443",
	Copy = "rbxassetid://130995614037295",
	Paste = "rbxassetid://95522685100659",
	Shift = "rbxassetid://81540484048773",
	PullOut = "rbxassetid://85456769289659",
	Ignite = "rbxassetid://110866917171495",
	Rotate = "rbxassetid://137199471516320",
	Meteor = "rbxassetid://126488098368427",
	Rally = "rbxassetid://109378563236768",
	Ping = "rbxassetid://71889071729482",
	Peek = "rbxassetid://132709227837164",
	Skip = "rbxassetid://73280159524845",
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
	captioned: boolean?, -- the word shows under the icon (caption)
}

local gui: ScreenGui
local buttons: { [string]: Button } = {}
-- top-down (castle) has no jump: DASH takes the jump button's spot and the tools close in (Button.topDown)
local noJump = false

-- An icon that fails to download shows the button's word instead, never an empty ring: phones got new uploads hours
-- after PC (Oct 17: every icon "Failure" on a phone, "Success" in Studio and on PC).
local function setIcon(entry: Button, key: string)
	local image = ICON[key] or ICON.Dash
	entry.icon.Image = image
	task.spawn(function()
		local ok = true
		ContentProvider:PreloadAsync({ entry.icon }, function(_, status)
			ok = status == Enum.AssetFetchStatus.Success
		end)
		if entry.icon.Image ~= image or entry.captioned then
			return -- changed meanwhile, or the word already shows under the icon
		end
		entry.icon.Visible = ok
		entry.label.Position = UDim2.fromScale(0.5, 0.5)
		entry.label.Size = UDim2.fromScale(0.8, 0.26)
		entry.label.Visible = not ok
	end)
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
	entry.captioned = true
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
	-- inner ring: clear of the jump button, and wide enough that buttons 45° apart don't touch (phones: the small
	-- jump button left DASH / POUND / GRAB overlapping)
	local radius = { math.max(jumpSize / 2 + gap + size / 2, (size + gap) / (2 * math.sin(math.rad(22.5)))) }
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
-- Drag-to-aim on a touch button (Brawl Stars): `aim()` gives (reach, ring radius) for the current kit, or nil when
-- this button doesn't drag right now; `done(cast)` runs on let go (cast = false when the button hid mid-drag).
local function bindDrag(entry: Button, aim: () -> (number?, number?, boolean?), done: (cast: boolean) -> ())
	local held: InputObject? = nil
	local start = Vector2.zero
	local function finish(cast: boolean)
		held = nil
		entry.icon.Position = UDim2.fromScale(0.5, 0.5)
		done(cast)
	end
	entry.button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch or held then
			return
		end
		local reach, radius, line = aim()
		if not reach then
			return
		end
		held = input
		start = Vector2.new(input.Position.X, input.Position.Y)
		TopDownAim.Drag(Vector2.zero, reach, radius, line)
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

-- Kai's castle tools drag too: FIRE steers the auto-fire while held, WALL is placed where you let go
local function fireMage(): boolean
	return player:GetAttribute("Kit") == "FireMage" and player:GetAttribute("CameraMode") == "TopDown"
end

local function bindUltDrag(entry: Button)
	bindDrag(entry, function()
		if player:GetAttribute("Kit") == "ShieldKnight" then
			local rally = Tuning.ShieldKnight.Rally
			return rally.LeapReach, rally.Radius, false
		end
		return Tuning.Touch.UltReach, Tuning.FireMage.Meteor.Radius, false
	end, function(cast)
		if cast then
			TopDownAim.ReleaseUlt()
		else
			TopDownAim.Drag(nil)
		end
	end)
end

local function bindToolDrags()
	bindDrag(buttons.Tool1, function()
		if fireMage() then
			return Tuning.Touch.FireReach, 1.5, false
		end
		return nil, nil, nil
	end, function()
		TopDownAim.Drag(nil) -- the fire loop stops with the button's release
	end)
	bindDrag(buttons.Tool2, function()
		if fireMage() then
			return Tuning.Touch.WallReach, Tuning.FireMage.FlameWall.Length / 2, true -- a line, like the wall
		end
		return nil, nil, nil
	end, function(cast)
		if cast then
			TopDownAim.ReleaseTool("Wall")
		else
			TopDownAim.Drag(nil)
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
	bindToolDrags()
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

	-- /diag (admin): report how the touch icons loaded on this device, in chat + the console (phones have no Studio)
	Net.event("AdminDiag").OnClientEvent:Connect(function()
		local StarterGui = game:GetService("StarterGui")
		local lines = {
			`[diag] device {Glyphs.device()} quality {UserSettings().GameSettings.SavedQualityLevel.Name} queue {ContentProvider.RequestQueueSize}`,
		}
		for name, entry in buttons do
			local icon = entry.icon
			local id = (icon.Image:match("%d+$") or icon.Image):sub(-5)
			local fetch = ContentProvider:GetAssetFetchStatus(icon.Image).Name
			local px = math.floor(icon.AbsoluteSize.X)
			table.insert(lines, `[diag] {name} vis {entry.button.Visible} loaded {icon.IsLoaded} {fetch} {px}px ..{id}`)
		end
		-- upload-path check: Studio MCP uploads ("Assistant_*") vs Studio importer images ("image"); counts by status
		local samples = {
			MCP = { 100311078346030, 100676855591730, 102235581488980, 103524685353613, 104229021377242 },
			Import = { 100041832780715, 100488548637171, 100885623527464, 102012553599365, 102454777643168 },
			Oct11 = { 99838830000219, 70739552910543, 96128480844430, 126720728128289, 82745210768012 },
			Oct17 = { 111841740424601, 109193362496507, 124834076029614, 129855379396466, 103293551589754 },
		}
		for group, ids in samples do
			local probes = {}
			for _, id in ids do
				local probe = Instance.new("ImageLabel")
				probe.Image = `rbxassetid://{id}`
				table.insert(probes, probe)
			end
			local counts: { [string]: number } = {}
			ContentProvider:PreloadAsync(probes, function(_, status)
				counts[status.Name] = (counts[status.Name] or 0) + 1
			end)
			local parts = {}
			for status, n in counts do
				table.insert(parts, `{status} {n}`)
			end
			table.insert(lines, `[diag] {group} images: {table.concat(parts, ", ")}`)
		end
		for _, text in lines do
			print(text)
			local channels = game:GetService("TextChatService"):FindFirstChild("TextChannels")
			local general = channels and channels:FindFirstChild("RBXGeneral") :: TextChannel?
			if general then
				general:DisplaySystemMessage(text)
			else
				pcall(StarterGui.SetCore, StarterGui, "ChatMakeSystemMessage", { Text = text })
			end
		end
	end)
end

return TouchController
