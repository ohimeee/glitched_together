-- HUD (mechanics.md §6): hearts/HP, tool card, crosshair, Pip hint bubble, GAME OVER? /
-- partner-wait overlays, and on-screen buttons for mobile. Every panel is a themed sticker (UiTheme via UiSkin):
-- it re-skins per world (FredokaOne menu → Arcade pixel → Fantasy storybook → Code grey), art-direction.md §11.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Net = require(ReplicatedStorage.Shared.Net)
local Roles = require(ReplicatedStorage.Shared.Config.Roles)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local UiSkin = require(ReplicatedStorage.Shared.Util.UiSkin)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)
local Input = require(script.Parent.Parent.Input)
local Aim = require(script.Parent.Parent.Aim)
local CardReveal = require(script.Parent.Parent.CardReveal)

local player = Players.LocalPlayer

local HUDController = {}

-- Hearts keep one round font in every world (the ♥ glyph is missing from the pixel/code fonts).
local HEART_FONT = Enum.Font.FredokaOne
local HEART_FULL = Color3.fromRGB(255, 95, 162) -- Pip pink: health, not a gameplay color
local HINT_CPS = 45 -- Pip's typewriter speed, characters per second

local TOOL_TEXT: { [string]: { any } } = {
	PauseBeam = { "PAUSE BEAM", { "LMB", "Freeze" }, { "RMB", "Release" } },
	GrappleLine = { "GRAPPLE LINE", { "LMB", "Swing" }, { "RMB", "Pull" } },
	FireMage = { "FIRE MAGE", { "LMB", "Fireball   E Ignite" }, { "RMB", "Flame Wall   Shift Blink" } },
	ShieldKnight = { "SHIELD KNIGHT", { "LMB", "Sword" }, { "RMB", "Block   Shift Charge" } },
	CopyPaste = { "COPY / PASTE", { "LMB", "Copy" }, { "RMB", "Paste   R Rotate" } },
	LayerShift = { "LAYER SHIFT", { "LMB", "Shift" }, { "RMB", "Pull Out" } },
}

local gui: ScreenGui

local function new(className: string, props: { [string]: any }, parent: Instance?): any
	local inst = Instance.new(className)
	for k, v in props do
		(inst :: any)[k] = v
	end
	inst.Parent = parent
	return inst
end

local function text(props: { [string]: any }, parent: Instance?, kind: UiSkin.TextKind?, color: Color3?): TextLabel
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	local label = new("TextLabel", props, parent)
	UiSkin.Text(label, kind or "Body", color)
	return label
end

local function corner(parent: Instance, radius: number)
	new("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function roleColor(p: Player): Color3
	local info = (Roles :: any)[p:GetAttribute("Role") or ""]
	return if info then info.Color else Palette.Duo
end

-- Health: a sticker chip with hearts (platforming) or an HP bar (castle) -----------------------
local function buildHealth()
	local chip = new("Frame", {
		Name = "Health",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 20, 1, -20),
		Size = UDim2.fromOffset(170, 52),
		ZIndex = 2,
	}, gui)
	UiSkin.Panel(chip)
	new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }, chip)
	local hearts = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3 }, chip)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 4),
	}, hearts)

	local hpBack = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 6),
		Size = UDim2.new(1, 0, 0, 12),
		BackgroundColor3 = Color3.fromRGB(20, 20, 35),
		Visible = false,
		ZIndex = 3,
	}, chip)
	corner(hpBack, 6)
	local hpFill = new("Frame", { Size = UDim2.fromScale(1, 1), ZIndex = 4 }, hpBack)
	corner(hpFill, 6)
	local hpLabel = text({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 0, -1),
		Size = UDim2.new(1, 0, 0, 16),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}, hpBack, "Title")

	local heartLabels: { TextLabel } = {}
	local function refresh()
		local kind = player:GetAttribute("HealthKind")
		local health = (player:GetAttribute("Health") or 0) :: number
		local max = (player:GetAttribute("MaxHealth") or 3) :: number
		local theme = UiSkin.Theme()
		if kind == "HP" then
			hearts.Visible = false
			hpBack.Visible = true
			chip.Size = UDim2.fromOffset(220, 52)
			hpFill.Size = UDim2.fromScale(math.clamp(health / math.max(max, 1), 0, 1), 1)
			hpFill.BackgroundColor3 = roleColor(player)
			hpLabel.Text = `HP {math.floor(health)} / {max}`
			return
		end
		hearts.Visible = true
		hpBack.Visible = false
		chip.Size = UDim2.fromOffset(24 + max * 38, 52)
		for i = 1, math.max(max, #heartLabels) do
			local h = heartLabels[i]
			if not h and i <= max then
				h = new("TextLabel", {
					Size = UDim2.fromOffset(34, 40),
					BackgroundTransparency = 1,
					Font = HEART_FONT,
					TextScaled = true,
					Text = "♥",
					ZIndex = 3,
				}, hearts)
				heartLabels[i] = h
			end
			if h then
				h.Visible = i <= max
				h.TextColor3 = if i <= health then HEART_FULL else theme.SubInk
				h.TextTransparency = if i <= health then 0 else 0.35
			end
		end
	end
	for _, attr in { "Health", "MaxHealth", "HealthKind" } do
		player:GetAttributeChangedSignal(attr):Connect(refresh)
	end
	UiSkin.OnTheme(refresh)

	-- a quick bump when you lose a heart
	local last = (player:GetAttribute("Health") or 0) :: number
	player:GetAttributeChangedSignal("Health"):Connect(function()
		local now = (player:GetAttribute("Health") or 0) :: number
		if now < last then
			chip.Rotation = -4
			TweenService:Create(chip, TweenInfo.new(0.35, Enum.EasingStyle.Elastic), { Rotation = 0 }):Play()
		end
		last = now
	end)
end

-- Tool card + crosshair -----------------------------------------------------------------------
local function keyRow(parent: Instance, order: number): (TextLabel, TextLabel)
	local row = new("Frame", {
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		ZIndex = 3,
	}, parent)
	local key = new("TextLabel", {
		Size = UDim2.fromOffset(48, 24),
		TextScaled = true,
		ZIndex = 4,
	}, row)
	UiSkin.Panel(key, { NoShadow = true })
	UiSkin.Text(key, "Title")
	new("UIPadding", { PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3) }, key)
	local action = text({
		Position = UDim2.fromOffset(58, 0),
		Size = UDim2.new(1, -58, 1, 0),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}, row, "Body")
	return key, action
end

local function buildTools()
	local card = new("Frame", {
		Name = "Tools",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.fromOffset(270, 112),
		Visible = false,
		ZIndex = 2,
	}, gui)
	UiSkin.Panel(card)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 12),
		PaddingTop = UDim.new(0, 8),
	}, card)
	new("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, card)
	local title = text({
		Size = UDim2.new(1, 0, 0, 30),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 0,
		ZIndex = 3,
	}, card, "Title")
	local key1, use1 = keyRow(card, 1)
	local key2, use2 = keyRow(card, 2)

	local crosshair = text({
		Name = "Crosshair",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(28, 28),
		Text = "+",
		TextScaled = true,
		Visible = false,
	}, gui, "Float")

	local function refresh()
		local kit = player:GetAttribute("Kit")
		local info = kit and TOOL_TEXT[kit]
		card.Visible = info ~= nil
		crosshair.Visible = info ~= nil and player:GetAttribute("CameraMode") ~= "TopDown"
		if info then
			title.Text = info[1]
			UiSkin.SetTextColor(title, roleColor(player)) -- your tool, your color (§6, §11)
			key1.Text, use1.Text = info[2][1], info[2][2]
			key2.Text, use2.Text = info[3][1], info[3][2]
		end
	end
	-- the crosshair sits in the middle while the camera has the cursor locked, else it rides the cursor / touch
	-- (and stands in for the mouse icon, which CameraController hides while a tool is out)
	RunService.RenderStepped:Connect(function()
		if crosshair.Visible then
			local point = Aim.screenPoint()
			crosshair.Position = UDim2.fromOffset(point.X, point.Y)
		end
	end)
	player:GetAttributeChangedSignal("Kit"):Connect(refresh)
	player:GetAttributeChangedSignal("CameraMode"):Connect(refresh)
	player:GetAttributeChangedSignal("Role"):Connect(refresh)
	refresh()
end

-- Pip hint bubble: a speech sticker with a "PIP" tab, a tail, and typewriter text --------------
local function buildHint()
	local bubble = new("Frame", {
		Name = "Hint",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 34),
		Size = UDim2.fromOffset(560, 78),
		Visible = false,
		ZIndex = 6,
	}, gui)
	local tail = new("Frame", {
		Name = "Tail",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 70, 1, 0),
		Size = UDim2.fromOffset(20, 20),
		Rotation = 45,
		ZIndex = 5,
	}, bubble)
	UiSkin.Panel(bubble)
	UiSkin.Panel(tail, { NoShadow = true })
	local tab = new("TextLabel", {
		Name = "Tab",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromOffset(18, 0),
		Size = UDim2.fromOffset(70, 26),
		Text = "PIP",
		TextScaled = true,
		ZIndex = 8,
	}, bubble)
	new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }, tab)
	local label = text({
		Size = UDim2.new(1, -32, 1, -24),
		Position = UDim2.fromOffset(16, 16),
		TextScaled = true,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 7,
	}, bubble, "Body")
	UiSkin.OnTheme(function(theme)
		UiSkin.Panel(tab, { NoShadow = true, Fill = theme.Accent })
		UiSkin.Text(tab, "Title", UiSkin.InkOn(theme.Accent))
	end)

	local shownAt = 0
	Net.event("Hint").OnClientEvent:Connect(function(line: string)
		local stamp = os.clock()
		shownAt = stamp
		label.Text = line
		label.MaxVisibleGraphemes = 0
		bubble.Visible = true
		Audio.play("PipChirp")
		bubble.Size = UDim2.fromOffset(520, 70)
		TweenService:Create(bubble, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
			Size = UDim2.fromOffset(560, 78),
		}):Play()
		task.spawn(function()
			local total = utf8.len(line) or #line
			local shown = 0
			while shown < total and shownAt == stamp do
				shown += 1
				label.MaxVisibleGraphemes = shown
				if shown % 3 == 1 then
					Audio.play("PipBleep") -- Pip talks in bleeps (design.md §8)
				end
				task.wait(1 / HINT_CPS)
			end
			label.MaxVisibleGraphemes = -1
		end)
		task.delay(Tuning.Pip.HintTime, function()
			if shownAt == stamp then
				bubble.Visible = false
			end
		end)
	end)
end

-- Overlays: GAME OVER?, falling fade, partner waiting (the Downed respawn meter: ReviveController) -------------
local function buildOverlays()
	local fade = new("Frame", {
		Name = "Fade",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 50,
	}, gui)

	-- The Glitch's screen: always magenta static, never themed (art-direction.md §7).
	local gameOver = new("TextLabel", {
		Name = "GameOver",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(20, 0, 30),
		BackgroundTransparency = 0,
		Font = Enum.Font.Arcade,
		Text = "GAME OVER?",
		TextSize = 110,
		TextColor3 = Palette.Glitch,
		TextStrokeTransparency = 1,
		Visible = false,
		ZIndex = 60,
	}, gui)

	local waiting = text({
		Name = "PartnerWait",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(10, 10, 25),
		BackgroundTransparency = 0.25,
		TextSize = 40,
		Visible = false,
		ZIndex = 40,
	}, gui, "Float")

	RunService.RenderStepped:Connect(function()
		local now = workspace:GetServerTimeNow()
		local waitUntil = player:GetAttribute("PartnerWaitUntil") :: number?
		if waitUntil then
			waiting.Visible = true
			waiting.Text = `Waiting for your partner… (reconnect)\n{math.ceil(math.max(0, waitUntil - now))}s`
		else
			waiting.Visible = false
		end
	end)

	player:GetAttributeChangedSignal("Falling"):Connect(function()
		local falling = player:GetAttribute("Falling") == true
		TweenService:Create(fade, TweenInfo.new(if falling then 1.2 else 0.3), {
			BackgroundTransparency = if falling then 0 else 1,
		}):Play()
	end)

	Net.event("GameOver").OnClientEvent:Connect(function()
		gameOver.Visible = true
		for _ = 1, 8 do -- glitch flicker: hard jumps, RGB split colors
			gameOver.Position = UDim2.fromOffset(math.random(-12, 12), math.random(-8, 8))
			gameOver.TextColor3 = if math.random() < 0.5 then Palette.Glitch else Palette.GlitchCyan
			task.wait(0.08)
		end
		gameOver.Position = UDim2.fromOffset(0, 0)
		task.wait(0.9)
		gameOver.Visible = false
	end)
end

-- Mobile buttons ---------------------------------------------------------------------------
local function buildTouch()
	if not UserInputService.TouchEnabled then
		return
	end
	local layout = {
		{ "BaseContext", "Dash", "DASH", UDim2.new(1, -250, 1, -110) },
		{ "BaseContext", "GroundPound", "POUND", UDim2.new(1, -250, 1, -190) },
		{ "BaseContext", "Swing", "GRAB", UDim2.new(1, -330, 1, -150) },
		{ "BaseContext", "Ping", "PING", UDim2.new(1, -90, 0, 120) },
		{ "BaseContext", "Peek", "PEEK", UDim2.new(1, -90, 0, 190) },
		{ "W1Tools", "Tool1", "TOOL 1", UDim2.new(1, -170, 1, -260) },
		{ "W1Tools", "Tool2", "TOOL 2", UDim2.new(1, -90, 1, -260) },
	}
	for _, b in layout do
		local button = new("TextButton", {
			Name = b[2],
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = b[4],
			Size = UDim2.fromOffset(70, 70),
			TextScaled = true,
			Text = b[3],
			AutoButtonColor = true,
			ZIndex = 3,
		}, gui)
		UiSkin.Panel(button)
		UiSkin.Text(button, "Title")
		new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, button)
		Input.bindButton(b[1], b[2], button)
		-- Tool buttons serve every world's tool context.
		if b[1] == "W1Tools" then
			Input.bindButton("CastleTools", b[2], button)
			Input.bindButton("W3Tools", b[2], button)
		end
	end
end

-- Castle: XP bar, ultimate meter, level-up picker, HP bars over heads (mechanics.md §6) ---------------------
local UPGRADE_TEXT: { [string]: { string } } = {
	BiggerFireball = { "BIGGER FIREBALL", "Fireballs are 50% bigger and hit 25% harder" },
	FasterCast = { "FASTER CAST", "A fireball every 0.25 s" },
	DoubleFlameWall = { "DOUBLE FLAME WALL", "Two walls at once" },
	EmberTrail = { "EMBER TRAIL", "Blink leaves fire behind" },
	WiderBlock = { "WIDER BLOCK", "Shield covers 160°" },
	LongerCharge = { "LONGER CHARGE", "Charge 22 studs" },
	ReflectBoost = { "REFLECT BOOST", "Reflected shots deal x2" },
	SecondWind = { "SECOND WIND", "+40 HP, Rally heals 20" },
}

local function isCastle(): boolean
	local kit = player:GetAttribute("Kit")
	return kit == "FireMage" or kit == "ShieldKnight"
end

local function buildXpAndUltimate()
	local xpBack = new("Frame", {
		Name = "XP",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -22),
		Size = UDim2.fromOffset(380, 18),
		Visible = false,
		ZIndex = 2,
	}, gui)
	UiSkin.Panel(xpBack)
	local xpFill = new("Frame", { Size = UDim2.fromScale(0, 1), ZIndex = 3 }, xpBack)
	local xpCorner = new("UICorner", {}, xpFill)
	local levelLabel = text({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -6),
		Size = UDim2.fromOffset(260, 24),
		TextSize = 22,
		ZIndex = 3,
	}, xpBack, "Float")

	local ultBack = new("Frame", {
		Name = "Ultimate",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -150),
		Size = UDim2.fromOffset(270, 20),
		Visible = false,
		ZIndex = 2,
	}, gui)
	UiSkin.Panel(ultBack)
	local ultFill = new("Frame", { Size = UDim2.fromScale(0, 1), ZIndex = 3 }, ultBack)
	local ultCorner = new("UICorner", {}, ultFill)
	local ultLabel = text({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 0, -6),
		Size = UDim2.fromOffset(270, 22),
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 3,
	}, ultBack, "Float")
	UiSkin.OnTheme(function(theme)
		xpFill.BackgroundColor3 = theme.Accent
		xpCorner.CornerRadius = UDim.new(0, theme.Corner)
		ultCorner.CornerRadius = UDim.new(0, theme.Corner)
	end)

	local function refresh()
		local show = isCastle()
		xpBack.Visible = show
		ultBack.Visible = show
		if not show then
			return
		end
		local xp = (player:GetAttribute("XP") or 0) :: number
		local level = (player:GetAttribute("Level") or 1) :: number
		local levels = Tuning.XpLevels
		local lo = if level > 1 then levels[level - 1] else 0
		local hi = levels[level]
		xpFill.Size = UDim2.fromScale(if hi then math.clamp((xp - lo) / (hi - lo), 0, 1) else 1, 1)
		levelLabel.Text = if hi then `LV {level}   {xp} / {hi} XP` else `LV {level}  MAX`
		local ult = (player:GetAttribute("Ultimate") or 0) :: number
		ultFill.Size = UDim2.fromScale(math.clamp(ult, 0, 1), 1)
		ultFill.BackgroundColor3 = roleColor(player)
		local name = if player:GetAttribute("Kit") == "FireMage" then "METEOR" else "RALLY"
		ultLabel.Text = if ult >= 1 then `{name} READY!  LMB + RMB` else name
	end
	for _, attr in { "Kit", "XP", "Level", "Ultimate", "Role" } do
		player:GetAttributeChangedSignal(attr):Connect(refresh)
	end
	refresh()
end

-- big glyphs for the reveal cards' art windows
local UPGRADE_ICON: { [string]: string } = {
	BiggerFireball = "🔥",
	FasterCast = "⚡",
	DoubleFlameWall = "🧱",
	EmberTrail = "✨",
	WiderBlock = "🛡️",
	LongerCharge = "💨",
	ReflectBoost = "🔁",
	SecondWind = "💖",
}

-- Level-up picker: TikTok-style card reveal (CardReveal; memory card-reveal-ui): two sealed cards drop in and flip
-- open, the player picks one. The world is paused server side while anyone picks (XpService).
local function buildPicker()
	local waiting = text({
		Name = "PickWaiting",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 110),
		Size = UDim2.fromOffset(500, 40),
		TextSize = 28,
		Text = "Waiting for your partner to pick...",
		Visible = false,
		ZIndex = 30,
	}, gui, "Float")
	local close: (() -> ())? = nil
	local function refreshWaiting()
		waiting.Visible = player:GetAttribute("Picking") == true and close == nil
	end
	local pickEvent = Net.event("LevelPick")
	Net.event("LevelUp").OnClientEvent:Connect(function(level: number, options: { string })
		if close then
			close()
		end
		local cards = {}
		for _, name in options do
			local info = UPGRADE_TEXT[name] or { name, "" }
			table.insert(cards, {
				id = name,
				name = info[1],
				desc = info[2],
				icon = UPGRADE_ICON[name] or "★",
				ribbon = `LV {level}`,
				stars = level,
			})
		end
		Audio.play("LevelUp")
		close = CardReveal.Show(gui, {
			title = `LEVEL {level}!  PICK ONE`,
			accent = roleColor(player),
			back = Palette.Castle.NightPurple,
			gold = Palette.Castle.Gold,
			cards = cards,
			zIndex = 40,
			onPick = function(id)
				close = nil
				pickEvent:FireServer(id)
				refreshWaiting()
			end,
		})
		refreshWaiting()
	end)
	player:GetAttributeChangedSignal("Picking"):Connect(function()
		if not player:GetAttribute("Picking") and close then
			close() -- auto-picked by the server (30 s)
			close = nil
		end
		refreshWaiting()
	end)
end

local function buildOverheadBars()
	local bars: { [Player]: BillboardGui } = {}
	local function barFor(p: Player)
		local bill = new("BillboardGui", {
			Name = "HPOver",
			-- sized in studs, not pixels: it keeps its size next to the character in any window (2P playtest Oct 11:
			-- the pixel bars looked huge in small windows, piling up when both rode the cart)
			Size = UDim2.fromScale(Tuning.OverheadBar.X, Tuning.OverheadBar.Y),
			StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0),
			AlwaysOnTop = true,
			LightInfluence = 0,
			Enabled = false,
		}, gui)
		local back = new(
			"Frame",
			{ Name = "Back", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(20, 20, 35) },
			bill
		)
		corner(back, 5)
		new("UIStroke", { Thickness = 2, Color = Palette.Castle.Gold }, back)
		local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1) }, back)
		corner(fill, 5)
		bars[p] = bill
	end
	for _, p in Players:GetPlayers() do
		barFor(p)
	end
	Players.PlayerAdded:Connect(barFor)
	Players.PlayerRemoving:Connect(function(p)
		if bars[p] then
			bars[p]:Destroy()
			bars[p] = nil
		end
	end)
	RunService.RenderStepped:Connect(function()
		for p, bill in bars do
			local head = p.Character and p.Character:FindFirstChild("Head")
			bill.Enabled = p:GetAttribute("HealthKind") == "HP" and head ~= nil and not p:GetAttribute("Downed")
			if bill.Enabled then
				bill.Adornee = head :: BasePart
				local health = (p:GetAttribute("Health") or 0) :: number
				local max = math.max(1, (p:GetAttribute("MaxHealth") or 100) :: number)
				local fill = (bill :: any).Back.Fill :: Frame
				fill.Size = UDim2.fromScale(math.clamp(health / max, 0, 1), 1)
				fill.BackgroundColor3 = roleColor(p)
			end
		end
	end)
end

local function buildCastle()
	buildXpAndUltimate()
	buildPicker()
	buildOverheadBars()
end

-- Boss bar (top center): the boss's name, a health bar and the phase, while workspace.BossName is set ---------
local function buildBoss()
	local panel = new("Frame", {
		Name = "Boss",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 18),
		Size = UDim2.fromOffset(460, 62),
		Visible = false,
		ZIndex = 2,
	}, gui)
	UiSkin.Panel(panel)
	local name = text({
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.new(1, -28, 0, 22),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 3,
	}, panel, "Title")
	local phase = text({
		Position = UDim2.fromOffset(14, 6),
		Size = UDim2.new(1, -28, 0, 18),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Right,
		ZIndex = 3,
	}, panel, "Body")
	local back = new("Frame", {
		Position = UDim2.new(0, 14, 0, 34),
		Size = UDim2.new(1, -28, 0, 16),
		BackgroundColor3 = Color3.fromRGB(20, 20, 35),
		ZIndex = 3,
	}, panel)
	corner(back, 8)
	local fill = new("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Palette.Glitch, -- he's made of the Glitch
		ZIndex = 4,
	}, back)
	corner(fill, 8)

	local function refresh()
		local boss = workspace:GetAttribute("BossName")
		panel.Visible = boss ~= nil
		if not boss then
			return
		end
		name.Text = boss
		phase.Text = string.upper((workspace:GetAttribute("BossPhaseName") or "") :: string)
		local health = math.clamp((workspace:GetAttribute("BossHealth") or 1) :: number, 0, 1)
		TweenService:Create(fill, TweenInfo.new(0.35), { Size = UDim2.fromScale(health, 1) }):Play()
	end
	for _, attr in { "BossName", "BossHealth", "BossPhaseName" } do
		workspace:GetAttributeChangedSignal(attr):Connect(refresh)
	end
	refresh()
end

function HUDController.Init()
	gui = new(
		"ScreenGui",
		-- Global z-order: sticker shadows and the hint tail sit behind their panels by ZIndex
		{ Name = "HUD", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Global },
		player:WaitForChild("PlayerGui")
	)
	buildHealth()
	buildTools()
	buildHint()
	buildOverlays()
	buildTouch()
	buildCastle()
	buildBoss()
end

function HUDController.Gui(): ScreenGui
	return gui
end

return HUDController
