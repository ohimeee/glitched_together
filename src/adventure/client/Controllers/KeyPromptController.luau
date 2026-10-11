-- Key prompts for kit actions (memory teach-controls; 2P playtest Oct 11: Kai shot at the Torch Run braziers instead
-- of pressing E, and took a gate for the blinkable bars). Same chip look as SwingPromptController.
--   Tagged prompts: a part tagged `KeyPrompt` with PromptKey (an Input action: "Dash", "Ignite"), PromptText and
--   optional PromptRole ("Kai" / "Miko") shows "[key] TEXT" while you're within Tuning.KeyPromptRange.
--   Focus prompt: a tool shows one chip over its current target (FireMage: the brazier Ignite would light) with
--   KeyPromptController.Focus(adornee, action, text); nil hides it.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)

local KeyPromptController = {}

local player = Players.LocalPlayer
local INK = Color3.fromRGB(24, 26, 40)

-- the key each action shows, per input: keyboard, gamepad, touch
local KEYS: { [string]: { string } } = {
	Dash = { "SHIFT", "B", "TAP" },
	Ignite = { "E", "X", "TAP" },
}

local function keyText(action: string): string
	local keys = KEYS[action] or { action, action, action }
	local last = UserInputService:GetLastInputType()
	if last.Name:find("Gamepad") then
		return keys[2]
	elseif last == Enum.UserInputType.Touch then
		return keys[3]
	end
	return keys[1]
end

type Chip = { gui: BillboardGui, key: TextLabel, label: TextLabel, scale: UIScale }

local function make(): Chip
	local gui = Instance.new("BillboardGui")
	gui.Name = "KeyPrompt"
	gui.Size = UDim2.fromOffset(150, 40)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.ResetOnSpawn = false
	gui.Enabled = false
	local chip = Instance.new("Frame")
	chip.AnchorPoint = Vector2.new(0.5, 0.5)
	chip.Position = UDim2.fromScale(0.5, 0.5)
	chip.Size = UDim2.fromScale(1, 1)
	chip.BackgroundColor3 = INK
	chip.BackgroundTransparency = 0.05
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
	key.Size = UDim2.fromOffset(58, 30)
	key.BackgroundColor3 = Palette.Neutral
	key.TextColor3 = INK
	key.Font = Enum.Font.GothamBlack
	key.TextScaled = true
	key.Parent = chip
	Instance.new("UICorner", key).CornerRadius = UDim.new(0.3, 0)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.18, 0)
	pad.PaddingBottom = UDim.new(0.18, 0)
	pad.PaddingLeft = UDim.new(0, 4)
	pad.PaddingRight = UDim.new(0, 4)
	pad.Parent = key
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0, 0.5)
	label.Position = UDim2.new(0, 68, 0.5, 0)
	label.Size = UDim2.new(1, -76, 0, 22)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(236, 236, 228)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = chip
	gui.Parent = player:WaitForChild("PlayerGui")
	return { gui = gui, key = key, label = label, scale = scale }
end

local function show(c: Chip, adornee: Instance?, action: string, text: string)
	if adornee and adornee:IsA("Model") then
		adornee = adornee.PrimaryPart or adornee:FindFirstChildWhichIsA("BasePart", true)
	end
	if not adornee then
		c.gui.Enabled = false
		return
	end
	if not c.gui.Enabled or c.gui.Adornee ~= adornee then
		c.scale.Scale = 1.25 -- a small pop as it appears
	end
	c.gui.Adornee = adornee
	c.gui.Enabled = true
	c.key.Text = keyText(action)
	c.label.Text = text
	c.scale.Scale += (1 - c.scale.Scale) * 0.2
end

local tagged: { [Instance]: Chip } = {}
local focus: Chip? = nil
local focusTarget: { adornee: Instance?, action: string, text: string } = { adornee = nil, action = "", text = "" }

function KeyPromptController.Focus(adornee: Instance?, action: string?, text: string?)
	focusTarget.adornee = adornee
	focusTarget.action = action or ""
	focusTarget.text = text or ""
end

function KeyPromptController.Init()
	focus = make()
	Tags.each("KeyPrompt", function(inst)
		if not tagged[inst] then
			tagged[inst] = make()
		end
	end, function(inst)
		local c = tagged[inst]
		if c then
			c.gui:Destroy()
			tagged[inst] = nil
		end
	end)

	RunService.RenderStepped:Connect(function()
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local role = player:GetAttribute("Role")
		for inst, c in tagged do
			local want = inst:GetAttribute("PromptRole")
			local near = root
				and inst:IsDescendantOf(workspace)
				and (want == nil or want == role)
				and (Tags.position(inst) - root.Position).Magnitude <= Tuning.KeyPromptRange
			show(
				c,
				if near then inst else nil,
				(inst:GetAttribute("PromptKey") or "") :: string,
				(inst:GetAttribute("PromptText") or "") :: string
			)
		end
		if focus then
			local t = focusTarget.adornee
			show(focus, if t and t:IsDescendantOf(workspace) then t else nil, focusTarget.action, focusTarget.text)
		end
	end)
end

return KeyPromptController
