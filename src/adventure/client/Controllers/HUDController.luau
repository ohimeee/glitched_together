-- HUD (mechanics.md §6): hearts/HP, tool labels, crosshair, Pip hint bubble, Downed / GAME OVER? /
-- partner-wait overlays, and on-screen buttons for mobile.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Net = require(ReplicatedStorage.Shared.Net)
local Roles = require(ReplicatedStorage.Shared.Config.Roles)
local Input = require(script.Parent.Parent.Input)

local player = Players.LocalPlayer

local HUDController = {}

local FONT = Enum.Font.FredokaOne

local TOOL_TEXT: { [string]: { string } } = {
	PauseBeam = { "PAUSE BEAM", "LMB  Freeze", "RMB  Release" },
	GrappleLine = { "GRAPPLE LINE", "LMB  Swing", "RMB  Pull" },
	FireMage = { "FIRE MAGE", "LMB  Fireball", "RMB  Flame Wall" },
	ShieldKnight = { "SHIELD KNIGHT", "LMB  Sword", "RMB  Block" },
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
		TextColor3 = Color3.fromRGB(255, 80, 170),
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
			gameOver.TextColor3 = if math.random() < 0.5
				then Color3.fromRGB(255, 80, 170)
				else Color3.fromRGB(60, 255, 120)
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
end

function HUDController.Gui(): ScreenGui
	return gui
end

return HUDController
