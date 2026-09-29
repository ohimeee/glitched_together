-- HUD (mechanics.md §6): hearts/HP, tool labels, crosshair, Pip hint bubble, Downed / GAME OVER? /
-- partner-wait overlays, and on-screen buttons for mobile.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Net = require(ReplicatedStorage.Shared.Net)
local Roles = require(ReplicatedStorage.Shared.Config.Roles)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Input = require(script.Parent.Parent.Input)

local player = Players.LocalPlayer

local HUDController = {}

local FONT = Enum.Font.FredokaOne

local TOOL_TEXT: { [string]: { string } } = {
	PauseBeam = { "PAUSE BEAM", "LMB  Freeze", "RMB  Release" },
	GrappleLine = { "GRAPPLE LINE", "LMB  Swing", "RMB  Pull" },
	FireMage = { "FIRE MAGE", "LMB  Fireball   E  Ignite", "RMB  Flame Wall   Shift  Blink" },
	ShieldKnight = { "SHIELD KNIGHT", "LMB  Sword", "RMB  Block   Shift  Charge" },
	CopyPaste = { "COPY / PASTE", "LMB  Copy", "RMB  Paste (R rotate)" },
	LayerShift = { "LAYER SHIFT", "LMB  Shift", "RMB  Pull Out" },
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

local function text(props: { [string]: any }, parent: Instance?): TextLabel
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = FONT
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	props.TextStrokeTransparency = props.TextStrokeTransparency or 0.5
	return new("TextLabel", props, parent)
end

local function corner(parent: Instance, radius: number)
	new("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

-- Health ------------------------------------------------------------------------------
local function buildHealth()
	local frame = new("Frame", {
		Name = "Health",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 20, 1, -20),
		Size = UDim2.fromOffset(260, 44),
		BackgroundTransparency = 1,
	}, gui)
	local label =
		text({ Size = UDim2.fromScale(1, 1), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left }, frame)

	local function refresh()
		local kind = player:GetAttribute("HealthKind")
		local health = (player:GetAttribute("Health") or 0) :: number
		local max = (player:GetAttribute("MaxHealth") or 3) :: number
		if kind == "HP" then
			label.Text = `HP {math.floor(health)} / {max}`
		else
			label.Text = string.rep("♥ ", health) .. string.rep("♡ ", math.max(0, max - health))
		end
		label.TextColor3 = if health <= 1 and kind ~= "HP" then Color3.fromRGB(255, 90, 90) else Color3.new(1, 1, 1)
	end
	for _, attr in { "Health", "MaxHealth", "HealthKind" } do
		player:GetAttributeChangedSignal(attr):Connect(refresh)
	end
	refresh()
end

-- Tools + crosshair ---------------------------------------------------------------------
local function buildTools()
	local frame = new("Frame", {
		Name = "Tools",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -20, 1, -20),
		Size = UDim2.fromOffset(240, 96),
		BackgroundColor3 = Color3.fromRGB(15, 15, 30),
		BackgroundTransparency = 0.35,
		Visible = false,
	}, gui)
	corner(frame, 12)
	new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingTop = UDim.new(0, 8) }, frame)
	new("UIListLayout", { Padding = UDim.new(0, 2) }, frame)
	local title =
		text({ Size = UDim2.new(1, 0, 0, 30), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left }, frame)
	local use1 =
		text({ Size = UDim2.new(1, 0, 0, 22), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left }, frame)
	local use2 =
		text({ Size = UDim2.new(1, 0, 0, 22), TextScaled = true, TextXAlignment = Enum.TextXAlignment.Left }, frame)

	local crosshair = text({
		Name = "Crosshair",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(28, 28),
		Text = "+",
		TextScaled = true,
		Visible = false,
	}, gui)

	local function refresh()
		local kit = player:GetAttribute("Kit")
		local info = kit and TOOL_TEXT[kit]
		frame.Visible = info ~= nil
		crosshair.Visible = info ~= nil and player:GetAttribute("CameraMode") ~= "TopDown"
		if info then
			local role = (Roles :: any)[player:GetAttribute("Role") or "Kai"]
			title.Text = info[1]
			title.TextColor3 = role.Color
			use1.Text = info[2]
			use2.Text = info[3]
		end
	end
	player:GetAttributeChangedSignal("Kit"):Connect(refresh)
	player:GetAttributeChangedSignal("CameraMode"):Connect(refresh)
	refresh()
end

-- Pip hint bubble -----------------------------------------------------------------------
local function buildHint()
	local bubble = new("Frame", {
		Name = "Hint",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 24),
		Size = UDim2.fromOffset(520, 70),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Visible = false,
	}, gui)
	corner(bubble, 16)
	local label = text({
		Size = UDim2.new(1, -24, 1, -12),
		Position = UDim2.fromOffset(12, 6),
		TextScaled = true,
		TextColor3 = Color3.fromRGB(30, 30, 60),
		TextStrokeTransparency = 1,
	}, bubble)
	local shownAt = 0
	Net.event("Hint").OnClientEvent:Connect(function(line: string)
		label.Text = "PIP: " .. line
		bubble.Visible = true
		local stamp = os.clock()
		shownAt = stamp
		task.delay(6, function()
			if shownAt == stamp then
				bubble.Visible = false
			end
		end)
	end)
end

-- Overlays: Downed, GAME OVER?, falling fade, partner waiting ---------------------------------
local function buildOverlays()
	local downed = text({
		Name = "Downed",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.7),
		Size = UDim2.fromOffset(560, 60),
		TextScaled = true,
		Visible = false,
	}, gui)

	local fade = new("Frame", {
		Name = "Fade",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = 50,
	}, gui)

	local gameOver = text({
		Name = "GameOver",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(20, 0, 30),
		BackgroundTransparency = 0,
		Text = "GAME OVER?",
		TextScaled = false,
		TextSize = 96,
		TextColor3 = Palette.Glitch,
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
	}, gui)

	RunService.RenderStepped:Connect(function()
		local now = workspace:GetServerTimeNow()
		if player:GetAttribute("Downed") then
			downed.Visible = true
			local at = player:GetAttribute("RespawnAt") :: number?
			local left = if at then math.max(0, at - now) else 0
			local mash = if workspace:GetAttribute("BossFight") then "  (mash JUMP!)" else ""
			downed.Text = `DOWNED — partner can revive (E)  ·  {string.format("%.1f", left)}s{mash}`
		else
			downed.Visible = false
		end

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
		for _ = 1, 8 do -- glitch flicker
			gameOver.Position = UDim2.fromOffset(math.random(-12, 12), math.random(-8, 8))
			gameOver.TextColor3 = if math.random() < 0.5 then Palette.Glitch else Color3.fromRGB(60, 255, 120)
			task.wait(0.08)
		end
		gameOver.Position = UDim2.fromOffset(0, 0)
		task.wait(0.9)
		gameOver.Visible = false
	end)
end

-- Your own revive prompt is only for your partner.
local function hideOwnRevivePrompt()
	local function watch(character: Model)
		local root = character:WaitForChild("HumanoidRootPart")
		root.ChildAdded:Connect(function(child)
			if child:IsA("ProximityPrompt") and child.Name == "RevivePrompt" then
				child.Enabled = false
			end
		end)
	end
	if player.Character then
		task.spawn(watch, player.Character)
	end
	player.CharacterAdded:Connect(watch)
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
			BackgroundColor3 = Color3.fromRGB(20, 20, 40),
			BackgroundTransparency = 0.3,
			Font = FONT,
			TextScaled = true,
			TextColor3 = Color3.new(1, 1, 1),
			Text = b[3],
		}, gui)
		corner(button, 35)
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
	BiggerFireball = { "BIGGER FIREBALL", "Fireballs are 50% bigger" },
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

local function roleColor(p: Player): Color3
	local info = (Roles :: any)[p:GetAttribute("Role") or ""]
	return if info then info.Color else Palette.Duo
end

local function buildXpAndUltimate()
	local xpBack = new("Frame", {
		Name = "XP",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -18),
		Size = UDim2.fromOffset(360, 14),
		BackgroundColor3 = Color3.fromRGB(20, 20, 35),
		Visible = false,
	}, gui)
	corner(xpBack, 7)
	local xpFill =
		new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.fromRGB(60, 255, 120) }, xpBack)
	corner(xpFill, 7)
	local levelLabel = text({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0, -2),
		Size = UDim2.fromOffset(240, 22),
		TextSize = 20,
	}, xpBack)

	local ultBack = new("Frame", {
		Name = "Ultimate",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -18, 1, -120),
		Size = UDim2.fromOffset(240, 18),
		BackgroundColor3 = Color3.fromRGB(20, 20, 35),
		Visible = false,
	}, gui)
	corner(ultBack, 9)
	local ultFill = new("Frame", { Size = UDim2.fromScale(0, 1) }, ultBack)
	corner(ultFill, 9)
	local ultLabel = text({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 0, -2),
		Size = UDim2.fromOffset(240, 22),
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, ultBack)

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

local function buildPicker()
	local picker = new("Frame", {
		Name = "LevelUp",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(560, 250),
		BackgroundColor3 = Palette.Castle.NightPurple,
		Visible = false,
		ZIndex = 30,
	}, gui)
	corner(picker, 18)
	new("UIStroke", { Thickness = 4, Color = Palette.Castle.Gold }, picker)
	local title =
		text({ Size = UDim2.new(1, 0, 0, 60), TextSize = 40, ZIndex = 31, TextColor3 = Palette.Castle.Gold }, picker)
	local waiting = text({
		Name = "PickWaiting",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 110),
		Size = UDim2.fromOffset(500, 40),
		TextSize = 26,
		Text = "Waiting for your partner to pick...",
		Visible = false,
		ZIndex = 30,
	}, gui)
	local buttons: { TextButton } = {}
	for i = 1, 2 do
		local b = new("TextButton", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(if i == 1 then 0.27 else 0.73, 0, 0, 72),
			Size = UDim2.fromOffset(240, 150),
			BackgroundColor3 = Palette.Castle.Royal,
			Font = FONT,
			TextWrapped = true,
			TextSize = 22,
			TextColor3 = Color3.new(1, 1, 1),
			ZIndex = 31,
		}, picker)
		corner(b, 14)
		buttons[i] = b
	end

	local function refreshWaiting()
		waiting.Visible = player:GetAttribute("Picking") == true and not picker.Visible
	end
	local pickEvent = Net.event("LevelPick")
	Net.event("LevelUp").OnClientEvent:Connect(function(level: number, options: { string })
		title.Text = `LEVEL {level}!  PICK ONE`
		for i, b in buttons do
			local name = options[i]
			local info = UPGRADE_TEXT[name] or { name, "" }
			b.Text = info[1] .. "\n\n" .. info[2]
			b:SetAttribute("Choice", name)
		end
		picker.Visible = true
		refreshWaiting()
	end)
	for _, b in buttons do
		b.Activated:Connect(function()
			local choice = b:GetAttribute("Choice")
			if picker.Visible and choice then
				picker.Visible = false
				pickEvent:FireServer(choice)
				refreshWaiting()
			end
		end)
	end
	player:GetAttributeChangedSignal("Picking"):Connect(function()
		if not player:GetAttribute("Picking") then
			picker.Visible = false
		end
		refreshWaiting()
	end)
end

local function buildOverheadBars()
	local bars: { [Player]: BillboardGui } = {}
	local function barFor(p: Player)
		local bill = new("BillboardGui", {
			Name = "HPOver",
			Size = UDim2.fromOffset(70, 9),
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
		corner(back, 4)
		local fill = new("Frame", { Name = "Fill", Size = UDim2.fromScale(1, 1) }, back)
		corner(fill, 4)
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

function HUDController.Init()
	gui = new(
		"ScreenGui",
		{ Name = "HUD", ResetOnSpawn = false, IgnoreGuiInset = true },
		player:WaitForChild("PlayerGui")
	)
	buildHealth()
	buildTools()
	buildHint()
	buildOverlays()
	hideOwnRevivePrompt()
	buildTouch()
	buildCastle()
end

function HUDController.Gui(): ScreenGui
	return gui
end

return HUDController
