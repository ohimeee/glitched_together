-- The end credits (Epilogue; Story Line "Continue" steps 5-6). The server fires the "Credits" remote after the
-- real-world ending cutscene: a night-blue screen, the credits (Config/Credits) scroll up, then the title card
-- "CONTINUE?" with one answer, YES. YES fades the screen away, leaves the duo free under the stars and tells the
-- server to open the BACK TO LOBBY exit on the hilltop ledge (Main).
-- Space / A / click / tap skips straight to the title card; on a gamepad YES is selected (A presses it). Under it sits a small, optional tip jar (Config/Products.Support,
-- server SupportService): "Enjoyed it? Support our next game", three Robux buttons, thank-you on purchase.
local AvatarEditorService = game:GetService("AvatarEditorService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Net = require(ReplicatedStorage.Shared.Net)
local Credits = require(ReplicatedStorage.Shared.Config.Credits)
local Places = require(ReplicatedStorage.Shared.Config.Places)
local Products = require(ReplicatedStorage.Shared.Config.Products)
local UiTheme = require(ReplicatedStorage.Shared.Config.UiTheme)
local Glyphs = require(ReplicatedStorage.Shared.Util.Glyphs)
local UiFit = require(ReplicatedStorage.Shared.Util.UiFit)

local CreditsController = {}

local player = Players.LocalPlayer
local SCROLL_SPEED = 60 -- pixels per second
local THEME = UiTheme.For("Epilogue")

-- gamepad: put the selection on `button` (console pass: every menu reachable without a cursor)
local function selectFor(button: GuiObject)
	if Glyphs.device() == "Gamepad" or GuiService:IsTenFootInterface() then
		GuiService.SelectedObject = button
	end
end

local function clearSelection(root: Instance)
	local selected = GuiService.SelectedObject
	if selected and selected:IsDescendantOf(root) then
		GuiService.SelectedObject = nil
	end
end

local function label(parent: Instance, text: string, size: number, font: Enum.Font, color: Color3): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 0, size + 10)
	t.Font = font
	t.TextSize = size
	t.TextColor3 = color
	t.TextWrapped = true
	t.Text = text
	t.Parent = parent
	return t
end

-- Roblox's own "favorite this experience?" prompt, for the start place (the lobby) once published. A Like can't be
-- prompted: the board and the panel only ask for one. False when there's no place id yet (Studio).
local function promptFavorite(): boolean
	local id = if Places.Lobby ~= 0 then Places.Lobby else game.PlaceId
	if id == 0 then
		return false
	end
	pcall(function()
		AvatarEditorService:PromptSetFavorite(id, Enum.AvatarItemType.Asset, true)
	end)
	return true
end

-- the tip jar under the credits' title card and behind the Epilogue SUPPORT board: thanks-in-advance and one button
-- per Products.Support entry, plus a favorite button under the credits only. `centred` = the board's pop-up
-- (mid-screen, support only: the favorite has its own board; user, Oct 12) instead of the strip under the title card.
local function supportPanel(parent: Instance, centred: boolean?): Frame
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, if centred then 0.5 else 1)
	panel.Position = if centred then UDim2.fromScale(0.5, 0.5) else UDim2.new(0.5, 0, 1, -36)
	panel.Size = UDim2.fromOffset(560, 150)
	panel.BackgroundColor3 = THEME.Panel
	panel.BackgroundTransparency = 1
	panel.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, THEME.Corner)
	corner.Parent = panel
	local stroke = Instance.new("UIStroke")
	stroke.Color = THEME.Stroke
	stroke.Thickness = 2
	stroke.Transparency = 1
	stroke.Parent = panel
	local head = label(
		panel,
		if centred then "Support our next game" else "Enjoyed Glitched Together?",
		26,
		THEME.TitleFont,
		THEME.Accent
	)
	head.Position = UDim2.fromOffset(0, 10)
	local sub = label(
		panel,
		if centred
			then "Every tip helps us build more worlds. Thank you!"
			else "Favorite it, leave a Like, or support our next game.",
		18,
		THEME.Font,
		THEME.SubInk
	)
	sub.Position = UDim2.fromOffset(0, 44)
	local row = Instance.new("Frame")
	row.AnchorPoint = Vector2.new(0.5, 1)
	row.Position = UDim2.new(0.5, 0, 1, -14)
	row.Size = UDim2.fromOffset(540, 44)
	row.BackgroundTransparency = 1
	row.Parent = panel
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Padding = UDim.new(0, 12)
	list.Parent = row
	local fades: { GuiObject } = { head, sub }
	local function button(text: string, width: number, color: Color3, onPress: () -> ())
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(width, 44)
		b.BackgroundColor3 = color
		b.Font = THEME.TitleFont
		b.TextSize = 24
		b.TextColor3 = THEME.Shadow
		b.Text = text
		b.AutoButtonColor = true
		b.Parent = row
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, THEME.Corner)
		c.Parent = b
		table.insert(fades, b)
		b.Activated:Connect(onPress)
	end
	if not centred then
		button("★ FAVORITE", 160, THEME.Ink, function()
			if not promptFavorite() then
				sub.Text = "(Favorites work once the game is published.)"
			end
		end)
	end
	for _, product in Products.Support do
		button(`{product.Robux} R$`, 108, THEME.Accent, function()
			if product.Id == 0 then
				sub.Text = "(Not set up yet: the product ids go in Config/Products.)"
				return
			end
			MarketplaceService:PromptProductPurchase(player, product.Id)
		end)
	end
	for _, g in fades do
		local goal: { [string]: number } = { TextTransparency = 0 }
		if g:IsA("TextButton") then
			goal.BackgroundTransparency = 0
		end
		for k in goal do
			(g :: any)[k] = 1
		end
		TweenService:Create(g, TweenInfo.new(1), goal :: any):Play()
	end
	TweenService:Create(panel, TweenInfo.new(1), { BackgroundTransparency = THEME.PanelTransparency + 0.25 }):Play()
	TweenService:Create(stroke, TweenInfo.new(1), { Transparency = 0.6 }):Play()
	local thanks = Net.event("SupportThanks").OnClientEvent:Connect(function()
		head.Text = "THANK YOU!"
		sub.Text = "Your support goes into our next game."
	end)
	panel.Destroying:Connect(function()
		thanks:Disconnect()
	end)
	return panel
end

local function roll()
	local old = player.PlayerGui:FindFirstChild("Credits")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "Credits"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 20 -- over the cutscene bars and the HUD
	gui.Parent = player:WaitForChild("PlayerGui")
	UiFit.attach(gui)
	player:SetAttribute("FreeCursor", true) -- CameraController unlocks the mouse so YES can be clicked
	gui.Destroying:Connect(function()
		player:SetAttribute("FreeCursor", nil)
		clearSelection(gui)
	end)

	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = THEME.Shadow
	back.BackgroundTransparency = 1
	back.BorderSizePixel = 0
	back.Parent = gui
	TweenService:Create(back, TweenInfo.new(1.5), { BackgroundTransparency = 0.08 }):Play()

	local column = Instance.new("Frame")
	column.AnchorPoint = Vector2.new(0.5, 0)
	column.Size = UDim2.new(0.8, 0, 0, 0)
	column.AutomaticSize = Enum.AutomaticSize.Y
	column.Position = UDim2.new(0.5, 0, 1, 40)
	column.BackgroundTransparency = 1
	column.Parent = back
	local list = Instance.new("UIListLayout")
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Padding = UDim.new(0, 6)
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Parent = column
	local order = 0
	for i, block in Credits do
		order += 1
		local title = label(column, block.Title, if i <= 2 then 46 else 30, THEME.TitleFont, THEME.Accent)
		title.LayoutOrder = order
		for _, line in block.Lines do
			order += 1
			label(column, line, 22, THEME.Font, THEME.Ink).LayoutOrder = order
		end
		order += 1
		label(column, "", 40, THEME.Font, THEME.Ink).LayoutOrder = order -- a gap
	end

	local done = false
	local scroll: Tween? = nil
	local function finish()
		if done then
			return
		end
		done = true
		if scroll then
			scroll:Cancel()
		end
		TweenService:Create(column, TweenInfo.new(0.6), { Position = UDim2.new(0.5, 0, -2, 0) }):Play()
		task.delay(0.6, function()
			column.Visible = false -- the last lines stayed over the card's top edge
		end)
		-- the title card: CONTINUE? YES
		local card = Instance.new("Frame")
		card.AnchorPoint = Vector2.new(0.5, 0.5)
		card.Position = UDim2.fromScale(0.5, 0.5)
		card.Size = UDim2.fromOffset(420, 220)
		card.BackgroundTransparency = 1
		card.Parent = back
		local q = label(card, "CONTINUE?", 64, THEME.TitleFont, THEME.Ink)
		q.Position = UDim2.fromOffset(0, 10)
		q.TextTransparency = 1
		local yes = Instance.new("TextButton")
		yes.AnchorPoint = Vector2.new(0.5, 0)
		yes.Position = UDim2.new(0.5, 0, 0, 120)
		yes.Size = UDim2.fromOffset(180, 64)
		yes.BackgroundColor3 = THEME.Accent
		yes.BackgroundTransparency = 1
		yes.Font = THEME.TitleFont
		yes.TextSize = 40
		yes.TextColor3 = THEME.Shadow
		yes.TextTransparency = 1
		yes.Text = "YES"
		yes.AutoButtonColor = true
		yes.Modal = true -- frees the cursor even in first person
		yes.Parent = card
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, THEME.Corner)
		corner.Parent = yes
		task.delay(0.8, function()
			if back.Parent then
				supportPanel(back)
			end
			TweenService:Create(q, TweenInfo.new(1), { TextTransparency = 0 }):Play()
			TweenService:Create(yes, TweenInfo.new(1), { TextTransparency = 0, BackgroundTransparency = 0 }):Play()
			selectFor(yes) -- A presses YES; down reaches the tip jar
			local follow = Glyphs.Changed:Connect(function()
				if yes.Parent and GuiService.SelectedObject == nil then
					selectFor(yes) -- picked up a controller at the title card
				end
			end)
			yes.Destroying:Connect(function()
				follow:Disconnect()
			end)
			-- YES blinks like an old title screen cursor until it's pressed
			task.spawn(function()
				while yes.Parent do
					task.wait(0.6)
					if yes.Parent then
						yes.TextTransparency = if yes.TextTransparency == 0 then 0.6 else 0
					end
				end
			end)
		end)
		yes.Activated:Connect(function()
			Net.event("ContinueYes"):FireServer()
			TweenService:Create(back, TweenInfo.new(1.2), { BackgroundTransparency = 1 }):Play()
			card:Destroy()
			for _, child in back:GetChildren() do
				if child ~= column and child:IsA("Frame") then
					child:Destroy() -- the tip jar goes with the card
				end
			end
			task.delay(1.3, gui.Destroy, gui)
		end)
	end

	local skip = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if
			input.KeyCode == Enum.KeyCode.Space
			or input.KeyCode == Enum.KeyCode.ButtonA
			or input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			finish()
		end
	end)
	gui.Destroying:Connect(function()
		skip:Disconnect()
	end)

	task.spawn(function()
		task.wait(1.5)
		local height = column.AbsoluteSize.Y
		local travel = back.AbsoluteSize.Y + height + 80
		local tween = TweenService:Create(column, TweenInfo.new(travel / SCROLL_SPEED, Enum.EasingStyle.Linear), {
			Position = UDim2.new(0.5, 0, 0, -height - 40),
		})
		scroll = tween
		tween:Play()
		tween.Completed:Wait()
		finish()
	end)
end

-- the Epilogue notice board's pop-up: the same panel mid-screen, with a close button (the cursor is free while open)
local function openBoard()
	if player.PlayerGui:FindFirstChild("SupportBoard") then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "SupportBoard"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 15
	gui.Parent = player.PlayerGui
	UiFit.attach(gui)
	player:SetAttribute("FreeCursor", true)
	local back = UserInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.ButtonB then
			gui:Destroy() -- gamepad: B closes it
		end
	end)
	gui.Destroying:Connect(function()
		player:SetAttribute("FreeCursor", nil)
		clearSelection(gui)
		back:Disconnect()
	end)
	local panel = supportPanel(gui, true)
	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -8, 0, 8)
	close.Size = UDim2.fromOffset(32, 32)
	close.BackgroundTransparency = 1
	close.Font = THEME.TitleFont
	close.TextSize = 24
	close.TextColor3 = THEME.SubInk
	close.Text = "✕"
	close.Modal = true -- frees the cursor even in first person
	close.Parent = panel
	close.Activated:Connect(function()
		gui:Destroy()
	end)
	local first = panel:FindFirstChildWhichIsA("Frame") -- the button row
	local firstButton = first and first:FindFirstChildWhichIsA("TextButton")
	if firstButton then
		selectFor(firstButton)
	end
	-- walking away closes it
	task.spawn(function()
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local from = root and root.Position
		while gui.Parent and root and from do
			task.wait(0.3)
			if (root.Position - from).Magnitude > 14 then
				gui:Destroy()
			end
		end
	end)
end

function CreditsController.Init()
	Net.event("Credits").OnClientEvent:Connect(roll)
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
		if prompt.Name == "SupportPrompt" then
			openBoard()
		elseif prompt.Name == "FavoritePrompt" and not promptFavorite() then
			warn("[Favorite] the favorite prompt works once the game is published (Places.Lobby)") -- Studio
		end
	end)
end

return CreditsController
