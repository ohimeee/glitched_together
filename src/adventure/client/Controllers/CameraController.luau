-- Camera modes (design.md §7): Follow (a bit higher/wider than default), SideOn (classic platformer),
-- TopDown (castle, centered between both players, zooms out as they separate). Peek and cutscenes override it.
-- Camera zones: a part tagged `CameraZone` (attributes Mode, e.g. "SideOn", and Axis = the side the camera sits on)
-- switches the mode while your character is inside it, then hands back to the world's mode.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CameraController = {}

local HEIGHT, BACK = 55, 30
local FOLLOW_FOV = 74
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

local function step(dt: number)
	if override then
		local target = override()
		if target then
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = camera.CFrame:Lerp(target, math.min(1, dt * 10))
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
	if m == "TopDown" then
		camera.CameraType = Enum.CameraType.Scriptable
		if not a then
			return
		end
		local b = rootOf(partner())
		local mid = if b then (a.Position + b.Position) / 2 else a.Position
		local spread = if b then (a.Position - b.Position).Magnitude else 0
		local zoom = math.clamp(1 + spread / 60, 1, 1.6)
		local eye = mid + Vector3.new(0, HEIGHT * zoom, BACK * zoom)
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
		if camera.CameraType ~= Enum.CameraType.Custom then
			camera.CameraType = Enum.CameraType.Custom
		end
	end
end

function applyMode()
	mode = (player:GetAttribute("CameraMode") or "Follow") :: string
	if mode == "Follow" then
		camera.CameraType = Enum.CameraType.Custom
		camera.FieldOfView = FOLLOW_FOV
		-- Start a bit further out than Roblox's default so players see more of the level.
		player.CameraMaxZoomDistance = 60
		player.CameraMinZoomDistance = 18
		task.delay(0.2, function()
			player.CameraMinZoomDistance = 6
		end)
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
	player:GetAttributeChangedSignal("CameraMode"):Connect(applyMode)
	applyMode()
	if not bound then
		bound = true
		RunService:BindToRenderStep("GlitchedCamera", Enum.RenderPriority.Camera.Value + 1, step)
	end
end

return CameraController
