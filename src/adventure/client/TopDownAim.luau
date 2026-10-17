-- Top-down aiming for the castle kits (implementation.md §8 "Aiming"): the mouse ray (or the right stick's
-- direction) hits a flat plane at the character's height; the character turns to face that point and a small
-- reticle marks it. Tools read TopDownAim.point() and send it to the server as `aim`.
-- Touch, and a gamepad with the right stick at rest (mobile + console pass): auto-aim at the nearest enemy in front
-- (Tuning.Touch.AimRange / AimCone around where you walk or face), else straight ahead.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CollectionService = game:GetService("CollectionService")

local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local Glyphs = require(ReplicatedStorage.Shared.Util.Glyphs)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local TopDownAim = {}

local trove = Trove.new()
local users = 0
local current: Vector3? = nil
local stick = Vector2.zero

local function rootOf(): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function humanoid(): Humanoid?
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

-- where you walk (or face, standing still), flat
local function heading(root: BasePart): Vector3
	local hum = humanoid()
	local move = if hum then hum.MoveDirection else Vector3.zero
	local v = if move.Magnitude > 0.1 then move else root.CFrame.LookVector
	v = Vector3.new(v.X, 0, v.Z)
	return if v.Magnitude > 0.01 then v.Unit else Vector3.zAxis
end

local function autoAim(root: BasePart): Vector3
	local ahead = heading(root)
	local cosCone = math.cos(math.rad(Tuning.Touch.AimCone))
	local best, bestDist = nil, Tuning.Touch.AimRange
	for _, enemy in CollectionService:GetTagged("Enemy") do
		if
			enemy:IsDescendantOf(workspace)
			and not enemy:GetAttribute("Dormant")
			and (enemy:GetAttribute("HP") or 1) > 0
		then
			local pos = Tags.position(enemy)
			local flat = Vector3.new(pos.X - root.Position.X, 0, pos.Z - root.Position.Z)
			local dist = flat.Magnitude
			if
				dist < bestDist
				and math.abs(pos.Y - root.Position.Y) < 30
				and (dist < 4 or flat.Unit:Dot(ahead) > cosCone)
			then
				best, bestDist = pos, dist
			end
		end
	end
	if best then
		return Vector3.new(best.X, root.Position.Y, best.Z)
	end
	return root.Position + ahead * 20
end

local function compute(root: BasePart): Vector3
	local device = Glyphs.device()
	if device == "Touch" or (device == "Gamepad" and stick.Magnitude <= 0.3) then
		return autoAim(root)
	end
	if stick.Magnitude > 0.3 then
		-- right stick: camera-relative direction on the floor
		local look = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z).Unit
		local right = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z).Unit
		return root.Position + (right * stick.X + look * stick.Y).Unit * 20
	end
	local mouse = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	local planeY = root.Position.Y
	if math.abs(ray.Direction.Y) < 1e-3 then
		return root.Position + root.CFrame.LookVector * 20
	end
	local t = (planeY - ray.Origin.Y) / ray.Direction.Y
	if t < 0 then
		return root.Position + root.CFrame.LookVector * 20
	end
	return ray.Origin + ray.Direction * t
end

-- The aim point (world space, at character height).
function TopDownAim.point(): Vector3
	local root = rootOf()
	if not root then
		return Vector3.zero
	end
	return current or compute(root)
end

-- Flat unit direction from the character to the aim point.
function TopDownAim.direction(): Vector3
	local root = rootOf()
	if not root then
		return Vector3.zAxis
	end
	local v = TopDownAim.point() - root.Position
	v = Vector3.new(v.X, 0, v.Z)
	return if v.Magnitude > 0.1 then v.Unit else Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z).Unit
end

-- Reference-counted: both castle kits call Start/Stop.
function TopDownAim.Start(color: Color3)
	users += 1
	if users > 1 then
		return
	end
	local reticle = trove:Add(Instance.new("Part"))
	reticle.Name = "AimReticle"
	reticle.Shape = Enum.PartType.Cylinder
	reticle.Size = Vector3.new(0.15, 2.4, 2.4)
	reticle.Material = Enum.Material.Neon
	reticle.Color = Palette.ForNeon(color)
	reticle.Transparency = 0.35
	reticle.Anchored = true
	reticle.CanCollide = false
	reticle.CanQuery = false
	reticle.CanTouch = false
	reticle.CastShadow = false
	reticle.Parent = workspace

	trove:Add(UserInputService.InputChanged:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Thumbstick2 then
			stick = Vector2.new(input.Position.X, input.Position.Y)
		end
	end))

	trove:Add(RunService.RenderStepped:Connect(function()
		local root = rootOf()
		local hum = humanoid()
		if not root or not hum then
			return
		end
		current = compute(root)
		local point = current :: Vector3
		reticle.CFrame = CFrame.new(point.X, root.Position.Y - 2.9, point.Z) * CFrame.Angles(0, 0, math.rad(90))
		if player:GetAttribute("Downed") or player:GetAttribute("Picking") then
			hum.AutoRotate = true
			return
		end
		hum.AutoRotate = false
		local flat = Vector3.new(point.X, root.Position.Y, point.Z)
		if (flat - root.Position).Magnitude > 0.5 then
			root.CFrame = CFrame.lookAt(root.Position, flat)
		end
	end))
end

function TopDownAim.Stop()
	users = math.max(0, users - 1)
	if users > 0 then
		return
	end
	trove:Clean()
	current = nil
	local hum = humanoid()
	if hum then
		hum.AutoRotate = true
	end
end

return TopDownAim
