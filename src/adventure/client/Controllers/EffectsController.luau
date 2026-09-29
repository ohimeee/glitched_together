-- Readable targets (design.md §5): Frozen objects glow blue with a PAUSE ⏸ timer; Grapple Rings stay orange,
-- Pullables yellow, Copyables white. Every client draws these from server-set tags/attributes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)

local EffectsController = {}

local FROZEN_BLUE = Color3.fromRGB(90, 170, 255)

local frozenGuis: { [Instance]: TextLabel } = {}

local function adorneePart(inst: Instance): BasePart?
	if inst:IsA("BasePart") then
		return inst
	elseif inst:IsA("Model") then
		return inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function onFreezable(inst: Instance)
	local function refresh()
		local frozen = inst:GetAttribute("Frozen") == true
		local hl = inst:FindFirstChild("FrozenLook") :: Highlight?
		if frozen and not hl then
			local newHl = Instance.new("Highlight")
			newHl.Name = "FrozenLook"
			newHl.FillColor = FROZEN_BLUE
			newHl.OutlineColor = Color3.new(1, 1, 1)
			newHl.FillTransparency = 0.45
			newHl.Parent = inst

			local part = adorneePart(inst)
			if part then
				local gui = Instance.new("BillboardGui")
				gui.Name = "FrozenTimer"
				gui.Size = UDim2.fromOffset(120, 40)
				gui.StudsOffsetWorldSpace = Vector3.new(0, part.Size.Y / 2 + 2, 0)
				gui.AlwaysOnTop = true
				gui.LightInfluence = 0
				gui.Adornee = part
				gui.Parent = newHl
				local label = Instance.new("TextLabel")
				label.Size = UDim2.fromScale(1, 1)
				label.BackgroundTransparency = 1
				label.Font = Enum.Font.FredokaOne
				label.TextScaled = true
				label.TextColor3 = Color3.new(1, 1, 1)
				label.TextStrokeColor3 = FROZEN_BLUE
				label.TextStrokeTransparency = 0
				label.Parent = gui
				frozenGuis[inst] = label
			end
		elseif not frozen and hl then
			hl:Destroy()
			frozenGuis[inst] = nil
		end
	end
	inst:GetAttributeChangedSignal("Frozen"):Connect(refresh)
	refresh()

	-- Freezable = blue frame, always.
	if not inst:FindFirstChild("FreezableFrame") then
		local sel = Instance.new("SelectionBox")
		sel.Name = "FreezableFrame"
		sel.Adornee = inst :: any
		sel.Color3 = FROZEN_BLUE
		sel.LineThickness = 0.06
		sel.SurfaceTransparency = 1
		sel.Parent = inst
	end
end

local function outline(tag: string, color: Color3)
	Tags.each(tag, function(inst)
		if inst:FindFirstChild(tag .. "Look") then
			return
		end
		local hl = Instance.new("Highlight")
		hl.Name = tag .. "Look"
		hl.FillTransparency = 1
		hl.OutlineColor = color
		hl.DepthMode = Enum.HighlightDepthMode.Occluded
		hl.Parent = inst
	end)
end

function EffectsController.Init()
	Tags.each("Freezable", onFreezable)
	outline("GrappleRing", Color3.fromRGB(255, 150, 40))
	outline("Pullable", Color3.fromRGB(255, 220, 60))
	outline("Copyable", Color3.new(1, 1, 1))

	RunService.RenderStepped:Connect(function()
		local now = workspace:GetServerTimeNow()
		for inst, label in frozenGuis do
			local untilTime = inst:GetAttribute("FrozenUntil") :: number?
			label.Text = if untilTime then `⏸ {string.format("%.1f", math.max(0, untilTime - now))}` else "⏸"
		end
	end)
end

return EffectsController
