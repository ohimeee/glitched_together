-- Code Layer visibility (implementation.md §8): hidden for Kai always, and for Miko unless she's shifted.
-- Shifted Miko sees them as green wireframes and the real world desaturates. Pulled-out objects show for everyone.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)

local player = Players.LocalPlayer

local CodeLayerController = {}

local GREEN = Color3.fromRGB(60, 255, 120)
local tracked: { [Instance]: boolean } = {}

local function shifted(): boolean
	return player:GetAttribute("Shifted") == true
end

local function partsOf(inst: Instance): { BasePart }
	if inst:IsA("BasePart") then
		return { inst }
	end
	local list = {}
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

local function refresh(inst: Instance)
	local pulled = inst:GetAttribute("PulledOut") == true
	local visible = pulled or shifted()
	for _, part in partsOf(inst) do
		part.LocalTransparencyModifier = if visible then 0 else 1
	end
	local hl = inst:FindFirstChild("CodeLayerLook") :: Highlight?
	if not hl then
		local newHl = Instance.new("Highlight")
		newHl.Name = "CodeLayerLook"
		newHl.FillColor = GREEN
		newHl.OutlineColor = GREEN
		newHl.DepthMode = Enum.HighlightDepthMode.Occluded
		newHl.Parent = inst
		hl = newHl
	end
	local h = hl :: Highlight
	h.Enabled = visible
	h.FillTransparency = if pulled then 0.85 else 0.6
end

local function refreshAll()
	for inst in tracked do
		if inst.Parent then
			refresh(inst)
		else
			tracked[inst] = nil
		end
	end
	local cc = Lighting:FindFirstChild("ShiftColor") :: ColorCorrectionEffect?
	if not cc then
		local newCc = Instance.new("ColorCorrectionEffect")
		newCc.Name = "ShiftColor"
		newCc.Parent = Lighting
		cc = newCc
	end
	TweenService:Create(cc :: ColorCorrectionEffect, TweenInfo.new(0.3), {
		Saturation = if shifted() then -0.75 else 0,
		TintColor = if shifted() then Color3.fromRGB(210, 255, 220) else Color3.new(1, 1, 1),
	}):Play()
end

function CodeLayerController.Init()
	Tags.each("CodeLayer", function(inst)
		tracked[inst] = true
		inst:GetAttributeChangedSignal("PulledOut"):Connect(function()
			refresh(inst)
		end)
		refresh(inst)
	end, function(inst)
		tracked[inst] = nil
	end)
	player:GetAttributeChangedSignal("Shifted"):Connect(refreshAll)
end

return CodeLayerController
