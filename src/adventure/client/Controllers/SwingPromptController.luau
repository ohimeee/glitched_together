-- Context prompts on swing points (user, Oct 4: "how the hell players know they will rope that"; memory teach-controls):
-- a small "[F] SWING" chip floats over every SwingPoint within `Tuning.SwingPromptRange`, faded until the point is in
-- grab range (`Tuning.SwingRange`), then bright with a pop. The key follows your device (Util/Glyphs): F on keyboard, RB on a
-- gamepad, GRAB (the touch button) on touch. Local and purely visual; MovementController does the grab.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Glyphs = require(ReplicatedStorage.Shared.Util.Glyphs)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)

local SwingPromptController = {}

local player = Players.LocalPlayer
local READY = Palette.Neutral -- yellow = neutral interactable (art-direction §6)
local IDLE = Color3.fromRGB(236, 236, 228)

type Prompt = { gui: BillboardGui, chip: Frame, key: TextLabel, label: TextLabel, scale: UIScale, near: boolean }
local prompts: { [Instance]: Prompt } = {}

local function keyText(): string
	return Glyphs.key("Swing") -- F / RB / GRAB (the touch button)
end

local function make(point: Instance): Prompt
	local gui = Instance.new("BillboardGui")
	gui.Name = "SwingPrompt"
	gui.Size = UDim2.fromOffset(128, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = Tuning.SwingPromptRange + 4
	gui.ResetOnSpawn = false
	gui.Adornee = if point:IsA("BasePart") or point:IsA("Attachment")
		then point
		else point:FindFirstChildWhichIsA("BasePart", true)
	gui.Enabled = false

	local chip = Instance.new("Frame")
	chip.AnchorPoint = Vector2.new(0.5, 0.5)
	chip.Position = UDim2.fromScale(0.5, 0.5)
	chip.Size = UDim2.fromScale(1, 1)
	chip.BackgroundColor3 = Color3.fromRGB(24, 26, 40)
	chip.Parent = gui
	Instance.new("UICorner", chip).CornerRadius = UDim.new(0.5, 0)
	local rim = Instance.new("UIStroke")
	rim.Color = Palette.Neutral
	rim.Thickness = 2
	rim.Parent = chip
	local scale = Instance.new("UIScale")
	scale.Parent = chip

	local key = Instance.new("TextLabel")
	key.AnchorPoint = Vector2.new(0, 0.5)
	key.Position = UDim2.new(0, 5, 0.5, 0)
	key.Size = UDim2.fromOffset(42, 30)
	key.BackgroundColor3 = IDLE
	key.TextColor3 = Color3.fromRGB(24, 26, 40)
	key.Font = Enum.Font.GothamBlack
	key.TextScaled = true
	key.Parent = chip
	Instance.new("UICorner", key).CornerRadius = UDim.new(0.3, 0)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.18, 0)
	pad.PaddingBottom = UDim.new(0.18, 0)
	pad.Parent = key

	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Position = UDim2.new(0, 52, 0.5, 0)
	label.Size = UDim2.new(1, -60, 0, 22)
	label.BackgroundTransparency = 1
	label.TextColor3 = IDLE
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = "SWING"
	label.Parent = chip

	gui.Parent = player:WaitForChild("PlayerGui")
	return { gui = gui, chip = chip, key = key, label = label, scale = scale, near = false }
end

function SwingPromptController.Init()
	Tags.each("SwingPoint", function(point)
		if not prompts[point] then
			prompts[point] = make(point)
		end
	end, function(point)
		local p = prompts[point]
		if p then
			p.gui:Destroy()
			prompts[point] = nil
		end
	end)

	RunService.RenderStepped:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local text = keyText()
		-- only the point you'd actually grab lights up (MovementController grabs the nearest one in range)
		local nearest, nearestDist = nil, Tuning.SwingRange
		if root then
			for point in prompts do
				if point:IsDescendantOf(workspace) then
					local d = (Tags.position(point) - root.Position).Magnitude
					if d < nearestDist then
						nearest, nearestDist = point, d
					end
				end
			end
		end
		for point, p in prompts do
			local d = if root and point:IsDescendantOf(workspace)
				then (Tags.position(point) - root.Position).Magnitude
				else math.huge
			p.gui.Enabled = d <= Tuning.SwingPromptRange and not player:GetAttribute("Swinging") -- no chip mid-swing
			if p.gui.Enabled then
				p.key.Text = text
				local near = point == nearest
				if near and not p.near then
					p.scale.Scale = 1.25 -- a small pop as it comes into reach
				end
				p.near = near
				p.scale.Scale += ((if near then 1 else 0.8) - p.scale.Scale) * 0.2
				p.chip.BackgroundTransparency = if near then 0.05 else 0.45
				p.key.BackgroundColor3 = if near then READY else IDLE
				p.key.TextTransparency = if near then 0 else 0.35
				p.label.TextTransparency = if near then 0 else 0.4
			end
		end
	end)
end

return SwingPromptController
