-- Kai, World 3 (mechanics.md §4): Copy one Copyable object (or anything Miko pulled out), Paste up to 2 copies.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Net = require(ReplicatedStorage.Shared.Net)
local CheckpointService = require(script.Parent.Parent.CheckpointService)

local T = Tuning.CopyPaste
local CopyPaste = { BlockedBy = { "Downed", "InCutscene" }, Cooldowns = { [1] = 0.3, [2] = 0.4 } }

local toolResult = Net.event("ToolResult")
local copied: { [Player]: Instance } = {}
local pastes: { [Player]: { Instance } } = {}

local function rootOf(p: Player): BasePart?
	return p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function copyableOf(target: Instance?): Instance?
	local copyable = Tags.find(target, "Copyable")
	if copyable then
		return copyable
	end
	local code = Tags.find(target, "CodeLayer")
	if code and code:GetAttribute("PulledOut") then
		return code
	end
	return nil
end

-- A clean template: real-world collisions, no Code Layer tag, anchored.
local function template(source: Instance): Instance
	local clone = source:Clone()
	CollectionService:RemoveTag(clone, "CodeLayer")
	clone:SetAttribute("PulledOut", nil)
	for _, d in clone:GetDescendants() do
		CollectionService:RemoveTag(d, "CodeLayer")
	end
	local parts = if clone:IsA("BasePart") then { clone } else clone:GetDescendants()
	for _, part in parts do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Default"
			part.Anchored = true
			part.Transparency = math.min(part.Transparency, 0.1)
		end
	end
	return clone
end

local function extents(inst: Instance): (CFrame, Vector3)
	if inst:IsA("BasePart") then
		return inst.CFrame, inst.Size
	end
	return (inst :: Model):GetBoundingBox()
end

local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include

function CopyPaste.Use(p: Player, useIndex: number, target: Instance?, aim: any)
	local root = rootOf(p)
	if not root then
		return
	end

	if useIndex == 1 then
		local source = copyableOf(target)
		if not source or Tags.distance(source, root.Position) > T.CopyRange + Tuning.SlackRange then
			return
		end
		local old = copied[p]
		if old then
			old:Destroy()
		end
		copied[p] = template(source)
		p:SetAttribute("CopiedName", source.Name)
		toolResult:FireClient(p, "Copied", source)
		toolResult:FireAllClients("CopyScan", p, source) -- everyone sees the scan (ToolFxController)
		return
	end

	if useIndex ~= 2 then
		return
	end
	local stored = copied[p]
	if not stored or typeof(aim) ~= "CFrame" then
		return
	end
	local cf = aim :: CFrame
	if (cf.Position - root.Position).Magnitude > T.PasteRange + Tuning.SlackRange then
		return
	end

	-- `NoPaste` volumes: rooms where pastes would let Kai build round a puzzle alone (paste stairs over a wall)
	for _, zone in Tags.list("NoPaste") do
		if zone:IsA("BasePart") then
			local lp = zone.CFrame:PointToObjectSpace(cf.Position)
			local half = zone.Size / 2
			if math.abs(lp.X) <= half.X and math.abs(lp.Y) <= half.Y and math.abs(lp.Z) <= half.Z then
				toolResult:FireClient(p, "PasteBlocked")
				return
			end
		end
	end

	local paste = stored:Clone()
	if paste:IsA("BasePart") then
		paste.CFrame = cf
	else
		(paste :: Model):PivotTo(cf)
	end

	-- Refuse to paste into a player.
	local chars = {}
	for _, other in game:GetService("Players"):GetPlayers() do
		if other.Character then
			table.insert(chars, other.Character)
		end
	end
	overlap.FilterDescendantsInstances = chars
	local boxCf, size = extents(paste)
	if #workspace:GetPartBoundsInBox(boxCf, size, overlap) > 0 then
		paste:Destroy()
		toolResult:FireClient(p, "PasteBlocked")
		return
	end

	CollectionService:AddTag(paste, "Pasted")
	paste.Parent = workspace:FindFirstChild("World") or workspace
	local list = pastes[p] or {}
	pastes[p] = list
	table.insert(list, paste)
	while #list > T.MaxPastes do
		local oldest = table.remove(list, 1)
		if oldest then
			oldest:Destroy()
		end
	end
	toolResult:FireAllClients("Pasted", p, paste)
end

-- Every checkpoint is a save: the clipboard and all pastes clear, so each section's puzzles bring their own copy
-- sources (and Kai can't carry a platform through the whole world to cross every gap alone).
function CopyPaste.Init()
	CheckpointService.Reached:Connect(function()
		for p, stored in copied do
			stored:Destroy()
			copied[p] = nil
			p:SetAttribute("CopiedName", nil)
		end
		for p, list in pastes do
			for _, paste in list do
				paste:Destroy()
			end
			pastes[p] = nil
		end
		toolResult:FireAllClients("ClipboardCleared")
	end)
end

return CopyPaste
