-- Camera modes (design.md §7): Follow (a bit higher/wider than default), SideOn (classic platformer),
-- TopDown (castle, centered between both players, zooms out as they separate). Peek and cutscenes override it.
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
	if mode == "TopDown" then
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
	elseif mode == "SideOn" then
		camera.CameraType = Enum.CameraType.Scriptable
		if not a then
			return
		end
		local axis = (player:GetAttribute("SideAxis") or Vector3.new(0, 0, 1)) :: Vector3
		local focus = a.Position + Vector3.new(0, 4, 0)
		local eye = focus + axis.Unit * 42 + Vector3.new(0, 6, 0)
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(eye, focus), math.min(1, dt * 8))
	else
		if camera.CameraType ~= Enum.CameraType.Custom then
			camera.CameraType = Enum.CameraType.Custom
		end
	end
end

local function applyMode()
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
