-- Partner always visible: through-wall outline in their color (Kai orange, Miko teal), a name tag,
-- and an arrow at the screen edge when they're off-screen (mechanics.md §6).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roles = require(ReplicatedStorage.Shared.Config.Roles)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local PartnerController = {}

local function partner(): Player?
	local myRole = player:GetAttribute("Role")
	for _, p in Players:GetPlayers() do
		local role = p:GetAttribute("Role")
		if p ~= player and role and role ~= myRole then
			return p
		end
	end
	return nil
end

local function roleInfo(p: Player): any
	return (Roles :: any)[p:GetAttribute("Role") or ""]
end

local function decorate(p: Player, character: Model)
	local info = roleInfo(p)
	if not info then
		return
	end
	local isPartner = p ~= player
	local highlight = Instance.new("Highlight")
	highlight.Name = "RoleOutline"
	highlight.FillTransparency = 1
	highlight.OutlineColor = info.Color
	highlight.OutlineTransparency = if isPartner then 0 else 1
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Adornee = character
	highlight.Parent = character

	local head = character:WaitForChild("Head", 5)
	if head and isPartner then
		local tag = Instance.new("BillboardGui")
		tag.Name = "RoleTag"
		tag.Size = UDim2.fromOffset(140, 36)
		tag.StudsOffset = Vector3.new(0, 2.6, 0)
		tag.AlwaysOnTop = true
		tag.LightInfluence = 0
		tag.MaxDistance = 400
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = info.Color
		label.TextStrokeTransparency = 0.3
		label.Text = (if info.Shape == "Triangle" then "▲ " else "● ") .. info.Label
		label.Parent = tag
		tag.Parent = head
	end
end

local function hook(p: Player)
	local function onChar(character: Model)
		if not p:GetAttribute("Role") then
			p:GetAttributeChangedSignal("Role"):Wait()
		end
		decorate(p, character)
	end
	if p.Character then
		task.spawn(onChar, p.Character)
	end
	p.CharacterAdded:Connect(onChar)
end

local function buildArrow()
	local gui = Instance.new("ScreenGui")
	gui.Name = "PartnerArrow"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = player:WaitForChild("PlayerGui")
	local arrow = Instance.new("TextLabel")
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Size = UDim2.fromOffset(44, 44)
	arrow.BackgroundTransparency = 1
	arrow.Font = Enum.Font.FredokaOne
	arrow.TextScaled = true
	arrow.Text = "➤"
	arrow.Visible = false
	arrow.Parent = gui

	RunService.RenderStepped:Connect(function()
		local p = partner()
		local root = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not (p and root) then
			arrow.Visible = false
			return
		end
		local screen, onScreen = camera:WorldToViewportPoint(root.Position)
		if onScreen then
			arrow.Visible = false
			return
		end
		local size = camera.ViewportSize
		local center = size / 2
		local dir = Vector2.new(screen.X, screen.Y) - center
		if screen.Z < 0 then
			dir = -dir -- behind the camera
		end
		if dir.Magnitude < 1 then
			dir = Vector2.new(0, 1)
		end
		dir = dir.Unit
		local margin = 40
		local scale = math.min(
			(center.X - margin) / math.max(math.abs(dir.X), 1e-3),
			(center.Y - margin) / math.max(math.abs(dir.Y), 1e-3)
		)
		local pos = center + dir * scale
		arrow.Position = UDim2.fromOffset(pos.X, pos.Y)
		arrow.Rotation = math.deg(math.atan2(dir.Y, dir.X))
		arrow.TextColor3 = roleInfo(p) and roleInfo(p).Color or Color3.new(1, 1, 1)
		arrow.TextTransparency = if p:GetAttribute("Shifted") then 0.7 else 0 -- in the Code Layer: a faint hint only
		arrow.Visible = true
	end)
end

function PartnerController.Init()
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)
	buildArrow()
end

function PartnerController.Partner(): Player?
	return partner()
end

return PartnerController
