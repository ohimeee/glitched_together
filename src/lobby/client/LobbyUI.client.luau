-- Lobby HUD: Invite Friend button, and a Rejoin button if you dropped out of a duo run.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local Net = require(ReplicatedStorage.Shared.Net)

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "LobbyUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function button(text: string, color: Color3, position: UDim2): TextButton
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(1, 1)
	b.Position = position
	b.Size = UDim2.fromOffset(190, 48)
	b.BackgroundColor3 = color
	b.Font = Enum.Font.FredokaOne
	b.TextScaled = true
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = text
	b.AutoButtonColor = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = b
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.Parent = b
	b.Parent = gui
	return b
end

local invite = button("INVITE A FRIEND", Color3.fromRGB(255, 80, 170), UDim2.new(1, -16, 1, -16))
invite.Activated:Connect(function()
	local ok, canInvite = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
	if ok and canInvite then
		SocialService:PromptGameInvite(player)
	end
end)

Net.event("RejoinOffer").OnClientEvent:Connect(function()
	local rejoin = button("REJOIN PARTNER", Color3.fromRGB(40, 170, 90), UDim2.new(1, -16, 1, -74))
	rejoin.Activated:Connect(function()
		rejoin.Text = "JOINING..."
		Net.event("RejoinAccept"):FireServer()
	end)
end)
