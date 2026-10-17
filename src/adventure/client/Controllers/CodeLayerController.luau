-- Code Layer visibility (implementation.md §8): hidden for Kai always, and for Miko unless she's shifted.
-- Shifted Miko sees them as teal wireframes (her color, art-direction.md §6/§8) and the real world desaturates, with
-- a teal scanline wipe across her screen on each shift (§12) and faint scanlines while shifted. Pulled-out objects
-- show for everyone. `CodeVisual` parts are real (solid for everyone) but drawn only in the Code Layer: hidden wires,
-- sockets, phantom steps, frame counters. Signs on either kind hide their text too.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local ToolFx = require(ReplicatedStorage.Shared.Config.ToolFx)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)

local player = Players.LocalPlayer

local CodeLayerController = {}

local TEAL = Palette.Miko
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
	for _, d in inst:GetDescendants() do
		if d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
			d.Enabled = visible
		end
	end
	local hl = inst:FindFirstChild("CodeLayerLook") :: Highlight?
	if not hl then
		local newHl = Instance.new("Highlight")
		newHl.Name = "CodeLayerLook"
		newHl.FillColor = TEAL
		newHl.OutlineColor = TEAL
		newHl.DepthMode = Enum.HighlightDepthMode.Occluded
		newHl.Parent = inst
		hl = newHl
	end
	local h = hl :: Highlight
	h.Enabled = visible
	h.FillTransparency = if pulled then 0.85 elseif inst:GetAttribute("On") == false then 0.95 else 0.6
	h.OutlineTransparency = if inst:GetAttribute("On") == false then 0.6 else 0
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

-- The shift wipe: a teal line sweeps down Miko's screen; scanlines stay faintly while she's shifted.
local wipeGui: ScreenGui? = nil

local function shiftWipe()
	local gui = wipeGui
	if not gui then
		local g = Instance.new("ScreenGui")
		g.Name = "ShiftWipe"
		g.IgnoreGuiInset = true
		g.ScreenInsets = Enum.ScreenInsets.None -- full-bleed wipe, notch included
		g.ResetOnSpawn = false
		g.DisplayOrder = 5
		local lines = Instance.new("ImageLabel")
		lines.Name = "Scanlines"
		lines.Size = UDim2.fromScale(1, 1)
		lines.BackgroundTransparency = 1
		lines.Image = ToolFx.Textures.Scanlines
		lines.ImageColor3 = TEAL
		lines.ScaleType = Enum.ScaleType.Tile
		lines.TileSize = UDim2.fromOffset(64, 64)
		lines.ImageTransparency = 1
		lines.Parent = g
		local bar = Instance.new("Frame")
		bar.Name = "Wipe"
		bar.Size = UDim2.new(1, 0, 0.12, 0)
		bar.AnchorPoint = Vector2.new(0, 0.5)
		bar.BackgroundColor3 = TEAL
		bar.BorderSizePixel = 0
		bar.Visible = false
		local grad = Instance.new("UIGradient")
		grad.Rotation = 90
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.7, 0.55),
			NumberSequenceKeypoint.new(0.95, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		grad.Parent = bar
		bar.Parent = g
		g.Parent = player:WaitForChild("PlayerGui")
		wipeGui = g
		gui = g
	end
	local g = gui :: ScreenGui
	local bar = g:FindFirstChild("Wipe") :: Frame
	local lines = g:FindFirstChild("Scanlines") :: ImageLabel
	local on = shifted()
	bar.Visible = true
	bar.Position = UDim2.fromScale(0, if on then -0.1 else 1.1)
	local sweep = TweenService:Create(bar, TweenInfo.new(Tuning.ToolFx.WipeTime, Enum.EasingStyle.Quad), {
		Position = UDim2.fromScale(0, if on then 1.1 else -0.1),
	})
	sweep:Play()
	sweep.Completed:Once(function()
		bar.Visible = false
	end)
	TweenService:Create(lines, TweenInfo.new(Tuning.ToolFx.WipeTime), { ImageTransparency = if on then 0.9 else 1 })
		:Play()
end

function CodeLayerController.Init()
	for _, tag in { "CodeLayer", "CodeVisual" } do
		Tags.each(tag, function(inst)
			tracked[inst] = true
			inst:GetAttributeChangedSignal("PulledOut"):Connect(function()
				refresh(inst)
			end)
			inst:GetAttributeChangedSignal("On"):Connect(function() -- blinking phantom steps (ContraptionService)
				refresh(inst)
			end)
			refresh(inst)
		end, function(inst)
			tracked[inst] = nil
		end)
	end
	player:GetAttributeChangedSignal("Shifted"):Connect(function()
		refreshAll()
		shiftWipe()
		Audio.play(if shifted() then "ShiftIn" else "ShiftOut")
	end)
end

return CodeLayerController
