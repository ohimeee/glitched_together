-- Lobby HUD: Invite Friend button, and a Rejoin button if you dropped out of a duo run.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local Net = require(ReplicatedStorage.Shared.Net)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local UiSkin = require(ReplicatedStorage.Shared.Util.UiSkin)
local UiFit = require(ReplicatedStorage.Shared.Util.UiFit)

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "LobbyUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.Parent = player:WaitForChild("PlayerGui")
UiFit.attach(gui)

-- the stack sits top right on every device (user, Oct 18), under Roblox's top bar
local function stackAt(index: number): (UDim2, Vector2)
	return UDim2.new(1, -16, 0, 60 + index * 58), Vector2.new(1, 0)
end

-- sticker buttons in the main HUD style (UiTheme default: FredokaOne, art-direction.md §11)
local function button(text: string, color: Color3, index: number): TextButton
	local b = Instance.new("TextButton")
	b.Position, b.AnchorPoint = stackAt(index)
	b.Size = UDim2.fromOffset(210, 52)
	b.Text = text
	b.TextScaled = true
	b.AutoButtonColor = true
	b.ZIndex = 2
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.Parent = b
	b.Parent = gui
	UiSkin.Panel(b, { Fill = color })
	UiSkin.Text(b, "Title", Color3.new(1, 1, 1))
	b.MouseEnter:Connect(function()
		b.Rotation = -2
	end)
	b.MouseLeave:Connect(function()
		b.Rotation = 0
	end)
	return b
end

-- settings menu (gear in the top bar's right corner; the same saved settings as the game)
require(ReplicatedStorage.Shared.Util.SettingsMenu).Init({ camera = false })
require(ReplicatedStorage.Shared.Util.BugReports).InitClient() -- BUG? button + /bug (beta)

local invite = button("INVITE A FRIEND", Palette.Prologue.Pink, 0)
invite.Activated:Connect(function()
	local ok, canInvite = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
	if ok and canInvite then
		SocialService:PromptGameInvite(player)
	end
end)

Net.event("RejoinOffer").OnClientEvent:Connect(function()
	local rejoin = button("REJOIN PARTNER", Color3.fromRGB(40, 170, 90), 2)
	rejoin.Activated:Connect(function()
		rejoin.Text = "JOINING..."
		Net.event("RejoinAccept"):FireServer()
	end)
end)
