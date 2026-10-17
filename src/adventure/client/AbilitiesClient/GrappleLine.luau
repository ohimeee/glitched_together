-- Miko's Grapple Line, client half: Tool1 (or the Swing key: F / RB / GRAB) swings from Grapple Rings or anything Kai
-- froze (swing runs locally through MovementController, Jump releases with a 1.3x boost); Tool2 pulls Pullable objects.
-- The swing takes the anchor under the crosshair, else the nearest one within NearRange (user, Oct 17: you can grab a
-- ring you're near without looking at it, on every device).
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local Net = require(ReplicatedStorage.Shared.Net)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local Input = require(script.Parent.Parent.Input)
local Aim = require(script.Parent.Parent.Aim)
local MoveAnim = require(script.Parent.Parent.Controllers.MoveAnimController)
local MovementController = require(script.Parent.Parent.Controllers.MovementController)

local toolUse = Net.event("ToolUse")
local toolResult = Net.event("ToolResult")
local T = Tuning.GrappleLine

local GrappleLine = {}
local trove = Trove.new()

local function canAnchor(inst: Instance): boolean
	return Tags.has(inst, "GrappleRing") or inst:GetAttribute("Frozen") == true
end

local function swingTarget(): Instance?
	local aimed = Aim.best({ "GrappleRing", "Freezable" }, T.Range, T.AimCone, canAnchor)
	if aimed then
		return aimed
	end
	local root = Aim.root()
	if not root then
		return nil
	end
	local best, bestDist = nil, T.NearRange
	for _, tag in { "GrappleRing", "Freezable" } do
		for _, inst in CollectionService:GetTagged(tag) do
			if inst:IsDescendantOf(workspace) and canAnchor(inst) then
				local d = Tags.distance(inst, root.Position)
				if d < bestDist then
					best, bestDist = inst, d
				end
			end
		end
	end
	return best
end

function GrappleLine:Start()
	local swingLook = trove:Add(Instance.new("Highlight"))
	swingLook.FillTransparency = 0.6
	swingLook.FillColor = Palette.Miko
	swingLook.OutlineColor = Palette.Miko
	swingLook.Enabled = false
	swingLook.Parent = workspace

	local target: Instance? = nil
	trove:Add(RunService.RenderStepped:Connect(function()
		target = if MovementController.IsSwinging() then nil else swingTarget()
		swingLook.Adornee = target :: any
		swingLook.Enabled = target ~= nil
	end))

	local function grab()
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
			MoveAnim.Aim()
			toolUse:FireServer(1, anchor)
		end
	end
	trove:Add(Input.action("W1Tools", "Tool1").Pressed:Connect(grab))
	-- the Swing key grabs too when no rail or swing point is in reach (MovementController takes those first)
	MovementController.SetSwingFallback(grab)

	trove:Add(Input.action("W1Tools", "Tool2").Pressed:Connect(function()
		local pullTarget = Aim.best({ "Pullable" }, T.PullRange, T.AimCone)
		if pullTarget then
			MoveAnim.Aim()
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
	MovementController.SetSwingFallback(nil)
	MovementController.StopSwing()
	trove:Clean()
end

return GrappleLine
