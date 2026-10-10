-- Camera modes (design.md §7): Follow (third-person mouse-look like It Takes Two: the mouse turns the camera with the
-- cursor locked, the crosshair is the screen center, both mouse buttons stay free for tools; hold Alt for a
-- cursor; gamepad right stick / touch drag turn it too), SideOn (classic platformer),
-- TopDown (castle, centered between both players, zooms out as they separate). Peek and cutscenes override it.
-- Camera zones: a part tagged `CameraZone` (attributes Mode, e.g. "SideOn", and Axis = the side the camera sits on)
-- switches the mode while your character is inside it, then hands back to the world's mode.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Input = require(script.Parent.Parent.Input)
local MovementController = require(script.Parent.MovementController)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local C = Tuning.Camera

local CameraController = {}

local HEIGHT, BACK = 55, 30

-- Follow (orbit) state
local yaw, pitch = 0, math.rad(-15)
local distance = C.Distance
local shoulder = 0 -- 0..1, eased in while a tool is held (the crosshair sits beside the body, not on it)
local stick = Vector2.zero
local wasFollow = false
local relockAt = 0 -- when the cursor last re-locked: the first mouse deltas after that are the cursor jumping to center
local camParams = RaycastParams.new()
camParams.FilterType = Enum.RaycastFilterType.Exclude
camParams.RespectCanCollide = true
local mode = "Follow"
local override: (() -> CFrame?)? = nil
local bound = false

local function rootOf(p: Player?): BasePart?
	local c = p and p.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function partner(): Player?
	local myRole = player:GetAttribute("Role")
	for _, p in Players:GetPlayers() do
		if p ~= player and p:GetAttribute("Role") and p:GetAttribute("Role") ~= myRole then
			return p
		end
	end
	return nil
end

local function zoneAt(pos: Vector3): BasePart?
	for _, zone in CollectionService:GetTagged("CameraZone") do
		if zone:IsA("BasePart") then
			local lp = zone.CFrame:PointToObjectSpace(pos)
			local h = zone.Size / 2
			if math.abs(lp.X) <= h.X and math.abs(lp.Y) <= h.Y and math.abs(lp.Z) <= h.Z then
				return zone
			end
		end
	end
	return nil
end

local currentZone: BasePart? = nil
local applyMode: () -> ()

-- Follow: orbit the head from yaw/pitch/distance. Looking up never sinks the camera into the floor: it stays a
-- little above the ground and keeps looking up from there, so you can see what is overhead (grapple rings).
local function followStep(dt: number, root: BasePart?)
	camera.CameraType = Enum.CameraType.Scriptable
	if not wasFollow then
		-- entering Follow: keep looking the way the camera already faces
		local look = camera.CFrame.LookVector
		yaw = math.atan2(-look.X, -look.Z)
		wasFollow = true
	end
	yaw -= stick.X * C.StickSpeed * dt
	pitch = math.clamp(pitch + stick.Y * C.StickSpeed * dt, math.rad(C.PitchMin), math.rad(C.PitchMax))
	if not root then
		return
	end
	local want = if player:GetAttribute("Kit") then 1 else 0
	shoulder += (want - shoulder) * math.min(1, dt * 6)

	local rot = CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
	local pivot = root.Position + Vector3.new(0, C.PivotHeight, 0)
	camParams.FilterDescendantsInstances = if player.Character then { player.Character } else {}

	-- shoulder first (stop short of a wall beside us), then back along the view
	local side = rot:VectorToWorldSpace(C.Shoulder * shoulder)
	local sideHit = if side.Magnitude > 0.01 then workspace:Raycast(pivot, side, camParams) else nil
	if sideHit then
		side = side.Unit * math.max(0, sideHit.Distance - 0.5)
	end
	local base = pivot + side
	local eye = base + rot:VectorToWorldSpace(Vector3.new(0, 0, distance))
	-- looking up: the eye never drops below the floor the character stands on (it looks up from low instead)
	local floor = workspace:Raycast(root.Position, Vector3.new(0, -12, 0), camParams)
	local floorY = if floor then floor.Position.Y else root.Position.Y - 3
	if eye.Y < floorY + C.GroundClearance then
		eye = Vector3.new(eye.X, floorY + C.GroundClearance, eye.Z)
	end
	-- walls between the head and the eye pull the camera in
	local toEye = eye - base
	local wall = if toEye.Magnitude > 0.01 then workspace:Raycast(base, toEye, camParams) else nil
	if wall then
		eye = base + toEye.Unit * math.max(0.5, wall.Distance - 0.6)
	end
	camera.CFrame = CFrame.new(eye) * rot.Rotation
	camera.Focus = CFrame.new(pivot)
	-- a little wider while swinging fast
	local speed = if MovementController.IsSwinging() then root.AssemblyLinearVelocity.Magnitude else 0
	local fov = C.FOV + math.clamp(speed / Tuning.SwingMaxSpeed, 0, 1) * C.SwingFovBoost
	camera.FieldOfView += (fov - camera.FieldOfView) * math.min(1, dt * 4)
end

-- The cursor is locked (mouse-look) in Follow mode unless a menu/cutscene needs it or Alt is held.
local function wantsLock(m: string): boolean
	return m == "Follow"
		and override == nil
		and not Input.isEnabled("MenuContext")
		and not UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
		and UserInputService.MouseEnabled
end

local function step(dt: number)
	if override then
		local target = override()
		if target then
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = camera.CFrame:Lerp(target, math.min(1, dt * 10))
			wasFollow = false
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
			return
		end
	end

	local a = rootOf(player)
	local zone = if a then zoneAt(a.Position) else nil
	if zone ~= currentZone then
		currentZone = zone
		if zone then
			camera.FieldOfView = 60
		else
			applyMode() -- leaving a zone: back to the world's camera
		end
	end
	local m = if zone then (zone:GetAttribute("Mode") or mode) :: string else mode
	local lock = wantsLock(m)
	if lock and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
		relockAt = os.clock()
	end
	UserInputService.MouseBehavior = if lock then Enum.MouseBehavior.LockCenter else Enum.MouseBehavior.Default
	-- with a tool out and the cursor free (side-on scenes, Alt), the HUD crosshair follows the cursor instead of the
	-- mouse icon; menus and cutscenes (MenuContext) always get the normal cursor
	local toolAim = player:GetAttribute("Kit") ~= nil and m ~= "TopDown" and not Input.isEnabled("MenuContext")
	UserInputService.MouseIconEnabled = not lock and not toolAim
	if m ~= "Follow" then
		wasFollow = false
	end
	if m == "TopDown" then
		camera.CameraType = Enum.CameraType.Scriptable
		if not a then
			return
		end
		local b = rootOf(partner())
		local mid = if b then (a.Position + b.Position) / 2 else a.Position
		local spread = if b then (a.Position - b.Position).Magnitude else 0
		-- a boss can pull the view toward itself so it stays in frame (workspace TopDownFocus + weight 0..1)
		local focus = workspace:GetAttribute("TopDownFocus")
		if typeof(focus) == "Vector3" then
			local w = (workspace:GetAttribute("TopDownFocusWeight") or 0.35) :: number
			mid = mid:Lerp(Vector3.new(focus.X, mid.Y, focus.Z), w)
		end
		-- a boss hall can pull the view back (workspace TopDownZoom, set by the Hollow Dragon fight)
		local zoom = math.clamp(1 + spread / 60, 1, 1.6) * ((workspace:GetAttribute("TopDownZoom") or 1) :: number)
		-- ...and look from the other side (workspace TopDownFlip): the boss at the far end fills the top of the screen
		local back = (if workspace:GetAttribute("TopDownFlip") then -BACK else BACK)
			* (workspace:GetAttribute("TopDownBack") or 1) :: number -- flatter angle: a tall boss stays in frame
		local eye = mid + Vector3.new(0, HEIGHT * zoom, back * zoom)
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(eye, mid), math.min(1, dt * 8))
	elseif m == "SideOn" then
		camera.CameraType = Enum.CameraType.Scriptable
		if not a then
			return
		end
		local axis = (
			(zone and zone:GetAttribute("Axis"))
			or player:GetAttribute("SideAxis")
			or Vector3.new(0, 0, 1)
		) :: Vector3
		local focus = a.Position + Vector3.new(0, 4, 0)
		local eye = focus + axis.Unit * 42 + Vector3.new(0, 6, 0)
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(eye, focus), math.min(1, dt * 8))
	else
		followStep(dt, a)
	end
end

function applyMode()
	mode = (player:GetAttribute("CameraMode") or "Follow") :: string
	if mode == "Follow" then
		camera.FieldOfView = C.FOV
	else
		camera.FieldOfView = 60
	end
end

-- Peek/cutscenes: a function returning the wanted CFrame (or nil to fall through to the normal mode).
function CameraController.SetOverride(fn: (() -> CFrame?)?)
	override = fn
	if not fn then
		applyMode()
	end
end

function CameraController.Mode(): string
	return mode
end

function CameraController.Init()
	local minPitch, maxPitch = math.rad(C.PitchMin), math.rad(C.PitchMax)
	UserInputService.InputChanged:Connect(function(input, processed)
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseMovement then
			if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter and os.clock() - relockAt > 0.25 then
				yaw -= input.Delta.X * C.MouseSensitivity
				pitch = math.clamp(pitch - input.Delta.Y * C.MouseSensitivity, minPitch, maxPitch)
			end
		elseif t == Enum.UserInputType.MouseWheel and not processed then
			distance = math.clamp(distance - input.Position.Z * 2, C.MinDistance, C.MaxDistance)
		elseif t == Enum.UserInputType.Touch and not processed then
			yaw -= input.Delta.X * C.TouchSensitivity
			pitch = math.clamp(pitch - input.Delta.Y * C.TouchSensitivity, minPitch, maxPitch)
		elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
			local v = Vector2.new(input.Position.X, input.Position.Y)
			stick = if v.Magnitude > 0.15 then v else Vector2.zero
		end
	end)
	player:GetAttributeChangedSignal("CameraMode"):Connect(applyMode)
	applyMode()
	if not bound then
		bound = true
		RunService:BindToRenderStep("GlitchedCamera", Enum.RenderPriority.Camera.Value + 1, step)
	end
end

return CameraController
