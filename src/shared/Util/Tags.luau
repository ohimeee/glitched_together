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
