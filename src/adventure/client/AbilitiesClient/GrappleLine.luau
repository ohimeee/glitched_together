-- Miko's Grapple Line, client half: Tool1 swings from Grapple Rings or anything Kai froze (swing runs
-- locally through MovementController, Jump releases with a 1.3x boost); Tool2 pulls Pullable objects.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Net = require(ReplicatedStorage.Shared.Net)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local Input = require(script.Parent.Parent.Input)
local Aim = require(script.Parent.Parent.Aim)
local MovementController = require(script.Parent.Parent.Controllers.MovementController)

local toolUse = Net.event("ToolUse")
local toolResult = Net.event("ToolResult")
local T = Tuning.GrappleLine

local GrappleLine = {}
local trove = Trove.new()

local function swingTarget(): Instance?
	return Aim.best({ "GrappleRing", "Freezable" }, T.Range, T.AimCone, function(inst)
		return Tags.has(inst, "GrappleRing") or inst:GetAttribute("Frozen") == true
	end)
end

function GrappleLine:Start()
	local swingLook = trove:Add(Instance.new("Highlight"))
	swingLook.FillTransparency = 0.6
	swingLook.FillColor = Color3.fromRGB(255, 150, 40)
	swingLook.OutlineColor = Color3.fromRGB(255, 150, 40)
	swingLook.Enabled = false
	swingLook.Parent = workspace

	local target: Instance? = nil
	trove:Add(RunService.RenderStepped:Connect(function()
		target = if MovementController.IsSwinging() then nil else swingTarget()
		swingLook.Adornee = target :: any
		swingLook.Enabled = target ~= nil
	end))

	trove:Add(Input.action("W1Tools", "Tool1").Pressed:Connect(function()
		if MovementController.IsSwinging() then
			MovementController.StopSwing()
			return
		end
		local anchor = target
		if not anchor then
			return
		end
		local started = MovementController.StartSwing(
			function()
				if not anchor.Parent then
					return nil
				end
				return Tags.position(anchor)
			end,
			T.Boost,
			function()
				toolUse:FireServer(1, nil) -- tell the server we let go
			end
		)
		if started then
			toolUse:FireServer(1, anchor)
		end
	end))

	trove:Add(Input.action("W1Tools", "Tool2").Pressed:Connect(function()
		local pullTarget = Aim.best({ "Pullable" }, T.PullRange, T.AimCone)
		if pullTarget then
			toolUse:FireServer(2, pullTarget)
		end
	end))

	-- The server cuts the line if Kai's freeze ends mid-swing or the target was invalid.
	trove:Add(toolResult.OnClientEvent:Connect(function(kind: string)
		if kind == "GrappleDrop" then
			MovementController.StopSwing()
		end
	end))
end

function GrappleLine:Stop()
	MovementController.StopSwing()
	trove:Clean()
end

return GrappleLine
