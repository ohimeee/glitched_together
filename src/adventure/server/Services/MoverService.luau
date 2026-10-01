-- Every moving level piece runs through here, which is what makes the Pause Beam possible (implementation.md §8).
--
-- A `Mover` is a BasePart (or a Model with a PrimaryPart and welded parts) with a child Folder `Waypoints`
-- holding parts named 1, 2, 3… Attributes: Period (s per full cycle, default 4), Mode ("PingPong" | "Loop"),
-- Ease ("Sine" | "Linear"), Spin (deg/s around its own Y, for gears).
-- Each mover keeps its own time `t`; freezing = not advancing `t`, so it resumes exactly where it paused.
-- Driven = true: the mover doesn't run on its own. A Station (InteractableService) drives it between waypoint 1
-- (t = 0) and its last waypoint (t = Period / 2) with MoverService.Drive; nobody driving = it eases back to 1 at
-- ReturnRate (x real time, default 0.5). Freezing a driven mover holds it wherever it is.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)

local MoverService = {}

type Mover = {
	inst: Instance,
	root: BasePart,
	points: { CFrame },
	t: number,
	period: number,
	loop: boolean,
	sine: boolean,
	spin: number,
	pausedUntil: number,
	driven: boolean,
	drive: number, -- -1..1 from the Station (0 = nobody cranking: ease back)
	returnRate: number,
	alignPos: AlignPosition,
	alignRot: AlignOrientation,
}

type Physics = { velocity: Vector3, angular: Vector3, pausedUntil: number }

local movers: { [Instance]: Mover } = {}
local physics: { [BasePart]: Physics } = {}

local resumed = Instance.new("BindableEvent")
MoverService.Resumed = resumed.Event -- (inst)

local function rootOf(inst: Instance): BasePart?
	if inst:IsA("BasePart") then
		return inst
	elseif inst:IsA("Model") then
		return inst.PrimaryPart
	end
	return nil
end

local function pose(m: Mover): CFrame
	local n = #m.points
	if n == 0 then
		return m.root.CFrame
	end
	local base: CFrame
	if n == 1 then
		base = m.points[1]
	else
		local phase = (m.t / m.period) % 1
		local legs = if m.loop then n else n - 1
		local s: number
		if m.loop then
			s = phase
		else
			s = phase * 2
			if s > 1 then
				s = 2 - s
			end
		end
		local x = s * legs
		local leg = math.clamp(math.floor(x), 0, legs - 1)
		local alpha = x - leg
		if m.sine then
			alpha = (1 - math.cos(alpha * math.pi)) / 2
		end
		local a = m.points[leg + 1]
		local b = m.points[(leg + 1) % n + 1]
		base = a:Lerp(b, alpha)
	end
	if m.spin ~= 0 then
		base *= CFrame.Angles(0, math.rad(m.spin * m.t), 0)
	end
	return base
end

local function register(inst: Instance)
	if movers[inst] then
		return
	end
	local root = rootOf(inst)
	if not root then
		warn("[MoverService] Mover without a root part:", inst:GetFullName())
		return
	end

	local points = {}
	local folder = inst:FindFirstChild("Waypoints")
	if folder then
		local list = folder:GetChildren()
		table.sort(list, function(a, b)
			return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
		end)
		for _, wp in list do
			if wp:IsA("BasePart") then
				table.insert(points, wp.CFrame)
				wp.Transparency = 1
				wp.CanCollide = false
				wp.CanQuery = false
				wp.CanTouch = false
				wp.Anchored = true
			end
		end
	end
	if #points == 0 then
		points = { root.CFrame }
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "MoverAttachment"
	attachment.Parent = root
	local alignPos = Instance.new("AlignPosition")
	alignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
	alignPos.Attachment0 = attachment
	alignPos.RigidityEnabled = true
	alignPos.Parent = root
	local alignRot = Instance.new("AlignOrientation")
	alignRot.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignRot.Attachment0 = attachment
	alignRot.RigidityEnabled = true
	alignRot.Parent = root

	local m: Mover = {
		inst = inst,
		root = root,
		points = points,
		t = (inst:GetAttribute("Offset") or 0) :: number,
		period = (inst:GetAttribute("Period") or 4) :: number,
		loop = inst:GetAttribute("Mode") == "Loop",
		sine = inst:GetAttribute("Ease") ~= "Linear",
		spin = (inst:GetAttribute("Spin") or 0) :: number,
		pausedUntil = 0,
		driven = inst:GetAttribute("Driven") == true,
		drive = 0,
		returnRate = (inst:GetAttribute("ReturnRate") or 0.5) :: number,
		alignPos = alignPos,
		alignRot = alignRot,
	}
	movers[inst] = m

	local start = pose(m)
	if inst:IsA("Model") then
		inst:PivotTo(start * root.CFrame:ToObjectSpace(inst:GetPivot()))
	else
		root.CFrame = start
	end
	alignPos.Position = start.Position
	alignRot.CFrame = start.Rotation

	for _, part in (if inst:IsA("Model") then inst:GetDescendants() else { root }) :: { Instance } do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
	task.defer(function()
		if root:IsDescendantOf(workspace) and root:CanSetNetworkOwnership() then
			root:SetNetworkOwner(nil) -- server-owned so every client sees the same motion
		end
	end)
end

local function unregister(inst: Instance)
	movers[inst] = nil
end

local function setFrozenAttrs(inst: Instance, untilTime: number?)
	inst:SetAttribute("Frozen", if untilTime then true else nil)
	inst:SetAttribute("FrozenUntil", untilTime)
end

-- Freeze a mover or a loose physics object for `duration` seconds.
function MoverService.Pause(inst: Instance, duration: number)
	local untilServer = workspace:GetServerTimeNow() + duration
	local m = movers[inst]
	if m then
		m.pausedUntil = os.clock() + duration
		setFrozenAttrs(inst, untilServer)
		return
	end
	local root = rootOf(inst)
	if root and not root.Anchored then
		physics[root] = {
			velocity = root.AssemblyLinearVelocity,
			angular = root.AssemblyAngularVelocity,
			pausedUntil = os.clock() + duration,
		}
		root.Anchored = true
		setFrozenAttrs(inst, untilServer)
	elseif root and physics[root] then
		physics[root].pausedUntil = os.clock() + duration
		setFrozenAttrs(inst, untilServer)
	elseif inst:GetAttribute("Freezable") ~= false then
		-- Anything else (enemies, bosses) reads the Frozen attribute itself.
		setFrozenAttrs(inst, untilServer)
		task.delay(duration, function()
			if inst:GetAttribute("FrozenUntil") == untilServer then
				MoverService.Resume(inst)
			end
		end)
	end
end

function MoverService.Resume(inst: Instance)
	local m = movers[inst]
	if m then
		m.pausedUntil = 0
	end
	local root = rootOf(inst)
	local p = root and physics[root]
	if root and p then
		physics[root] = nil
		root.Anchored = false
		root.AssemblyLinearVelocity = p.velocity
		root.AssemblyAngularVelocity = p.angular
	end
	if inst:GetAttribute("Frozen") then
		setFrozenAttrs(inst, nil)
		resumed:Fire(inst)
	end
end

-- Station input for a Driven mover: -1..1 (0 = let go, it eases back).
function MoverService.Drive(inst: Instance, axis: number)
	local m = movers[inst]
	if m then
		m.drive = math.clamp(axis, -1, 1)
	end
end

-- How far a mover is along its path, 0..1 (Driven movers: 0 = home, 1 = fully out).
function MoverService.Progress(inst: Instance): number
	local m = movers[inst]
	if not m then
		return 0
	end
	local phase = (m.t / m.period) % 1
	return if phase <= 0.5 then phase * 2 else 2 - phase * 2
end

function MoverService.IsFrozen(inst: Instance): boolean
	return inst:GetAttribute("Frozen") == true
end

function MoverService.Init()
	Tags.each("Mover", register, unregister)

	RunService.Heartbeat:Connect(function(dt)
		local now = os.clock()
		for inst, m in movers do
			if not m.root.Parent then
				movers[inst] = nil
				continue
			end
			if m.pausedUntil > 0 then
				if now < m.pausedUntil then
					continue
				end
				MoverService.Resume(inst)
			end
			if m.driven then
				local rate = if m.drive ~= 0 then m.drive else -m.returnRate
				m.t = math.clamp(m.t + rate * dt, 0, m.period / 2)
			else
				m.t += dt
			end
			local cf = pose(m)
			m.alignPos.Position = cf.Position
			m.alignRot.CFrame = cf.Rotation
		end
		for root, p in physics do
			if now >= p.pausedUntil then
				local inst = Tags.find(root, "Freezable") or root
				MoverService.Resume(inst)
			end
		end
	end)
end

return MoverService
