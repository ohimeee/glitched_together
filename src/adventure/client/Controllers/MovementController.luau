-- The shared moveset (mechanics.md §2), run on the owning client for feel (implementation.md §7).
-- Double jump, air/ground dash, ground pound, crouch + long jump, sprint toggle, coyote time, jump buffer,
-- wall cling / wall jump, ledge assist, swing points, grind rails, jump vents, bounce-pad launches.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Net = require(ReplicatedStorage.Shared.Net)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local Input = require(script.Parent.Parent.Input)

local player = Players.LocalPlayer
local groundPoundEvent = Net.event("GroundPound")
local mashEvent = Net.event("RespawnMash")

local MovementController = {}

-- Swing state is module-level so tools (Grapple Line) can start and stop swings.
type Swing = {
	anchor: () -> Vector3?,
	length: number,
	boost: number,
	rope: Part,
	onEnd: (() -> ())?,
}

local current: {
	humanoid: Humanoid,
	root: BasePart,
	swing: Swing?,
	stopSwing: (boolean) -> (),
	startSwing: (anchor: () -> Vector3?, boost: number, onEnd: (() -> ())?) -> boolean,
}? =
	nil

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.RespectCanCollide = true

local function onCharacter(character: Model)
	local trove = Trove.new()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	local attachment = root:WaitForChild("RootAttachment") :: Attachment
	rayParams.FilterDescendantsInstances = { character }

	-- Our own Downed system replaces Roblox death.
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	humanoid.UseJumpPower = false
	humanoid.JumpHeight = Tuning.JumpHeight

	local airJumps, airDashes, lastGroundDash = 0, 0, -math.huge
	local pounding, crouching, sprinting = false, false, false
	local lastGrounded, jumpedSinceGround = os.clock(), false
	local lastJumpRequest, bufferedJumpAt = 0, -math.huge
	local movingSince: number? = nil
	local stillSince: number? = nil
	local cling: { normal: Vector3, started: number }? = nil
	local grind: { rail: BasePart, dir: number }? = nil
	local lastLedgeAssist = 0
	local swing: Swing? = nil

	local function inAir(): boolean
		local s = humanoid:GetState()
		return s == Enum.HumanoidStateType.Freefall
			or s == Enum.HumanoidStateType.Jumping
			or s == Enum.HumanoidStateType.PlatformStanding
	end

	local function blocked(): boolean
		return player:GetAttribute("InCutscene") == true or player:GetAttribute("Picking") == true
	end

	local function resetAir()
		airJumps, airDashes = 0, 0
	end

	local function burst(velocity: Vector3, duration: number)
		local lv = Instance.new("LinearVelocity")
		lv.Attachment0 = attachment
		lv.MaxForce = math.huge
		lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		lv.RelativeTo = Enum.ActuatorRelativeTo.World
		lv.VectorVelocity = velocity
		lv.Parent = root
		task.delay(duration, function()
			lv:Destroy()
		end)
	end

	local function setVelocity(v: Vector3)
		root.AssemblyLinearVelocity = v
	end

	-- Swing (Swing Points and Grapple Line) ---------------------------------------------
	local function stopSwing(jumped: boolean)
		local s = swing
		if not s then
			return
		end
		swing = nil
		if current then
			current.swing = nil
		end
		s.rope:Destroy()
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		if jumped then
			local v = root.AssemblyLinearVelocity * s.boost
			setVelocity(Vector3.new(v.X, math.max(v.Y, 0) + Tuning.DoubleJumpVelocity * 0.6, v.Z))
		end
		resetAir()
		if s.onEnd then
			task.spawn(s.onEnd)
		end
	end

	local function startSwing(anchor: () -> Vector3?, boost: number, onEnd: (() -> ())?): boolean
		local pos = anchor()
		if not pos or grind then
			return false
		end
		if swing then
			stopSwing(false)
		end
		local rope = Instance.new("Part")
		rope.Name = "SwingRope"
		rope.Anchored = true
		rope.CanCollide = false
		rope.CanQuery = false
		rope.CanTouch = false
		rope.Material = Enum.Material.Neon
		rope.Color = if player:GetAttribute("Role") == "Miko" then Color3.fromRGB(255, 170, 60) else Color3.new(1, 1, 1)
		rope.Size = Vector3.new(0.2, 0.2, 1)
		rope.Parent = workspace
		swing = {
			anchor = anchor,
			length = math.max((root.Position - pos).Magnitude, 6),
			boost = boost,
			rope = rope,
			onEnd = onEnd,
		}
		if current then
			current.swing = swing
		end
		pounding = false
		cling = nil
		humanoid.PlatformStand = true
		return true
	end

	local function stepSwing(dt: number)
		local s = swing :: Swing
		local anchorPos = s.anchor()
		if not anchorPos then
			stopSwing(false)
			return
		end
		local v = root.AssemblyLinearVelocity
		local steer = flat(humanoid.MoveDirection) * 60
		v += (Vector3.new(0, -Tuning.Gravity, 0) + steer) * dt
		local pos = root.Position + v * dt
		local offset = pos - anchorPos
		if offset.Magnitude > s.length then
			local n = offset.Unit
			pos = anchorPos + n * s.length
			local outward = v:Dot(n)
			if outward > 0 then
				v -= n * outward
			end
		end
		local facing = if flat(v).Magnitude > 1 then flat(v).Unit else root.CFrame.LookVector
		root.CFrame = CFrame.lookAt(pos, pos + facing)
		setVelocity(v)

		local mid = (pos + anchorPos) / 2
		local len = (pos - anchorPos).Magnitude
		s.rope.Size = Vector3.new(0.2, 0.2, len)
		s.rope.CFrame = CFrame.lookAt(mid, anchorPos)
	end

	-- Grind rails ---------------------------------------------------------------------
	local function railPoint(rail: BasePart, pos: Vector3): (Vector3, number)
		local localPos = rail.CFrame:PointToObjectSpace(pos)
		local half = rail.Size.Z / 2
		local z = math.clamp(localPos.Z, -half, half)
		local top = rail.CFrame * Vector3.new(0, rail.Size.Y / 2, z)
		return top, z
	end

	local function startGrind(rail: BasePart)
		if swing then
			return
		end
		local along = rail.CFrame.LookVector
		local dir = if root.AssemblyLinearVelocity:Dot(along) >= 0 then 1 else -1
		if flat(root.AssemblyLinearVelocity).Magnitude < 2 then
			dir = if root.CFrame.LookVector:Dot(along) >= 0 then 1 else -1
		end
		grind = { rail = rail, dir = dir }
		pounding = false
		cling = nil
		humanoid.PlatformStand = true
		resetAir()
	end

	local function stopGrind(jumped: boolean)
		local g = grind
		if not g then
			return
		end
		grind = nil
		humanoid.PlatformStand = false
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		local v = g.rail.CFrame.LookVector * g.dir * Tuning.GrindSpeed
		setVelocity(v + Vector3.new(0, if jumped then Tuning.DoubleJumpVelocity else 0, 0))
	end

	local function stepGrind(dt: number)
		local g = grind :: { rail: BasePart, dir: number }
		local rail = g.rail
		if not rail.Parent then
			stopGrind(false)
			return
		end
		local _, z = railPoint(rail, root.Position)
		z -= g.dir * Tuning.GrindSpeed * dt -- LookVector is -Z in object space
		local half = rail.Size.Z / 2
		if math.abs(z) > half then
			local link = rail:FindFirstChild("Next") :: ObjectValue?
			local nextRail = link and link.Value
			if nextRail and nextRail:IsA("BasePart") then
				g.rail = nextRail
				g.dir = if nextRail.CFrame.LookVector:Dot(rail.CFrame.LookVector * g.dir) >= 0 then 1 else -1
				return
			end
			stopGrind(false)
			return
		end
		local top = rail.CFrame * Vector3.new(0, rail.Size.Y / 2, z)
		local pos = top + rail.CFrame.UpVector * (humanoid.HipHeight + root.Size.Y / 2)
		local forward = rail.CFrame.LookVector * g.dir
		root.CFrame = CFrame.lookAt(pos, pos + forward)
		setVelocity(forward * Tuning.GrindSpeed)
	end

	local function nearestRail(maxDistance: number): BasePart?
		local best, bestDist = nil, maxDistance
		for _, rail in CollectionService:GetTagged("GrindRail") do
			if rail:IsA("BasePart") and rail:IsDescendantOf(workspace) then
				local top = railPoint(rail, root.Position)
				local d = (top - root.Position).Magnitude
				if d < bestDist then
					best, bestDist = rail, d
				end
			end
		end
		return best
	end

	-- Jumping -------------------------------------------------------------------------
	local function doubleJump()
		airJumps += 1
		local v = root.AssemblyLinearVelocity
		setVelocity(Vector3.new(v.X, Tuning.DoubleJumpVelocity, v.Z))
	end

	local function wallJump()
		local c = cling :: { normal: Vector3, started: number }
		cling = nil
		resetAir()
		setVelocity(c.normal * Tuning.WallJumpAway + Vector3.new(0, Tuning.WallJumpUp, 0))
		root.CFrame = CFrame.lookAt(root.Position, root.Position + c.normal)
	end

	local function onJumpPress()
		if blocked() then
			return
		end
		if player:GetAttribute("Downed") then
			if workspace:GetAttribute("BossFight") then
				mashEvent:FireServer()
			end
			return
		end
		if player:GetAttribute("NoJump") then
			return
		end
		if swing then
			stopSwing(true)
			return
		end
		if grind then
			stopGrind(true)
			return
		end
		if cling then
			wallJump()
			return
		end
		if not inAir() then
			-- Long jump: crouch + jump while moving keeps (and adds) momentum.
			if crouching and humanoid.MoveDirection.Magnitude > 0.1 then
				crouching = false
				local dir = flat(humanoid.MoveDirection).Unit
				task.defer(function()
					setVelocity(dir * Tuning.LongJumpForward + Vector3.new(0, Tuning.LongJumpUp, 0))
				end)
			end
			return -- normal jump is Roblox's own
		end
		if not jumpedSinceGround and os.clock() - lastGrounded <= Tuning.CoyoteTime then
			jumpedSinceGround = true
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			return
		end
		if airJumps < 1 and not pounding then
			doubleJump()
			return
		end
		bufferedJumpAt = os.clock()
	end

	trove:Add(UserInputService.JumpRequest:Connect(function()
		-- JumpRequest repeats every frame while held; only react to new presses.
		local now = os.clock()
		local fresh = now - lastJumpRequest > 0.12
		lastJumpRequest = now
		if fresh then
			onJumpPress()
		end
	end))

	trove:Add(humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping then
			jumpedSinceGround = true
		elseif new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			resetAir()
			cling = nil
			lastGrounded = os.clock()
			jumpedSinceGround = false
			if pounding then
				pounding = false
				groundPoundEvent:FireServer(root.Position)
			end
			if os.clock() - bufferedJumpAt <= Tuning.JumpBuffer and not player:GetAttribute("NoJump") then
				bufferedJumpAt = -math.huge
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		elseif new == Enum.HumanoidStateType.Freefall and not jumpedSinceGround then
			lastGrounded = os.clock() -- walked off a ledge: coyote window starts now
		end
	end))

	-- Dash ----------------------------------------------------------------------------
	trove:Add(Input.action("BaseContext", "Dash").Pressed:Connect(function()
		if blocked() or player:GetAttribute("Downed") or swing or grind then
			return
		end
		local kit = player:GetAttribute("Kit")
		if kit == "FireMage" or kit == "ShieldKnight" then
			return -- castle: Kai blinks, Miko shield-charges (their kit clients handle Dash)
		end
		local airborne = inAir()
		if airborne and airDashes >= 1 then
			return
		end
		if not airborne and os.clock() - lastGroundDash < Tuning.GroundDashCooldown then
			return
		end
		if airborne then
			airDashes += 1
		else
			lastGroundDash = os.clock()
		end
		cling = nil
		local dir = if humanoid.MoveDirection.Magnitude > 0
			then flat(humanoid.MoveDirection).Unit
			else root.CFrame.LookVector
		burst(dir * (Tuning.DashDistance / Tuning.DashTime), Tuning.DashTime)
	end))

	-- Ground pound (air) / crouch (ground) ------------------------------------------------
	local poundAction = Input.action("BaseContext", "GroundPound")
	trove:Add(poundAction.Pressed:Connect(function()
		if blocked() or player:GetAttribute("Downed") or swing or grind then
			return
		end
		if not inAir() then
			crouching = true
			return
		end
		if pounding then
			return
		end
		pounding = true
		cling = nil
		burst(Vector3.zero, Tuning.PoundHang) -- brief hang in the air
		task.delay(Tuning.PoundHang, function()
			if pounding then
				setVelocity(Vector3.new(0, -Tuning.PoundFallSpeed, 0))
			end
		end)
	end))
	trove:Add(poundAction.Released:Connect(function()
		crouching = false
	end))

	-- Sprint toggle and Swing grab --------------------------------------------------------
	trove:Add(Input.action("BaseContext", "Sprint").Pressed:Connect(function()
		sprinting = not sprinting
	end))

	trove:Add(Input.action("BaseContext", "Swing").Pressed:Connect(function()
		if blocked() or player:GetAttribute("Downed") then
			return
		end
		if swing then
			stopSwing(false)
			return
		end
		local rail = nearestRail(Tuning.GrindGrabRange)
		if rail then
			startGrind(rail)
			return
		end
		local best, bestDist = nil, Tuning.SwingRange
		for _, point in CollectionService:GetTagged("SwingPoint") do
			if point:IsDescendantOf(workspace) then
				local d = (Tags.position(point) - root.Position).Magnitude
				if d < bestDist then
					best, bestDist = point, d
				end
			end
		end
		if best then
			local point = best
			startSwing(function()
				return if point.Parent then Tags.position(point) else nil
			end, Tuning.SwingBoost)
		end
	end))

	-- Bounce-pad launch from the server ----------------------------------------------------
	trove:Add(Net.event("Launch").OnClientEvent:Connect(function(velocity: Vector3)
		stopSwing(false)
		stopGrind(false)
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		task.defer(function()
			setVelocity(flat(root.AssemblyLinearVelocity) + velocity)
		end)
		resetAir()
	end))

	-- Per-frame: speed, swing/grind stepping, wall cling, ledge assist, vents -------------
	trove:Add(RunService.Heartbeat:Connect(function(dt)
		if not root.Parent then
			return
		end
		local now = os.clock()
		local moving = humanoid.MoveDirection.Magnitude > 0.1

		-- Mobile auto-sprint after 1.5 s of movement; sprint cancels when you stop.
		if moving then
			stillSince = nil
			movingSince = movingSince or now
			if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
				if now - (movingSince :: number) >= Tuning.MobileAutoSprintAfter then
					sprinting = true
				end
			end
		else
			movingSince = nil
			stillSince = stillSince or now
			if sprinting and now - (stillSince :: number) > 0.3 then
				sprinting = false
			end
		end

		local speed = Tuning.WalkSpeed
		if blocked() then
			speed = 0
		elseif player:GetAttribute("Downed") then
			speed = Tuning.GhostSpeed
		elseif crouching and not inAir() then
			speed = Tuning.CrouchSpeed
		elseif sprinting then
			speed = Tuning.SprintSpeed
		end
		if player:GetAttribute("Blocking") then
			speed *= Tuning.Castle.ShieldSpeedMult
		end
		if ((player:GetAttribute("SlowUntil") or 0) :: number) > workspace:GetServerTimeNow() then
			speed *= 0.5 -- Static Mage slow orb
		end
		if player:GetAttribute("Picking") then
			speed = 0 -- level-up picker pauses the duo
		end
		humanoid.WalkSpeed = speed
		humanoid.JumpHeight = if player:GetAttribute("NoJump") or blocked() then 0 else Tuning.JumpHeight

		if swing then
			stepSwing(dt)
			return
		end
		if grind then
			stepGrind(dt)
			return
		end

		local v = root.AssemblyLinearVelocity
		local airborne = inAir()

		-- Land on a rail from above.
		if airborne and v.Y < 0 then
			local rail = nearestRail(2.5)
			if rail then
				startGrind(rail)
				return
			end
		end

		-- Wall cling on Clingable walls: slide at 4 studs/s for up to 1.5 s.
		if cling then
			if now - cling.started > Tuning.WallClingTime or not airborne then
				cling = nil
			else
				setVelocity(Vector3.new(0, -Tuning.WallClingSlide, 0))
				return
			end
		elseif airborne and moving and v.Y < 2 and not pounding then
			local dir = flat(humanoid.MoveDirection).Unit
			local hit = workspace:Raycast(root.Position, dir * 2.5, rayParams)
			if hit and Tags.find(hit.Instance, "Clingable") then
				cling = { normal = flat(hit.Normal).Unit, started = now }
				resetAir()
				return
			end
		end

		-- Ledge assist: a near-miss ledge pulls you up instead of letting you fall.
		if airborne and moving and v.Y < 8 and now - lastLedgeAssist > 0.3 then
			local dir = flat(humanoid.MoveDirection).Unit
			local feet = root.Position - Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2, 0)
			local wall = workspace:Raycast(feet + Vector3.new(0, 0.5, 0), dir * 2, rayParams)
			if wall and not Tags.find(wall.Instance, "Clingable") then
				local reach = Tuning.LedgeAssistReach
				local above = workspace:Raycast(root.Position + Vector3.new(0, reach, 0), dir * 2, rayParams)
				if not above then
					local probe = feet + dir * 2 + Vector3.new(0, reach + 0.5, 0)
					local top = workspace:Raycast(probe, Vector3.new(0, -(reach + 0.5), 0), rayParams)
					if top and top.Normal.Y > 0.7 then
						lastLedgeAssist = now
						local lift = top.Position.Y - feet.Y + 0.2
						root.CFrame += Vector3.new(0, lift, 0) + dir * 0.8
						setVelocity(dir * math.max(flat(v).Magnitude, 8))
					end
				end
			end
		end

		-- Jump vents: upward (or downward) air stream.
		for _, vent in CollectionService:GetTagged("JumpVent") do
			if vent:IsA("BasePart") and vent:IsDescendantOf(workspace) then
				local localPos = vent.CFrame:PointToObjectSpace(root.Position)
				local half = vent.Size / 2
				if
					math.abs(localPos.X) <= half.X
					and math.abs(localPos.Y) <= half.Y
					and math.abs(localPos.Z) <= half.Z
				then
					local dirSign = (vent:GetAttribute("Direction") or 1) :: number
					local target = Tuning.VentForce * dirSign
					setVelocity(Vector3.new(v.X, v.Y + (target - v.Y) * math.min(1, dt * 6), v.Z))
					resetAir()
					if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
						humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
					end
				end
			end
		end
	end))

	current = {
		humanoid = humanoid,
		root = root,
		swing = nil,
		stopSwing = stopSwing,
		startSwing = startSwing,
	}

	player.CharacterRemoving:Once(function()
		stopSwing(false)
		current = nil
		trove:Clean()
	end)
end

-- For tools: start a swing on a moving/static anchor. Returns false if it couldn't start.
function MovementController.StartSwing(anchor: () -> Vector3?, boost: number, onEnd: (() -> ())?): boolean
	return current ~= nil and current.startSwing(anchor, boost, onEnd)
end

function MovementController.StopSwing()
	if current then
		current.stopSwing(false)
	end
end

function MovementController.IsSwinging(): boolean
	return current ~= nil and current.swing ~= nil
end

function MovementController.Init()
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	player.CharacterAdded:Connect(onCharacter)
end

return MovementController
