-- Streaming-safe "for every tagged instance, now and later" helpers.
local CollectionService = game:GetService("CollectionService")

local Tags = {}

function Tags.each(tag: string, onAdded: (Instance) -> (), onRemoved: ((Instance) -> ())?)
	for _, inst in CollectionService:GetTagged(tag) do
		task.spawn(onAdded, inst)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(onAdded)
	if onRemoved then
		CollectionService:GetInstanceRemovedSignal(tag):Connect(onRemoved)
	end
end

function Tags.has(inst: Instance?, tag: string): boolean
	return inst ~= nil and CollectionService:HasTag(inst, tag)
end

-- Walks up from a hit part to the first ancestor (or itself) carrying the tag.
function Tags.find(inst: Instance?, tag: string): Instance?
	while inst and inst ~= workspace do
		if CollectionService:HasTag(inst, tag) then
			return inst
		end
		inst = inst.Parent
	end
	return nil
end

-- Everything with the tag that's in the world right now.
function Tags.list(tag: string): { Instance }
	local list = {}
	for _, inst in CollectionService:GetTagged(tag) do
		if inst:IsDescendantOf(workspace) then
			table.insert(list, inst)
		end
	end
	return list
end

-- Distance from a point to the nearest point of a tagged thing's box (a part, or a model's bounding box), so big
-- objects count as in range at their near end, not only at their center.
function Tags.distance(inst: Instance, pos: Vector3): number
	local cf: CFrame, size: Vector3
	if inst:IsA("BasePart") then
		cf, size = inst.CFrame, inst.Size
	elseif inst:IsA("Model") then
		cf, size = inst:GetBoundingBox()
	else
		return (Tags.position(inst) - pos).Magnitude
	end
	local p = cf:PointToObjectSpace(pos)
	local half = size / 2
	local nearest = Vector3.new(
		math.clamp(p.X, -half.X, half.X),
		math.clamp(p.Y, -half.Y, half.Y),
		math.clamp(p.Z, -half.Z, half.Z)
	)
	return (p - nearest).Magnitude
end

-- World position of a tagged thing (part or model).
function Tags.position(inst: Instance): Vector3
	if inst:IsA("BasePart") then
		return inst.Position
	elseif inst:IsA("PVInstance") then
		return inst:GetPivot().Position
	elseif inst:IsA("Attachment") then
		return inst.WorldPosition
	end
	return Vector3.zero
end

return Tags
