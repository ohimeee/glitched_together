-- Watches the server-set `Kit` attribute: stops the old client tool, starts the new one, and enables
-- the matching InputContext (implementation.md §8). The final boss swaps kits just by changing it.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Kits = require(ReplicatedStorage.Shared.Config.Kits)
local Input = require(script.Parent.Parent.Input)

local player = Players.LocalPlayer
local toolsFolder = script.Parent.Parent.AbilitiesClient

export type ClientTool = {
	Start: (self: ClientTool) -> (),
	Stop: (self: ClientTool) -> (),
}

local KitController = {}
KitController.Current = nil :: ClientTool?

local activeName: string? = nil

local function setContext(tool: string?)
	for _, name in { "W1Tools", "CastleTools", "W3Tools" } do
		Input.setEnabled(name, tool ~= nil and Kits.ContextOfTool[tool] == name)
	end
end

local function swap()
	local name = player:GetAttribute("Kit") :: string?
	if name == activeName then
		return
	end
	if KitController.Current then
		local ok, err = pcall(function()
			(KitController.Current :: ClientTool):Stop()
		end)
		if not ok then
			warn("[KitController] Stop failed:", err)
		end
		KitController.Current = nil
	end
	activeName = name
	setContext(name)

	local module = name and toolsFolder:FindFirstChild(name)
	if module and module:IsA("ModuleScript") then
		local tool = require(module) :: any
		KitController.Current = tool
		local ok, err = pcall(function()
			tool:Start()
		end)
		if not ok then
			warn(`[KitController] {name} failed to start:`, err)
		end
	end
end

function KitController.Init()
	player:GetAttributeChangedSignal("Kit"):Connect(swap)
	swap()
end

return KitController
