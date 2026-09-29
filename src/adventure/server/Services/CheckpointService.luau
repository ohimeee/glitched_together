-- Shared checkpoints (implementation.md §9): whoever touches a higher Order first moves the duo's checkpoint.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)

local CheckpointService = {}

local currentOrder = 0
local world = "Prologue"
local reached = Instance.new("BindableEvent")
CheckpointService.Reached = reached.Event -- (order: number, part: BasePart)

local function checkpointsInWorld(): { BasePart }
	local list = {}
	for _, inst in game:GetService("CollectionService"):GetTagged("Checkpoint") do
		if inst:IsA("BasePart") and inst:IsDescendantOf(workspace) then
			local w = inst:GetAttribute("World")
			if w == nil or w == world then
				table.insert(list, inst)
			end
		end
	end
	table.sort(list, function(a, b)
		return (a:GetAttribute("Order") or 0) < (b:GetAttribute("Order") or 0)
	end)
	return list
end

-- The part for the current checkpoint (the highest Order <= current, else the first one).
function CheckpointService.CurrentPart(): BasePart?
	local best: BasePart? = nil
	for _, cp in checkpointsInWorld() do
		local order = cp:GetAttribute("Order") or 0
		if order <= currentOrder or best == nil then
			best = cp
		end
	end
	return best
end

function CheckpointService.Current(): number
	return currentOrder
end

-- Where to put a player: on the checkpoint pad, Kai on the left and Miko on the right.
function CheckpointService.SpawnCFrame(p: Player?): CFrame
	local cp = CheckpointService.CurrentPart()
	local side = if p and p:GetAttribute("Role") == "Miko" then 3 else -3
	if cp then
		return cp.CFrame * CFrame.new(side, cp.Size.Y / 2 + 3, 0)
	end
	local worldModel = workspace:FindFirstChild("World")
	local spawn = worldModel and worldModel:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawn then
		return spawn.CFrame * CFrame.new(side, 4, 0)
	end
	return CFrame.new(side, 10, 0)
end

function CheckpointService.Reset(worldName: string, order: number)
	world = worldName
	currentOrder = order
end

function CheckpointService.Init()
	Tags.each("Checkpoint", function(inst)
		if not inst:IsA("BasePart") then
			return
		end
		inst.Touched:Connect(function(hit)
			local character = hit:FindFirstAncestorOfClass("Model")
			local p = character and Players:GetPlayerFromCharacter(character)
			if not p or p:GetAttribute("Downed") then
				return
			end
			local w = inst:GetAttribute("World")
			if w ~= nil and w ~= world then
				return
			end
			local order = inst:GetAttribute("Order") or 0
			if order > currentOrder then
				currentOrder = order
				reached:Fire(order, inst)
			end
		end)
	end)
end

return CheckpointService
