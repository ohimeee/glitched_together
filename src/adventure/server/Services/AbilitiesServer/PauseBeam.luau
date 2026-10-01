-- Kai, World 1 (mechanics.md §4): Freeze a Freezable object for 4 s (one at a time), Release it early.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Net = require(ReplicatedStorage.Shared.Net)
local MoverService = require(script.Parent.Parent.MoverService)
local GrappleLine = require(script.Parent.GrappleLine)

local toolResult = Net.event("ToolResult") -- every client draws the beam / release (ToolFxController)
local launchEvent = Net.event("Launch")

local PauseBeam = { BlockedBy = { "Downed", "InCutscene" }, Cooldowns = { [1] = 0.25, [2] = 0.25 } }
local frozenBy: { [Player]: Instance } = {}

-- Release as a launcher (obstacles.md Part 3, It Takes Two's "partner launcher"): a Freezable with a LaunchVelocity
-- attribute (world studs/s) flings his partner when she stands on it or swings from it and Kai releases it early. A
-- freeze that just runs out doesn't, so the launch is always Kai's call; like a Bounce Pad it never launches the
-- player who triggers it, so it can't be solved alone. Cannons aim instead: LaunchSpeed (studs/s along the way the
-- object faces, flattened) + LaunchHeight (studs up), so where it points when Kai freezes it is where she flies.
local function launchVelocity(inst: Instance): Vector3?
	local velocity = inst:GetAttribute("LaunchVelocity")
	if typeof(velocity) == "Vector3" then
		return velocity
	end
	local speed = inst:GetAttribute("LaunchSpeed")
	local root = if inst:IsA("BasePart") then inst elseif inst:IsA("Model") then inst.PrimaryPart else nil
	if type(speed) ~= "number" or not root then
		return nil
	end
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	local up = Tuning.JumpVelocity((inst:GetAttribute("LaunchHeight") or 0) :: number)
	return (if look.Magnitude > 0.01 then look.Unit else Vector3.zAxis) * speed + Vector3.new(0, up, 0)
end

local function launchRiders(inst: Instance, releaser: Player)
	local velocity = launchVelocity(inst)
	if not velocity then
		return
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { inst }
	for _, p in Players:GetPlayers() do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if p == releaser or not root then
			continue
		end
		local down = Vector3.new(0, -Tuning.ReleaseLaunch.RideDepth, 0)
		if workspace:Raycast(root.Position, down, params) or GrappleLine.SwingTarget(p) == inst then
			launchEvent:FireClient(p, velocity, "ReleaseLaunch")
		end
	end
end

function PauseBeam.Use(player: Player, useIndex: number, target: Instance?)
	if useIndex == 2 then -- Release
		local current = frozenBy[player]
		if current then
			launchRiders(current, player)
			MoverService.Resume(current)
			frozenBy[player] = nil
			toolResult:FireAllClients("Released", player, current)
		end
		return
	end

	local freezable = Tags.find(target, "Freezable")
	if not freezable then
		return
	end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	if Tags.distance(freezable, root.Position) > Tuning.PauseBeam.Range + Tuning.SlackRange then
		return
	end

	local old = frozenBy[player]
	if old and old ~= freezable then
		MoverService.Resume(old)
	end
	frozenBy[player] = freezable
	MoverService.Pause(freezable, Tuning.PauseBeam.Duration)
	toolResult:FireAllClients("Froze", player, freezable)
end

return PauseBeam
