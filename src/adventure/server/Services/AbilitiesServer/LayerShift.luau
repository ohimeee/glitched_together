-- Miko, World 3 (mechanics.md §4): Shift into the Code Layer (only she sees/stands on it), Pull Out one object
-- into the real world so Kai can see, touch and copy it. Only one pulled-out object at a time.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Net = require(ReplicatedStorage.Shared.Net)
local CollisionService = require(script.Parent.Parent.CollisionService)

local T = Tuning.LayerShift
local LayerShift = { BlockedBy = { "Downed", "InCutscene" }, Cooldowns = { [1] = T.Transition, [2] = 0.4 } }

local toolResult = Net.event("ToolResult")
local pulledOut: { [Player]: Instance } = {}

local function setGroup(inst: Instance, group: string)
	local parts = if inst:IsA("BasePart") then { inst } else inst:GetDescendants()
	for _, part in parts do
		if part:IsA("BasePart") then
			part.CollisionGroup = group
		end
	end
end

local function sendBack(inst: Instance)
	inst:SetAttribute("PulledOut", nil)
	setGroup(inst, "CodeLayer")
end

function LayerShift.Use(p: Player, useIndex: number, target: Instance?)
	if useIndex == 1 then
		local shifted = not p:GetAttribute("Shifted")
		p:SetAttribute("Shifted", shifted or nil)
		CollisionService.SetShifted(p, shifted)
		return
	end

	if useIndex ~= 2 or not p:GetAttribute("Shifted") then
		return
	end
	local code = Tags.find(target, "CodeLayer")
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (code and root) or code:GetAttribute("PulledOut") then
		return
	end
	if Tags.distance(code, root.Position) > T.PullRange + Tuning.SlackRange then
		return
	end

	local old = pulledOut[p]
	if old and old.Parent then
		sendBack(old)
	end
	pulledOut[p] = code
	code:SetAttribute("PulledOut", true) -- CodeLayerController shows it to everyone
	setGroup(code, "Default")
	toolResult:FireAllClients("PulledOut", p, code)
end

function LayerShift.Init()
	-- Leaving World 3 (or losing the kit) drops the shift.
	game:GetService("Players").PlayerAdded:Connect(function(p)
		p:GetAttributeChangedSignal("Kit"):Connect(function()
			if p:GetAttribute("Kit") ~= "LayerShift" and p:GetAttribute("Shifted") then
				p:SetAttribute("Shifted", nil)
				CollisionService.SetShifted(p, false)
			end
		end)
	end)
end

return LayerShift
