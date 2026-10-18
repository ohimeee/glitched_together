-- Soft lock-on aiming for tools: the best tagged target inside a cone around the crosshair. The crosshair is the
-- screen center while the mouse-look camera has the cursor locked, on a gamepad and on touch (user: a tap moved the
-- crosshair; phones turn the camera by dragging and lean on the lock-on cone); otherwise (side-on scenes, Alt held)
-- it's wherever the cursor is (playtest Oct 1: side-on bats couldn't be aimed at).
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Glyphs = require(ReplicatedStorage.Shared.Util.Glyphs)
local Settings = require(ReplicatedStorage.Shared.Util.Settings)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Aim = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

function Aim.root(): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local usingTouch = false
UserInputService.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		usingTouch = true
	elseif
		input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.MouseButton1
	then
		usingTouch = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		usingTouch = false
	end
end)

-- Where the crosshair is, in viewport pixels (matches the HUD, which ignores the GUI inset).
function Aim.screenPoint(): Vector2
	local size = camera.ViewportSize
	if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
		return size / 2
	end
	-- gamepad and touch: the screen center (the camera follows the right stick / a drag)
	if usingTouch or Glyphs.device() == "Gamepad" or Glyphs.device() == "Touch" then
		return size / 2
	end
	return UserInputService:GetMouseLocation()
end

-- True when the crosshair sits in the middle (mouse-look); false when it follows the cursor / touch.
function Aim.centered(): boolean
	return UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
end

function Aim.centerRay(): Ray
	local point = Aim.screenPoint()
	return camera:ViewportPointToRay(point.X, point.Y)
end

-- What the crosshair is pointing at (ignores your own character). `group`: the collision group the ray acts as
-- (rays pass through whatever that group can't collide with; Code Layer objects need "MikoShifted").
function Aim.hit(distance: number, group: string?): RaycastResult?
	rayParams.FilterDescendantsInstances = if player.Character then { player.Character } else {}
	rayParams.CollisionGroup = group or "Default"
	local ray = Aim.centerRay()
	return workspace:Raycast(ray.Origin, ray.Direction * distance, rayParams)
end

-- Best instance with any of `tags` (and passing `accept`) within `range` of the character (to its nearest point)
-- and `coneDegrees` of the crosshair. Direct crosshair hits win. `group`: see Aim.hit.
function Aim.best(
	tags: { string },
	range: number,
	coneDegrees: number,
	accept: ((Instance) -> boolean)?,
	group: string?
): Instance?
	local root = Aim.root()
	if not root then
		return nil
	end
	local direct = Aim.hit(range + 60, group)
	if direct then
		for _, tag in tags do
			local found = Tags.find(direct.Instance, tag)
			if found and (not accept or accept(found)) and Tags.distance(found, root.Position) <= range then
				return found
			end
		end
	end

	local ray = Aim.centerRay()
	-- the settings menu's aim assist scales every lock-on cone (0 = only what the crosshair is on)
	local assist = Settings.Get("AutoAim") :: number
	if assist <= 0 then
		return nil
	end
	local cosCone = math.cos(math.rad(math.min(coneDegrees * assist, 89)))
	local best, bestDot = nil, cosCone
	for _, tag in tags do
		for _, inst in CollectionService:GetTagged(tag) do
			if inst:IsDescendantOf(workspace) and (not accept or accept(inst)) then
				local pos = Tags.position(inst)
				if Tags.distance(inst, root.Position) <= range then
					local dot = (pos - ray.Origin).Unit:Dot(ray.Direction.Unit)
					if dot > bestDot then
						best, bestDot = inst, dot
					end
				end
			end
		end
	end
	return best
end

-- Touch drag on a held tool button (PASTE): finger offset in screen px from the press, nil = none
local drag: Vector2? = nil
function Aim.SetDrag(offset: Vector2?)
	drag = offset
end
function Aim.drag(): Vector2?
	return drag
end

return Aim
