-- The tip jar UI, client only, shared by the adventure (under the credits' title card + the Epilogue SUPPORT board)
-- and the lobby (the tip jar on the desk). Quick buttons for Products.Support entries marked Quick, plus an
-- "other amount" box (user, Oct 18): Roblox can't charge a typed amount, so it buys the closest product and says
-- which. Receipts: server Util/TipJar. After a purchase the panel thanks the player and offers "hide my name"
-- (Supporter Wall + credits, Util/Supporters).
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Net = require(ReplicatedStorage.Shared.Net)
local Products = require(ReplicatedStorage.Shared.Config.Products)
local UiTheme = require(ReplicatedStorage.Shared.Config.UiTheme)
local Glyphs = require(ReplicatedStorage.Shared.Util.Glyphs)
local UiFit = require(ReplicatedStorage.Shared.Util.UiFit)

local TipPanel = {}

local player = Players.LocalPlayer
local THEME = UiTheme.For("Epilogue")
local THANKS = "Your photo is going up on the Supporter Wall."

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

local function selectFor(button: GuiObject)
	if Glyphs.device() == "Gamepad" or GuiService:IsTenFootInterface() then
		GuiService.SelectedObject = button
	end
end

-- the product closest to `robux` (a tie goes to the smaller one)
function TipPanel.Closest(robux: number): { Id: number, Robux: number }?
	local best, gap = nil, math.huge
	for _, p in Products.Support do
		local d = math.abs(p.Robux - robux)
		if d < gap then
			best, gap = p, d
		end
	end
	return best
end

-- The panel. opts.centred = a mid-screen pop-up (boards, the lobby jar) instead of the strip under the credits;
-- opts.onFavorite = also show a FAVORITE button (credits only); opts.title / opts.sub = other wording.
function TipPanel.Panel(
	parent: Instance,
	opts: { centred: boolean?, onFavorite: (() -> boolean)?, title: string?, sub: string? }?
): Frame
	local o = opts or {}
	local centred = o.centred == true
	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, if centred then 0.5 else 1)
	panel.Position = if centred then UDim2.fromScale(0.5, 0.5) else UDim2.new(0.5, 0, 1, -36)
	panel.Size = UDim2.fromOffset(600, 204)
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
		o.title or (if o.onFavorite then "Enjoyed Glitched Together?" else "Support our next game"),
		26,
		THEME.TitleFont,
		THEME.Accent
	)
	head.Position = UDim2.fromOffset(0, 10)
	local sub = label(
		panel,
		o.sub
			or (
				if o.onFavorite
					then "Favorite it, leave a Like, or support our next game."
					else "Every tip helps us build more worlds. Thank you!"
			),
		18,
		THEME.Font,
		THEME.SubInk
	)
	sub.Position = UDim2.fromOffset(0, 44)

	local fades: { GuiObject } = { head, sub }
	local function row(y: number): Frame
		local r = Instance.new("Frame")
		r.AnchorPoint = Vector2.new(0.5, 0)
		r.Position = UDim2.new(0.5, 0, 0, y)
		r.Size = UDim2.fromOffset(580, 44)
		r.BackgroundTransparency = 1
		r.Parent = panel
		local list = Instance.new("UIListLayout")
		list.FillDirection = Enum.FillDirection.Horizontal
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.VerticalAlignment = Enum.VerticalAlignment.Center
		list.Padding = UDim.new(0, 12)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = r
		return r
	end
	local function button(parent2: Instance, text: string, width: number, color: Color3, onPress: () -> ())
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(width, 44)
		b.BackgroundColor3 = color
		b.Font = THEME.TitleFont
		b.TextSize = 24
		b.TextColor3 = THEME.Shadow
		b.Text = text
		b.AutoButtonColor = true
		b.LayoutOrder = #parent2:GetChildren()
		b.Parent = parent2
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, THEME.Corner)
		c.Parent = b
		table.insert(fades, b)
		b.Activated:Connect(onPress)
		return b
	end
	local function buy(product: { Id: number, Robux: number })
		if product.Id == 0 then
			sub.Text = `(Not set up yet: the {product.Robux} R$ product id goes in Config/Products.)`
			return
		end
		MarketplaceService:PromptProductPurchase(player, product.Id)
	end

	local quick = row(80)
	if o.onFavorite then
		local favorite = o.onFavorite
		button(quick, "★ FAVORITE", 160, THEME.Ink, function()
			if not favorite() then
				sub.Text = "(Favorites work once the game is published.)"
			end
		end)
	end
	for _, product in Products.Support do
		if product.Quick then
			button(quick, `{product.Robux} R$`, 108, THEME.Accent, function()
				buy(product)
			end)
		end
	end

	-- other amount: type a number, TIP buys the closest product (shown live under the box)
	local other = row(134)
	local box = Instance.new("TextBox")
	box.Size = UDim2.fromOffset(220, 40)
	box.BackgroundColor3 = THEME.Shadow
	box.BackgroundTransparency = 0.3
	box.Font = THEME.Font
	box.TextSize = 20
	box.TextColor3 = THEME.Ink
	box.PlaceholderText = "other amount (R$)"
	box.PlaceholderColor3 = THEME.SubInk
	box.Text = ""
	box.ClearTextOnFocus = false
	box.LayoutOrder = 1
	box.Parent = other
	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, THEME.Corner)
	boxCorner.Parent = box
	table.insert(fades, box)
	local note = label(other, "", 16, THEME.Font, THEME.SubInk)
	note.Size = UDim2.fromOffset(150, 40)
	note.LayoutOrder = 3
	local function picked(): { Id: number, Robux: number }?
		local n = tonumber((box.Text:gsub("[^%d]", "")))
		return if n and n > 0 then TipPanel.Closest(n) else nil
	end
	box:GetPropertyChangedSignal("Text"):Connect(function()
		local digits = box.Text:gsub("[^%d]", ""):sub(1, 6)
		if digits ~= box.Text then
			box.Text = digits
			return
		end
		local p = picked()
		note.Text = if p then `tips {p.Robux} R$` else ""
	end)
	local tip = button(other, "TIP", 90, THEME.Accent, function()
		local p = picked()
		if p then
			buy(p)
		else
			sub.Text = "Type an amount first."
		end
	end)
	tip.LayoutOrder = 2
	box.FocusLost:Connect(function(enter)
		local p = enter and picked()
		if p then
			buy(p)
		end
	end)

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

	local hideButton: TextButton? = nil
	local thanks = Net.event("SupportThanks").OnClientEvent:Connect(function()
		head.Text = "THANK YOU!"
		sub.Text = THANKS
		-- the wall + credits show the supporter's name: their choice to take it down (and put it back)
		if not hideButton then
			local hidden = false
			local b = Instance.new("TextButton")
			b.AnchorPoint = Vector2.new(1, 0)
			b.Position = UDim2.new(1, -44, 0, 8)
			b.Size = UDim2.fromOffset(150, 26)
			b.BackgroundTransparency = 1
			b.Font = THEME.Font
			b.TextSize = 16
			b.TextColor3 = THEME.SubInk
			b.Text = "hide my name"
			b.Parent = panel
			b.Activated:Connect(function()
				hidden = not hidden
				Net.event("SupporterHide"):FireServer(hidden)
				b.Text = if hidden then "show my name" else "hide my name"
				sub.Text = if hidden then "Your name stays off the wall." else THANKS
			end)
			hideButton = b
		end
	end)
	panel.Destroying:Connect(function()
		thanks:Disconnect()
	end)
	return panel
end

-- The pop-up (a board / the lobby jar): the panel mid-screen with a close button; the cursor is free while open
-- (player attribute FreeCursor, adventure CameraController); B or walking away closes it.
function TipPanel.Open(): ScreenGui?
	if player.PlayerGui:FindFirstChild("SupportBoard") then
		return nil
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
		local selected = GuiService.SelectedObject
		if selected and selected:IsDescendantOf(gui) then
			GuiService.SelectedObject = nil
		end
		back:Disconnect()
	end)
	local panel = TipPanel.Panel(gui, { centred = true })
	-- close: a round dark button on the panel's corner with an X drawn from two bars (the "✕" character didn't
	-- render in the lobby's font, so the jar had no visible way out; user, Oct 19)
	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.AnchorPoint = Vector2.new(0.5, 0.5)
	close.Position = UDim2.new(1, -6, 0, 6)
	close.Size = UDim2.fromOffset(40, 40)
	close.BackgroundColor3 = Color3.fromRGB(22, 24, 44)
	close.Text = ""
	close.AutoButtonColor = true
	close.Modal = true -- frees the cursor even in first person
	close.ZIndex = 10
	close.Parent = panel
	local round = Instance.new("UICorner")
	round.CornerRadius = UDim.new(0.5, 0)
	round.Parent = close
	local rim = Instance.new("UIStroke")
	rim.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	rim.Color = Color3.new(1, 1, 1)
	rim.Thickness = 2
	rim.Parent = close
	for _, angle in { 45, -45 } do
		local bar = Instance.new("Frame")
		bar.AnchorPoint = Vector2.new(0.5, 0.5)
		bar.Position = UDim2.fromScale(0.5, 0.5)
		bar.Size = UDim2.new(0.55, 0, 0, 4)
		bar.Rotation = angle
		bar.BackgroundColor3 = Color3.new(1, 1, 1)
		bar.BorderSizePixel = 0
		bar.ZIndex = 11
		bar.Parent = close
	end
	close.Activated:Connect(function()
		gui:Destroy()
	end)
	local first = panel:FindFirstChildWhichIsA("Frame") -- the quick row
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
	return gui
end

return TipPanel
