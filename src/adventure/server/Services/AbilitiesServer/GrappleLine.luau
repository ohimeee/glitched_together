-- Miko, World 1 (mechanics.md §4): Swing on Grapple Rings or anything Kai froze; Pull light objects to her.
-- The swing itself runs on Miko's client for feel; the server only validates and can cut the line.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Net = require(ReplicatedStorage.Shared.Net)
local MoverService = require(script.Parent.Parent.MoverService)
local InteractableService = require(script.Parent.Parent.InteractableService)
local ContraptionService = require(script.Parent.Parent.ContraptionService)

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

-- Crates are heavy (user, Oct 17: players must not push them with their bodies): max density, high friction, and
-- the server owns their physics, so no client shoves one locally. Only Miko's pull moves them.
local function heavy(part: BasePart)
	if part.Anchored or not part:IsDescendantOf(workspace) then
		return
	end
	part.CustomPhysicalProperties = PhysicalProperties.new(T.CrateDensity, 1, 0, 100, 100)
	if part:CanSetNetworkOwnership() then
		part:SetNetworkOwner(nil)
	end
end

local function pull(p: Player, target: Instance, root: BasePart)
	-- Levers: a pull throws them over; pulling again throws them back (the rope flicks out and back).
	local lever = Tags.find(target, "LeverPull")
	if lever then
		toolResult:FireAllClients("PullStart", p, lever)
		InteractableService.Toggle(lever)
		return
	end
	-- "?" blocks (Coin Bonk Stairs): a pull bonks it and a coin step pops out; the block stays put
	local bonk = Tags.find(target, "BonkBlock")
	if bonk then
		toolResult:FireAllClients("PullStart", p, bonk)
		ContraptionService.Bonk(bonk)
		return
	end
	local part = if target:IsA("BasePart") then target else (target :: any).PrimaryPart
	if not part then
		return
	end
	-- Predictable pulls (playtest Oct 1: "the box is random"): the object comes straight at Miko along the line
	-- between them, stops PullDistance in front of her (short of any wall), and lands flat on the floor, upright,
	-- with no drop or tumble. Pulling it up onto a ledge (user, Oct 17: "so hard to put it above") lifts it first: the
	-- wall check runs at the height it ends at, so the ledge it climbs over doesn't stop it.
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { part, p.Character :: Instance }
	params.RespectCanCollide = true
	params.IgnoreWater = true
	local flatTo = (part.Position - root.Position) * Vector3.new(1, 0, 1)
	local dir = if flatTo.Magnitude > 0.1 then flatTo.Unit else root.CFrame.LookVector * Vector3.new(1, 0, 1)
	local half = part.Size.Y / 2
	local start = part.Position
	-- rest on the floor under a spot
	local function restY(at: Vector3): number
		local floor = workspace:Raycast(at + Vector3.new(0, 4, 0), Vector3.new(0, -30, 0), params)
		return if floor then floor.Position.Y + half else at.Y
	end
	local dest = root.Position + dir * T.PullDistance
	local lift = math.max(start.Y, restY(dest)) + 0.1
	-- don't pass through walls on the way in (checked level at the carry height, so a shelf or ledge under it doesn't count)
	local path = (dest - start) * Vector3.new(1, 0, 1)
	local wall = if path.Magnitude > 0.1
		then workspace:Raycast(Vector3.new(start.X, lift, start.Z), path, params)
		else nil
	if wall then
		local keep = math.max(0, wall.Distance - math.max(part.Size.X, part.Size.Z) / 2)
		dest = start + path.Unit * keep
	end
	-- landing near a crate-only plate: settle on its middle, square (user, Oct 17: it leaned on the plate's edge)
	for _, plate in CollectionService:GetTagged("PressurePlate") do
		if plate:IsA("BasePart") and plate:GetAttribute("HeavyOnly") and plate:IsDescendantOf(workspace) then
			local flat = (plate.Position - dest) * Vector3.new(1, 0, 1)
			local mine = (plate.Position - root.Position) * Vector3.new(1, 0, 1)
			if flat.Magnitude <= T.PlateSnap and mine.Magnitude > plate.Size.X / 2 + 2 then
				dest = Vector3.new(plate.Position.X, dest.Y, plate.Position.Z)
				break
			end
		end
	end
	-- nothing to land on (a gap between it and Miko): it stays put rather than drop into the void
	if not workspace:Raycast(Vector3.new(dest.X, lift + 4, dest.Z), Vector3.new(0, -30, 0), params) then
		return
	end
	local y = restY(Vector3.new(dest.X, lift, dest.Z))
	local yaw = math.atan2(-dir.X, -dir.Z)
	local goal = CFrame.new(dest.X, y, dest.Z) * CFrame.Angles(0, yaw, 0)
	-- two legs: up then in (onto a ledge), or in then down (off one), so it never cuts through an edge
	local legs = { goal }
	if math.abs(y - start.Y) > 0.5 then
		local mid = if y > start.Y then Vector3.new(start.X, y, start.Z) else Vector3.new(dest.X, start.Y, dest.Z)
		legs = { CFrame.new(mid) * goal.Rotation, goal }
	end

	local wasAnchored = part.Anchored
	part.Anchored = true
	part.CustomPhysicalProperties = PhysicalProperties.new(part.CurrentPhysicalProperties.Density, 1, 0, 100, 100)
	toolResult:FireAllClients("PullStart", p, target)
	for i, cf in legs do
		local style = if i == #legs then Enum.EasingStyle.Quad else Enum.EasingStyle.Sine
		local info = TweenInfo.new(T.PullTime * (if #legs > 1 then 0.6 else 1), style, Enum.EasingDirection.Out)
		local tween = TweenService:Create(part, info, { CFrame = cf })
		tween:Play()
		tween.Completed:Wait()
	end
	part.AssemblyLinearVelocity = Vector3.zero
	part.AssemblyAngularVelocity = Vector3.zero
	part.Anchored = wasAnchored
	heavy(part) -- unanchoring hands ownership back to auto
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
		if Tags.distance(anchor, root.Position) > T.Range + Tuning.SlackRange then
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
		if Tags.distance(pullable, root.Position) > T.PullRange + Tuning.SlackRange then
			return
		end
		if massOf(pullable) > T.MaxMass then
			return
		end
		task.spawn(pull, p, pullable, root)
	end
end

-- The anchor this player is swinging from (a ring or a frozen object), if any.
function GrappleLine.SwingTarget(p: Player): Instance?
	return swinging[p]
end

function GrappleLine.Init()
	Tags.each("Pullable", function(inst)
		if inst:IsA("BasePart") and inst.Name == "Crate" then
			heavy(inst)
			inst.AncestryChanged:Connect(function()
				heavy(inst)
			end)
		end
	end)
	-- a kit change (zone, world, boss phase) ends the swing: no stale anchor or rope carries into the next kit
	local function watch(p: Player)
		p:GetAttributeChangedSignal("Kit"):Connect(function()
			if swinging[p] then
				swinging[p] = nil
				toolResult:FireAllClients("GrappleEnd", p)
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		swinging[p] = nil
	end)
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
