-- Run in Studio (Edit, Studio MCP execute_luau with this file's text) while `python tools/anim/upload.py receive`
-- waits: sends every MoveAnims clip as a Rojo .model.json tree ({ [clipName] = tree }) to it on port 34998.
local HttpService = game:GetService("HttpService")
local MoveAnims = require(game:GetService("ReplicatedStorage").Shared.Config.MoveAnims)

local function cframe(cf: CFrame)
	local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
	return {
		CFrame = {
			position = { x, y, z },
			orientation = { { r00, r01, r02 }, { r10, r11, r12 }, { r20, r21, r22 } }, -- rows (Rojo)
		},
	}
end

local function tree(inst: Instance)
	local node: { [string]: any } = { name = inst.Name, className = inst.ClassName, properties = {} }
	if inst:IsA("KeyframeSequence") then
		node.properties.Loop = { Bool = inst.Loop }
		node.properties.Priority = { Enum = inst.Priority.Value }
	elseif inst:IsA("Keyframe") then
		node.properties.Time = { Float32 = inst.Time }
	elseif inst:IsA("Pose") then
		node.properties.CFrame = cframe(inst.CFrame)
		node.properties.Weight = { Float32 = inst.Weight }
		node.properties.EasingStyle = { Enum = inst.EasingStyle.Value }
		node.properties.EasingDirection = { Enum = inst.EasingDirection.Value }
	end
	local children = {}
	for _, child in inst:GetChildren() do
		table.insert(children, tree(child))
	end
	if #children > 0 then
		node.children = children
	end
	return node
end

local out = {}
for name in MoveAnims.Clips do
	out[name] = tree(MoveAnims.build(name))
end

local was = HttpService.HttpEnabled
HttpService.HttpEnabled = true
local ok, result = pcall(function()
	return HttpService:PostAsync(
		"http://127.0.0.1:34998/",
		HttpService:JSONEncode(out),
		Enum.HttpContentType.ApplicationJson
	)
end)
HttpService.HttpEnabled = was
return if ok then result else "failed: " .. tostring(result)
