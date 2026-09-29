-- Tiny cleanup helper: collect connections, instances and functions, then clean them all at once.
export type Trove = {
	Add: (self: Trove, item: any) -> any,
	Clean: (self: Trove) -> (),
}

local Trove = {}
Trove.__index = Trove

function Trove.new(): Trove
	return setmetatable({ _items = {} }, Trove) :: any
end

function Trove:Add(item: any): any
	table.insert(self._items, item)
	return item
end

function Trove:Clean()
	local items = self._items
	self._items = {}
	for i = #items, 1, -1 do
		local item = items[i]
		local kind = typeof(item)
		if kind == "RBXScriptConnection" then
			item:Disconnect()
		elseif kind == "Instance" then
			item:Destroy()
		elseif kind == "function" then
			task.spawn(item)
		elseif kind == "table" and item.Clean then
			item:Clean()
		elseif kind == "table" and item.Destroy then
			item:Destroy()
		end
	end
end

return Trove
