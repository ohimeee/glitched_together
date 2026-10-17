-- The shared moveset (mechanics.md §2), run on the owning client for feel (implementation.md §7).
-- Double jump, air/ground dash, ground pound, crouch + long jump, sprint toggle, coyote time, jump buffer,
-- wall cling / wall jump, ledge assist, swing points, grind rails, jump vents, bounce-pad launches.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local ToolFx = require(ReplicatedStorage.Shared.Config.ToolFx)
local Net = require(ReplicatedStorage.Shared.Net)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local Glyphs = require(ReplicatedStorage.Shared.Util.Glyphs)
local Input = require(script.Parent.Parent.Input)
local MoveAnim = require(script.Parent.MoveAnimController)

local player = Players.LocalPlayer
local groundPoundEvent = Net.event("GroundPound")

local MovementController = {}

-- Swing state is module-level so tools (Grapple Line) can start and stop swings.
type Swing = {
	anchor: () -> Vector3?,
	length: number,
	boost: number,
	rope: { Instance }, -- drawn rope (swing points only: the Grapple Line's rope is ToolFxController's)
	anchorAt: Attachment?,
	target: number, -- rope length it reels in to
	plane: Vector3, -- flat unit axis the swing moves along ("forward": the way you came)
	angle: number, -- radians from straight down, + = forward along plane
	omega: number, -- radians/s
	pose: RBXScriptConnection?, -- hanging pose (arms up on the rope)
	blocked: number, -- seconds the swing has been stuck against something
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

-- A tool's own grab for the Swing key (Miko's Grapple Line), tried when there is no rail or swing point to take.
local swingFallback: (() -> ())? = nil

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
	local grind: { rail: BasePart, dir: number, z: number }? = nil
	local lastLedgeAssist = 0
	local poundStarted = 0
	local fallSpeed = 0 -- last downward speed in the air (Landed fires after the stop)
	local lastVent = -math.huge -- last time inside an upward jump vent stream (you bob in and out at its top)
	local swing: Swing? = nil

	local function inAir(): boolean
		local s = humanoid:GetState()
		return s == Enum.HumanoidStateType.Freefall
			or s == Enum.HumanoidStateType.Jumping
			or s == Enum.HumanoidStateType.PlatformStanding
	end

	local function blocked(): boolean
		return player:GetAttribute("InCutscene") == true
			or player:GetAttribute("Picking") == true
			or player:GetAttribute("Station") ~= nil -- cranking a Station roots you
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
		player:SetAttribute("Swinging", nil) -- local only: SwingPromptController hides its chips
		if current then
			current.swing = nil
		end
		for _, inst in s.rope do
			inst:Destroy()
		end
		if s.pose then
			s.pose:Disconnect()
		end
		humanoid.PlatformStand = false
		-- stand back up (the body leaned along the rope), facing the way we fly
		local fly = flat(root.AssemblyLinearVelocity)
		local look = if fly.Magnitude > 1 then fly.Unit else s.plane
		root.CFrame = CFrame.lookAt(root.Position, root.Position + look)
		root.AssemblyAngularVelocity = Vector3.zero
		humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		if jumped then
			-- jump off forward (the way you came), stronger the faster you swing forward: time it at the front
			local v = root.AssemblyLinearVelocity
			local forward = math.max(v:Dot(s.plane), 0) * s.boost + Tuning.SwingJumpForward
			local up = math.max(v.Y, 0) + Tuning.DoubleJumpVelocity * 0.6
			setVelocity(s.plane * forward + Vector3.new(0, up, 0))
		end
		resetAir()
		if s.onEnd then
			task.spawn(s.onEnd)
		end
	end

	local reelTarget: (anchorPos: Vector3) -> number
	local swingPlane: (anchorPos: Vector3) -> Vector3

	-- Hanging pose while swinging: both arms up on the rope, legs slightly forward, knees bent. Set on every
	-- Stepped (after the Animator writes its pose). Local only for now (Motor6D.Transform doesn't replicate).
	local function hangPose(): RBXScriptConnection?
		local function joint(part: string, name: string): Motor6D?
			local p = character:FindFirstChild(part)
			local j = p and p:FindFirstChild(name)
			return if j and j:IsA("Motor6D") then j else nil
		end
		local pose = {
			{ joint("RightUpperArm", "RightShoulder"), CFrame.Angles(math.pi, 0, math.rad(-8)) },
			{ joint("LeftUpperArm", "LeftShoulder"), CFrame.Angles(math.pi, 0, math.rad(8)) },
			{ joint("RightUpperLeg", "RightHip"), CFrame.Angles(math.rad(-20), 0, 0) },
			{ joint("LeftUpperLeg", "LeftHip"), CFrame.Angles(math.rad(-10), 0, 0) },
			{ joint("RightLowerLeg", "RightKnee"), CFrame.Angles(math.rad(35), 0, 0) },
			{ joint("LeftLowerLeg", "LeftKnee"), CFrame.Angles(math.rad(25), 0, 0) },
		}
		return RunService.Stepped:Connect(function()
			for _, entry in pose do
				local j = entry[1] :: Motor6D?
				if j then
					j.Transform = entry[2]
				end
			end
		end)
	end

	local function startSwing(anchor: () -> Vector3?, boost: number, onEnd: (() -> ())?, drawRope: boolean?): boolean
		local pos = anchor()
		if not pos or grind then
			return false
		end
		if swing then
			stopSwing(false)
		end
		local rope: { Instance } = {}
		local anchorAt: Attachment? = nil
		local hand = character:FindFirstChild("RightGripAttachment", true) :: Attachment?
		if drawRope and hand then
			-- a braided rope from the hand to the point (same look as the Grapple Line's)
			local a = Instance.new("Attachment")
			a.Name = "SwingAnchor"
			a.Position = pos
			a.Parent = workspace.Terrain
			anchorAt = a
			local beam = Instance.new("Beam")
			beam.Attachment0 = hand
			beam.Attachment1 = a
			beam.Texture = ToolFx.Textures.Rope
			beam.TextureMode = Enum.TextureMode.Static
			beam.TextureLength = 2
			beam.Width0 = Tuning.ToolFx.RopeWidth
			beam.Width1 = Tuning.ToolFx.RopeWidth
			beam.FaceCamera = true
			beam.Segments = 1
			beam.Parent = a
			rope = { a }
		end
		local plane = swingPlane(pos)
		local offset = root.Position - pos
		local length = math.max(offset.Magnitude, Tuning.SwingMinLength)
		local angle = math.atan2(offset:Dot(plane), -offset.Y)
		local tangent = plane * math.cos(angle) + Vector3.yAxis * math.sin(angle)
		swing = {
			anchor = anchor,
			length = length,
			target = reelTarget(pos),
			plane = plane,
			angle = angle,
			omega = root.AssemblyLinearVelocity:Dot(tangent) / length, -- keep the run-up
			boost = boost,
			rope = rope,
			anchorAt = anchorAt,
			pose = if MoveAnim.Has("Swing") then nil else hangPose(), -- the Swing clip, else the scripted hang
			blocked = 0,
			onEnd = onEnd,
		}
		player:SetAttribute("Swinging", true)
		if current then
			current.swing = swing
		end
		pounding = false
		cling = nil
		humanoid.PlatformStand = true
		return true
	end

	-- How long the rope ends up: at most SwingMaxLength, and short enough that the low point of the arc clears
	-- the floor under the anchor (a far ring grabbed from the ground zips you up instead of dragging you through it).
	function reelTarget(anchorPos: Vector3): number
		local length = math.max((root.Position - anchorPos).Magnitude, Tuning.SwingMinLength)
		local target = math.min(length, Tuning.SwingMaxLength)
		local below = workspace:Raycast(anchorPos, Vector3.new(0, -(target + 12), 0), rayParams)
		if below then
			target = math.min(target, anchorPos.Y - below.Position.Y - Tuning.SwingGroundGap)
		end
		return math.max(target, 3)
	end

	-- The swing's plane ("forward"): the way you came (run-up), else from you toward the point, else the camera's
	-- facing: you always swing on toward where you were heading.
	function swingPlane(anchorPos: Vector3): Vector3
		local run = flat(root.AssemblyLinearVelocity)
		if run.Magnitude > 4 then
			return run.Unit
		end
		local toward = flat(anchorPos - root.Position)
		if toward.Magnitude > 2 then
			return toward.Unit
		end
		local look = flat(workspace.CurrentCamera.CFrame.LookVector)
		return if look.Magnitude > 0.01 then look.Unit else Vector3.zAxis
	end

	-- An assisted pendulum in one vertical plane: angle from straight down, eased into a steady arc
	-- (Tuning.SwingArc) so every swing reads the same and you only time the jump.
	local function stepSwing(dt: number)
		local s = swing :: Swing
		local anchorPos = s.anchor()
		if not anchorPos then
			stopSwing(false)
			return
		end
		local g = Tuning.SwingGravity
		-- A/D slowly turn the plane
		local input = flat(humanoid.MoveDirection)
		local side = s.plane:Cross(Vector3.yAxis)
		local turn = input:Dot(side) * Tuning.SwingTurnRate * dt
		if math.abs(turn) > 1e-4 then
			s.plane = CFrame.fromAxisAngle(Vector3.yAxis, -turn):VectorToWorldSpace(s.plane)
		end
		-- reel in (a far grab zips toward the point first)
		local reel = 0
		if s.length > s.target then
			reel = math.min(Tuning.SwingReelSpeed * dt, s.length - s.target)
			s.length -= reel
		end
		local L = s.length
		-- pendulum + assist toward the arc: ω² = 2g/L (cos θ − cos A) at every point of that arc
		s.omega += -(g / L) * math.sin(s.angle) * dt
		local arc = math.rad(Tuning.SwingArc)
		local want2 = 2 * g / L * (math.cos(s.angle) - math.cos(arc))
		local want = math.sqrt(math.max(want2, 0))
		local dir = if s.omega > 0.05 then 1 elseif s.omega < -0.05 then -1 elseif s.angle <= 0 then 1 else -1
		if want2 > 0 then
			s.omega += (dir * want - s.omega) * math.min(1, Tuning.SwingAssist * dt)
		elseif math.abs(s.angle) > arc then
			s.omega *= 1 - math.min(1, Tuning.SwingAssist * dt) -- past the arc (a fast run-up): calm it down
		end
		local maxOmega = Tuning.SwingMaxSpeed / L
		s.omega = math.clamp(s.omega, -maxOmega, maxOmega)
		local nextAngle = s.angle + s.omega * dt

		local function pointAt(theta: number): Vector3
			return anchorPos + (s.plane * math.sin(theta) - Vector3.yAxis * math.cos(theta)) * L
		end
		local pos = pointAt(nextAngle)
		-- the body is moved by hand, so it must not pass through floors or walls: stop the swing there
		local move = pos - root.Position
		local hit = if move.Magnitude > 0.01 then workspace:Raycast(root.Position, move, rayParams) else nil
		if hit then
			-- bump: bounce back a little (a reel still lifts you clear); stuck for a moment = let go and land
			s.omega = -s.omega * Tuning.SwingBounce
			pos = root.Position
			s.blocked += dt
			if s.blocked > Tuning.SwingStuckTime then
				stopSwing(false)
				return
			end
		else
			s.angle = nextAngle
			s.blocked = 0
		end
		local tangent = s.plane * math.cos(s.angle) + Vector3.yAxis * math.sin(s.angle)
		local v = tangent * s.omega * L + (anchorPos - pos).Unit * (reel / math.max(dt, 1e-3))

		-- hang from the rope: the body leans along it, facing forward along the swing
		local up = Vector3.yAxis:Lerp((anchorPos - pos).Unit, Tuning.SwingLean).Unit
		local look = s.plane - up * s.plane:Dot(up)
		if look.Magnitude > 0.01 then
			local right = look.Unit:Cross(up).Unit
			local target = CFrame.fromMatrix(pos, right, up)
			root.CFrame = root.CFrame.Rotation:Lerp(target.Rotation, math.min(1, dt * 12)) + pos
		else
			root.CFrame = root.CFrame.Rotation + pos
		end
		setVelocity(v)
		if s.anchorAt then
			s.anchorAt.Position = anchorPos
		end
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
		local _, z = railPoint(rail, root.Position)
		grind = { rail = rail, dir = dir, z = z }
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
		local g = grind :: { rail: BasePart, dir: number, z: number }
		local rail = g.rail
		if not rail.Parent then
			stopGrind(false)
			return
		end
		-- advance a stored position along the rail (re-reading root.Position double-counted the velocity set below,
		-- so grinds ran at ~2x GrindSpeed)
		local z = g.z - g.dir * Tuning.GrindSpeed * dt -- LookVector is -Z in object space
		local half = rail.Size.Z / 2
		if math.abs(z) > half then
			-- curved rails are chains of short segments: off the far end (local -Z) → Next, off the near end → Prev
			local link = rail:FindFirstChild(if z < 0 then "Next" else "Prev") :: ObjectValue?
			local nextRail = link and link.Value
			if nextRail and nextRail:IsA("BasePart") then
				g.dir = if nextRail.CFrame.LookVector:Dot(rail.CFrame.LookVector * g.dir) >= 0 then 1 else -1
				g.rail = nextRail
				rail = nextRail
				-- keep riding this frame on the new segment: carry the overshoot past the old end (no hitch, no gain)
				local over = math.abs(z) - half
				local h2 = rail.Size.Z / 2
				z = math.clamp(if g.dir == 1 then h2 - over else -h2 + over, -h2, h2)
			else
				stopGrind(false)
				return
			end
		end
		g.z = z
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
		Audio.play("DoubleJump", root)
		MoveAnim.Play("DoubleJump")
		local v = root.AssemblyLinearVelocity
		setVelocity(Vector3.new(v.X, Tuning.DoubleJumpVelocity, v.Z))
	end

	local function wallJump()
		local c = cling :: { normal: Vector3, started: number }
		cling = nil
		resetAir()
		Audio.play("WallJump", root)
		MoveAnim.Play("WallJump")
		setVelocity(c.normal * Tuning.WallJumpAway + Vector3.new(0, Tuning.WallJumpUp, 0))
		root.CFrame = CFrame.lookAt(root.Position, root.Position + c.normal)
	end

	local function onJumpPress()
		if blocked() then
			return
		end
		if player:GetAttribute("Downed") then
			return -- mashing to respawn: ReviveController
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
				Audio.play("LongJump", root)
				MoveAnim.Play("LongJump")
				task.defer(function()
					setVelocity(dir * Tuning.LongJumpForward + Vector3.new(0, Tuning.LongJumpUp, 0))
					-- hold the horizontal speed through the rise (the humanoid's air control would otherwise
					-- brake it to walk speed at once); vertical stays free so gravity still arcs the jump
					local lv = Instance.new("LinearVelocity")
					lv.Attachment0 = attachment
					lv.MaxForce = math.huge
					lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
					lv.RelativeTo = Enum.ActuatorRelativeTo.World
					lv.PrimaryTangentAxis = Vector3.xAxis
					lv.SecondaryTangentAxis = Vector3.zAxis
					lv.PlaneVelocity = Vector2.new(dir.X, dir.Z) * Tuning.LongJumpForward
					lv.Parent = root
					task.delay(Tuning.LongJumpHold, function()
						lv:Destroy()
					end)
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
				MoveAnim.Play("PoundLand")
				Audio.play("PoundImpact", root)
				Audio.play("PoundDebris", root)
				groundPoundEvent:FireServer(root.Position)
			elseif fallSpeed < -Tuning.MoveAnim.HardLandSpeed then
				MoveAnim.Play("Land")
			end
			fallSpeed = 0
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
		Audio.play("Dash", root)
		MoveAnim.Play("Dash")
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
		Audio.play("PoundStart", root)
		MoveAnim.Play("PoundSpin")
		poundStarted = os.clock()
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
			Audio.play("Swing", root)
			startSwing(function()
				return if point.Parent then Tags.position(point) else nil
			end, Tuning.SwingBoost, nil, true)
		elseif swingFallback then
			swingFallback()
		end
	end))

	-- Launches from the server (bounce pads, Release-launchers) ----------------------------------
	-- Straight up keeps your run speed; a launch with its own horizontal part replaces it and holds it through the
	-- flight (the humanoid's air control would brake it to walk speed at once), like the long jump.
	trove:Add(Net.event("Launch").OnClientEvent:Connect(function(velocity: Vector3, sound: string?)
		Audio.play(sound or "BouncePad", root)
		stopSwing(false)
		stopGrind(false)
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		local side = flat(velocity)
		task.defer(function()
			setVelocity(if side.Magnitude > 0.1 then velocity else flat(root.AssemblyLinearVelocity) + velocity)
			if side.Magnitude <= 0.1 then
				return
			end
			local lv = Instance.new("LinearVelocity")
			lv.Attachment0 = attachment
			lv.MaxForce = math.huge
			lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
			lv.RelativeTo = Enum.ActuatorRelativeTo.World
			lv.PrimaryTangentAxis = Vector3.xAxis
			lv.SecondaryTangentAxis = Vector3.zAxis
			lv.PlaneVelocity = Vector2.new(side.X, side.Z)
			lv.Parent = root
			local start = os.clock()
			local conn: RBXScriptConnection
			conn = RunService.Heartbeat:Connect(function()
				local t = os.clock() - start
				local landed = t > 0.2 and humanoid.FloorMaterial ~= Enum.Material.Air
				if landed or t > Tuning.ReleaseLaunch.MaxHold or not lv.Parent or swing or grind then
					conn:Disconnect()
					lv:Destroy()
				end
			end)
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

		-- Touch + gamepad auto-sprint after 1.5 s of movement (console pass: L3 still toggles it); stopping cancels it.
		if moving then
			stillSince = nil
			movingSince = movingSince or now
			if
				(UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
				or Glyphs.device() == "Gamepad"
			then
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

		-- looping move animations follow the state
		local hide = blocked() or player:GetAttribute("Downed") == true
		local grounded = not inAir()
		local run = flat(root.AssemblyLinearVelocity).Magnitude
		MoveAnim.Set("Swing", swing ~= nil and not hide)
		MoveAnim.Set("Grind", grind ~= nil and not hide)
		MoveAnim.Set("WallCling", cling ~= nil and not hide)
		MoveAnim.Set("PoundFall", pounding and not hide and now - poundStarted >= Tuning.PoundHang)
		MoveAnim.Set("VentFloat", now - lastVent < Tuning.MoveAnim.VentFloatHold and not pounding and not hide)
		MoveAnim.Set("Crouch", crouching and grounded and not moving and not hide)
		MoveAnim.Set("CrouchWalk", crouching and grounded and moving and not hide)
		MoveAnim.Set(
			"Sprint",
			sprinting and grounded and moving and not crouching and not hide and run > Tuning.WalkSpeed + 2,
			math.max(run / Tuning.SprintSpeed, 0.6)
		)

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
		if airborne then
			fallSpeed = v.Y
		end

		-- Land on a rail from above. A fast fall can touch down on the (solid) rail between two frames, so standing
		-- on top of one catches it too (only from above: walking past a rail end at its height doesn't).
		if (airborne and v.Y < 0) or not airborne then
			local rail = nearestRail(Tuning.GrindCatchRange)
			if rail and (airborne or root.Position.Y - railPoint(rail, root.Position).Y > 2) then
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
						MoveAnim.Play("LedgeAssist")
						local lift = top.Position.Y - feet.Y + 0.2
						root.CFrame += Vector3.new(0, lift, 0) + dir * 0.8
						setVelocity(dir * math.max(flat(v).Magnitude, 8))
					end
				end
			end
		end

		-- Jump vents: upward (or downward) air stream. Riding an upward one: flip in, then float.
		local venting = false
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
					venting = venting or dirSign > 0
					local target = Tuning.VentForce * dirSign
					setVelocity(Vector3.new(v.X, v.Y + (target - v.Y) * math.min(1, dt * 6), v.Z))
					resetAir()
					if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
						humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
					end
				end
			end
		end
		if venting then
			if now - lastVent > Tuning.MoveAnim.VentFlipGap and not pounding then
				MoveAnim.Play("VentFlip")
			end
			lastVent = now
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

-- For tools: what the Swing key (F / RB / GRAB) does when no rail or swing point is in reach. nil clears it.
function MovementController.SetSwingFallback(fn: (() -> ())?)
	swingFallback = fn
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
