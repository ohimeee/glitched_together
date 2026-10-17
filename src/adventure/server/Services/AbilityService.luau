-- Receives ToolUse and decides (implementation.md §5 trust rule: the client asks, the server decides).
-- Checks: the player's current Kit, BlockedBy attributes, per-use cooldowns, and a flood limit.
-- Each tool module then checks its own target tags and ranges.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Net = require(ReplicatedStorage.Shared.Net)

export type ServerTool = {
	BlockedBy: { string },
	Cooldowns: { [number]: number }?,
	Use: (player: Player, useIndex: number, target: Instance?, aim: any) -> (),
	Init: (() -> ())?,
}

local AbilityService = {}

local folder = script.Parent.AbilitiesServer
local tools: { [string]: ServerTool } = {}
local lastUse: { [Player]: { [number]: number } } = {}
local budget: { [Player]: number } = {}

local MAX_PER_SECOND = 20

function AbilityService.Init()
	for _, module in folder:GetChildren() do
		if module:IsA("ModuleScript") then
			local tool = require(module) :: ServerTool
			tools[module.Name] = tool
			if tool.Init then
				tool.Init()
			end
		end
	end

	Net.event("ToolUse").OnServerEvent:Connect(function(p: Player, useIndex: any, target: any, aim: any)
		if type(useIndex) ~= "number" or useIndex < 1 or useIndex > 5 then
			return
		end
		if target ~= nil and typeof(target) ~= "Instance" then
			return
		end
		budget[p] = (budget[p] or 0) + 1
		if budget[p] > MAX_PER_SECOND then
			return
		end

		local kit = p:GetAttribute("Kit")
		local tool = kit and tools[kit]
		if not tool then
			return
		end
		for _, attr in tool.BlockedBy do
			if p:GetAttribute(attr) then
				return
			end
		end
		local cooldown = tool.Cooldowns and tool.Cooldowns[useIndex]
		if cooldown then
			local uses = lastUse[p] or {}
			lastUse[p] = uses
			local now = os.clock()
			if now - (uses[useIndex] or -math.huge) < cooldown * 0.9 then -- 10% slack for lag
				return
			end
			uses[useIndex] = now
			if cooldown >= 1 then -- touch buttons draw the wait (TouchController): server-time end of the cooldown
				p:SetAttribute(`Cooldown{useIndex}`, workspace:GetServerTimeNow() + cooldown)
			end
		end
		tool.Use(p, useIndex, target, aim)
	end)

	task.spawn(function()
		while true do
			task.wait(1)
			table.clear(budget)
		end
	end)

	Players.PlayerRemoving:Connect(function(p)
		lastUse[p] = nil
		budget[p] = nil
	end)
end

return AbilityService
