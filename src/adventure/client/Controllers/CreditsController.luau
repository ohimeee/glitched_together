-- The end credits (Epilogue; Story Line "Continue" steps 5-6). The server fires the "Credits" remote after the
-- real-world ending cutscene: a night-blue screen, the credits (Config/Credits) scroll up, then the title card
-- "CONTINUE?" with one answer, YES. YES fades the screen away and leaves the duo free under the stars.
-- Space / click / tap skips straight to the title card.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Net = require(ReplicatedStorage.Shared.Net)
local Credits = require(ReplicatedStorage.Shared.Config.Credits)
local UiTheme = require(ReplicatedStorage.Shared.Config.UiTheme)

local CreditsController = {}

local player = Players.LocalPlayer
local SCROLL_SPEED = 60 -- pixels per second
local THEME = UiTheme.For("Epilogue")

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
	player:SetAttribute("FreeCursor", true) -- CameraController unlocks the mouse so YES can be clicked
	gui.Destroying:Connect(function()
		player:SetAttribute("FreeCursor", nil)
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
			TweenService:Create(q, TweenInfo.new(1), { TextTransparency = 0 }):Play()
			TweenService:Create(yes, TweenInfo.new(1), { TextTransparency = 0, BackgroundTransparency = 0 }):Play()
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
			TweenService:Create(back, TweenInfo.new(1.2), { BackgroundTransparency = 1 }):Play()
			card:Destroy()
			task.delay(1.3, gui.Destroy, gui)
		end)
	end

	local skip = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
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

function CreditsController.Init()
	Net.event("Credits").OnClientEvent:Connect(roll)
end

return CreditsController
