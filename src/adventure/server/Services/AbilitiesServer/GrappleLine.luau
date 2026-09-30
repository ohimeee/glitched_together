-- Miko, World 1 (mechanics.md §4): Swing on Grapple Rings or anything Kai froze; Pull light objects to her.
-- The swing itself runs on Miko's client for feel; the server only validates and can cut the line.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Net = require(ReplicatedStorage.Shared.Net)
local MoverService = require(script.Parent.Parent.MoverService)
local InteractableService = require(script.Parent.Parent.InteractableService)

local T = Tuning.GrappleLine
local GrappleLine = { BlockedBy = { "Downed", "InCutscene" }, Cooldowns = { [2] = T.PullCooldown } }

local toolResult = Net.event("ToolResult")
local swinging: { [Player]: Instance } = {}

local function rootOf(p: Player): BasePart?
	return p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function massOf(inst: Instance): number
	local attr = inst:GetAttribute("Mass")
	if type(attr) == "number" then
		return attr
	end
	if inst:IsA("BasePart") then
		return inst.AssemblyMass
	end
	return math.huge
end

local function pull(p: Player, target: Instance, root: BasePart)
	-- Levers: a pull throws them over; pulling again throws them back (the rope flicks out and back).
	local lever = Tags.find(target, "LeverPull")
	if lever then
		toolResult:FireAllClients("PullStart", p, lever)
		InteractableService.Toggle(lever)
		return
	end
	local part = if target:IsA("BasePart") then target else (target :: any).PrimaryPart
	if not part then
		return
	end
	local look = root.CFrame.LookVector * Vector3.new(1, 0, 1)
	local dest = root.Position + look.Unit * T.PullDistance + Vector3.new(0, 0.5, 0)
	local wasAnchored = part.Anchored
	part.Anchored = true
	toolResult:FireAllClients("PullStart", p, target)
	local tween =
		TweenService:Create(part, TweenInfo.new(T.PullTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = CFrame.new(dest) * part.CFrame.Rotation,
		})
	tween:Play()
	tween.Completed:Wait()
	part.Anchored = wasAnchored
	toolResult:FireAllClients("Pulled", p, target)
end

function GrappleLine.Use(p: Player, useIndex: number, target: Instance?)
	local root = rootOf(p)
	if not root then
		return
	end

	if useIndex == 1 then
		if not target then -- let go (always tell everyone, so no client keeps a stale rope)
			swinging[p] = nil
			toolResult:FireAllClients("GrappleEnd", p)
			return
		end
		local ring = Tags.find(target, "GrappleRing")
		local frozen = Tags.find(target, "Freezable")
		local anchor = ring or (if frozen and MoverService.IsFrozen(frozen) then frozen else nil)
		if not anchor then
			toolResult:FireClient(p, "GrappleDrop")
			return
		end
		if (Tags.position(anchor) - root.Position).Magnitude > T.Range + Tuning.SlackRange then
			toolResult:FireClient(p, "GrappleDrop")
			return
		end
		swinging[p] = anchor
		toolResult:FireAllClients("GrappleStart", p, anchor)
	elseif useIndex == 2 then
		local pullable = target and Tags.find(target, "Pullable")
		if not pullable then
			return
		end
		if (Tags.position(pullable) - root.Position).Magnitude > T.PullRange + Tuning.SlackRange then
			return
		end
		if massOf(pullable) > T.MaxMass then
			return
		end
		task.spawn(pull, p, pullable, root)
	end
end

function GrappleLine.Init()
	-- If Kai's freeze runs out mid-swing, the line snaps.
	MoverService.Resumed:Connect(function(inst: Instance)
		for p, anchor in swinging do
			if anchor == inst and not Tags.has(anchor, "GrappleRing") then
				swinging[p] = nil
				toolResult:FireClient(p, "GrappleDrop")
				toolResult:FireAllClients("GrappleEnd", p)
			end
		end
	end)
end

return GrappleLine
