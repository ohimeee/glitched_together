-- FIND A PARTNER (server: lobby/server/Matchmaking). A big green button at the bottom centre; pressed, it turns into
-- a search card: timer, ANY / KAI / MIKO wish chips (owner colors: they pick a character), CANCEL. The player can
-- keep walking round the bedroom while it searches. Found → "PARTNER FOUND" card, then the teleport.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage.Shared.Net)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local UiSkin = require(ReplicatedStorage.Shared.Util.UiSkin)
local UiFit = require(ReplicatedStorage.Shared.Util.UiFit)

local player = Players.LocalPlayer

local GREEN = Color3.fromRGB(40, 170, 90)
local GREY = Color3.fromRGB(120, 124, 150)
local NAVY = Palette.Prologue.Navy
local WISH_COLOR = { Any = GREY, Kai = Palette.Kai, Miko = Palette.Miko }

local findEvent = Net.event("MatchFind")
local cancelEvent = Net.event("MatchCancel")
local statusEvent = Net.event("MatchStatus")

local gui = Instance.new("ScreenGui")
gui.Name = "MatchUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.DisplayOrder = 4
gui.Parent = player:WaitForChild("PlayerGui")
UiFit.attach(gui)

local function label(parent: GuiObject, text: string, kind: any, y: number, h: number): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.new(0, 16, 0, y)
	l.Size = UDim2.new(1, -32, 0, h)
	l.Text = text
	l.TextScaled = true
	l.Parent = parent
	UiSkin.Text(l, kind, Color3.new(1, 1, 1))
	return l
end

local function button(parent: GuiObject, text: string, color: Color3, pos: UDim2, size: UDim2): TextButton
	local b = Instance.new("TextButton")
	b.Position = pos
	b.Size = size
	b.Text = text
	b.TextScaled = true
	b.AutoButtonColor = true
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.Parent = b
	b.Parent = parent
	UiSkin.Panel(b, { Fill = color })
	UiSkin.Text(b, "Title", Color3.new(1, 1, 1))
	return b
end

-- the big button --------------------------------------------------------------------------------------------------
local find = button(gui, "FIND A PARTNER", GREEN, UDim2.new(0.5, 0, 1, -28), UDim2.fromOffset(300, 70))
find.AnchorPoint = Vector2.new(0.5, 1)
-- a soft pulse on its outline (no movement: moving UI snaps to pixels and shakes)
local glow = Instance.new("UIStroke")
glow.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
glow.Color = Color3.fromRGB(190, 255, 200)
glow.Thickness = 4
glow.Parent = find
TweenService
	:Create(
		glow,
		TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ Transparency = 0.85 }
	)
	:Play()

-- the search card -------------------------------------------------------------------------------------------------
local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0.5, 1)
card.Position = UDim2.new(0.5, 0, 1, -28)
card.Size = UDim2.fromOffset(380, 196)
card.Visible = false
card.Parent = gui
UiSkin.Panel(card, { Fill = NAVY })

local title = label(card, "SEARCHING FOR A PARTNER", "Title", 12, 30)
local sub = label(card, "0:00", "Body", 46, 24)

local wish = "Any"
local chips: { [string]: TextButton } = {}
for i, name in { "Any", "Kai", "Miko" } do
	local chip = button(
		card,
		string.upper(name),
		WISH_COLOR[name],
		UDim2.new(0, 16 + (i - 1) * 120, 0, 82),
		UDim2.fromOffset(108, 44)
	)
	chips[name] = chip
	chip.Activated:Connect(function()
		wish = name
		findEvent:FireServer(wish)
	end)
end

local cancel = button(card, "CANCEL", GREY, UDim2.new(0.5, -70, 0, 138), UDim2.fromOffset(140, 44))

local function paintChips()
	for name, chip in chips do
		local on = name == wish
		chip.BackgroundTransparency = if on then 0 else 0.55
		chip.TextTransparency = if on then 0 else 0.35
	end
end

-- states ----------------------------------------------------------------------------------------------------------
local since: number? = nil
local busy = false -- found / teleporting: the card can't be cancelled any more

local function showButton()
	since, busy = nil, false
	card.Visible = false
	find.Visible = true
end

local function showCard(head: string, line: string, controls: boolean)
	find.Visible = false
	card.Visible = true
	title.Text = head
	sub.Text = line
	cancel.Visible = controls
	for _, chip in chips do
		chip.Visible = controls
	end
	card.Size = UDim2.fromOffset(380, if controls then 196 else 92)
end

find.Activated:Connect(function()
	showCard("SEARCHING FOR A PARTNER", "0:00", true)
	paintChips()
	findEvent:FireServer(wish)
end)

cancel.Activated:Connect(function()
	if not busy then
		cancelEvent:FireServer()
		showButton()
	end
end)

statusEvent.OnClientEvent:Connect(function(state: string, info: { [string]: any })
	if state == "Searching" then
		since = info.since
		wish = info.role or wish
		paintChips()
		if not busy then
			showCard("SEARCHING FOR A PARTNER", sub.Text, true)
		end
	elseif state == "Found" then
		busy, since = true, nil
		local role = string.upper(tostring(info.role or ""))
		showCard("PARTNER FOUND!", `{info.partner or "?"} · you are {role}`, false)
		UiSkin.SetTextColor(sub, WISH_COLOR[info.role] or Color3.new(1, 1, 1))
	elseif state == "Studio" then
		UiSkin.SetTextColor(sub, Color3.new(1, 1, 1))
		showCard("MATCHED! (STUDIO)", "teleport skipped", false)
		task.delay(2, showButton)
	elseif state == "Failed" then
		if busy then
			UiSkin.SetTextColor(sub, Color3.new(1, 1, 1))
			showCard("COULDN'T CONNECT", "try again", false)
			task.delay(2.5, showButton)
		end
	elseif state == "Off" then
		if not busy then
			showButton()
		end
	end
end)

-- the timer (whole seconds; server time so it matches the queue)
local shown = -1
RunService.Heartbeat:Connect(function()
	if since and card.Visible and not busy then
		local t = math.max(0, workspace:GetServerTimeNow() - since)
		local s = math.floor(t)
		if s ~= shown then
			shown = s
			sub.Text = string.format("%d:%02d", s // 60, s % 60)
		end
	end
end)
