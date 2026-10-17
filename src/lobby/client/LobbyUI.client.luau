-- Lobby HUD: Invite Friend button, and a Rejoin button if you dropped out of a duo run.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local Net = require(ReplicatedStorage.Shared.Net)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local UiSkin = require(ReplicatedStorage.Shared.Util.UiSkin)

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "LobbyUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.Parent = player:WaitForChild("PlayerGui")

-- sticker buttons in the main HUD style (UiTheme default: FredokaOne, art-direction.md §11)
local function button(text: string, color: Color3, position: UDim2): TextButton
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(1, 1)
	b.Position = position
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

local invite = button("INVITE A FRIEND", Palette.Prologue.Pink, UDim2.new(1, -16, 1, -16))
invite.Activated:Connect(function()
	local ok, canInvite = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
	if ok and canInvite then
		SocialService:PromptGameInvite(player)
	end
end)

Net.event("RejoinOffer").OnClientEvent:Connect(function()
	local rejoin = button("REJOIN PARTNER", Color3.fromRGB(40, 170, 90), UDim2.new(1, -16, 1, -132))
	rejoin.Activated:Connect(function()
		rejoin.Text = "JOINING..."
		Net.event("RejoinAccept"):FireServer()
	end)
end)
