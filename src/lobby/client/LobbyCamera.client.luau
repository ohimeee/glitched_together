-- The lobby's own orbit camera (user, Oct 19: the settings menu's camera rows only worked in the adventure, because the
-- lobby used Roblox's camera). Same feel and settings as the adventure's CameraController (sensitivity per device,
-- invert Y, FOV offset), but the mouse stays free so capsules, boards, the tip jar and menus stay clickable:
-- hold right-click to look (like Roblox's camera), wheel / pinch zooms, right stick turns, a drag on the screen turns.
-- Walls pull the camera in so the bedroom furniture never hides you.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Settings = require(ReplicatedStorage.Shared.Util.Settings)

local C = Tuning.Camera
local L = Tuning.LobbyCamera
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- (Roblox shift lock is already off for the lobby: lobby.project.json EnableMouseLockOption)

local yaw, pitch = 0, math.rad(-12)
local distance = L.Distance
local looking = false -- right mouse held
local touchLook: InputObject? = nil -- the screen drag that turns the camera (not the thumbstick)
local stick = Vector2.zero

local function sens(key: string): number
	return Settings.Get(key) :: number
end
local function invert(): number
	return if Settings.Get("InvertY") then -1 else 1
end

local function turn(dx: number, dy: number)
	yaw -= dx
	pitch = math.clamp(pitch - dy * invert(), math.rad(C.PitchMin), math.rad(C.PitchMax))
end

UserInputService.InputBegan:Connect(function(input, processed)
	local t = input.UserInputType
	if t == Enum.UserInputType.MouseButton2 and not processed then
		looking = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	elseif t == Enum.UserInputType.Touch and not processed and not touchLook then
		touchLook = input
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		looking = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	elseif input == touchLook then
		touchLook = nil
	elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
		stick = Vector2.zero
	end
end)

UserInputService.InputChanged:Connect(function(input, processed)
	local t = input.UserInputType
	if t == Enum.UserInputType.MouseMovement and looking then
		local k = C.MouseSensitivity * sens("MouseSensitivity")
		turn(input.Delta.X * k, input.Delta.Y * k)
	elseif t == Enum.UserInputType.MouseWheel and not processed then
		distance = math.clamp(distance - input.Position.Z * L.ZoomStep, L.MinDistance, L.MaxDistance)
	elseif input == touchLook then
		local k = C.TouchSensitivity * sens("TouchSensitivity")
		turn(input.Delta.X * k, input.Delta.Y * k)
	elseif input.KeyCode == Enum.KeyCode.Thumbstick2 then
		stick = Vector2.new(input.Position.X, input.Position.Y)
	end
end)

-- pinch to zoom on touch
UserInputService.TouchPinch:Connect(function(_, scale, _, state, processed)
	if not processed and state == Enum.UserInputState.Change then
		distance = math.clamp(distance / math.max(scale, 0.01) ^ 0.05, L.MinDistance, L.MaxDistance)
	end
end)

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local started = false
RunService:BindToRenderStep("LobbyCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then
		return
	end
	if not started then
		-- start behind the character
		started = true
		local look = root.CFrame.LookVector
		yaw = math.atan2(-look.X, -look.Z)
	end
	camera.CameraType = Enum.CameraType.Scriptable

	-- right stick (a small dead zone; full stick = StickSpeed rad/s like the adventure)
	if stick.Magnitude > 0.15 then
		local k = C.StickSpeed * sens("GamepadSensitivity") * dt
		turn(stick.X * k, -stick.Y * k)
	end

	local pivot = root.Position + Vector3.new(0, L.PivotHeight, 0)
	local rot = CFrame.fromEulerAnglesYXZ(pitch, yaw, 0)
	local want = pivot - rot.LookVector * distance
	-- walls and furniture pull the camera in (never through the bedroom)
	params.FilterDescendantsInstances = { character }
	local hit = workspace:Raycast(pivot, want - pivot, params)
	local at = if hit then hit.Position + hit.Normal * 0.6 else want
	camera.CFrame = CFrame.lookAt(at, pivot)
	camera.FieldOfView = L.FOV + sens("FovOffset")
	-- very close: hide the character so the view isn't a wall of hair
	local close = (at - pivot).Magnitude < 1.5
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			(d :: any).LocalTransparencyModifier = if close then 1 else 0
		end
	end
end)
