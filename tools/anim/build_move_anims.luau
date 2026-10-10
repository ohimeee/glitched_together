-- Run in Studio (Edit, command bar or Studio MCP execute_luau): builds every clip of Config/MoveAnims.luau as a
-- KeyframeSequence into ServerStorage.MoveAnims. Upload each: right-click → Save to Roblox (owner = the
-- experience's owner), then paste the ids into MoveAnims.Ids. Re-run after changing a clip and re-upload that one.
local MoveAnims = require(game:GetService("ReplicatedStorage").Shared.Config.MoveAnims)
local ServerStorage = game:GetService("ServerStorage")

local folder = ServerStorage:FindFirstChild("MoveAnims")
if folder then
	folder:Destroy()
end
folder = Instance.new("Folder")
folder.Name = "MoveAnims"
local names = {}
for name in MoveAnims.Clips do
	table.insert(names, name)
end
table.sort(names)
for _, name in names do
	MoveAnims.build(name).Parent = folder
end
folder.Parent = ServerStorage
return `built {#names}: {table.concat(names, ", ")}`
