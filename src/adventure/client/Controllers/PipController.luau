-- Pip in the world: floats between the duo facing the camera ("hovers between them", Story Line), and flies
-- to your shoulder when a hint arrives. Its glow takes the color of whoever it talks to (art-direction.md §5):
-- white while floating between you, your role color while it talks to you. Local-only copy of ReplicatedStorage.PipModel (published by ArtService);
-- if the meshes never load, the hint bubble still works on its own.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Net = require(ReplicatedStorage.Shared.Net)
local Roles = require(ReplicatedStorage.Shared.Config.Roles)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local T = Tuning.Pip

local PipController = {}

local function partner(): Player?
	local myRole = player:GetAttribute("Role")
	for _, p in Players:GetPlayers() do
		local role = p:GetAttribute("Role")
		if p ~= player and role and role ~= myRole then
			return p
		end
	end
	return nil
end

local function rootOf(p: Player?): BasePart?
	local character = p and p.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function PipController.Init()
	task.spawn(function()
		local template = ReplicatedStorage:WaitForChild("PipModel", 60) :: Model?
		if not template then
			return
		end
		local pip = template:Clone()
		pip:ScaleTo(T.Scale)
		for _, d in pip:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
			end
		end
		pip.Parent = workspace

		local glow = pip:FindFirstChildWhichIsA("PointLight", true)
		local hintUntil = 0
		Net.event("Hint").OnClientEvent:Connect(function()
			hintUntil = os.clock() + T.HintTime
			local role = (Roles :: any)[player:GetAttribute("Role") or ""]
			if glow then
				glow.Color = if role then role.Color else Palette.Duo
			end
			task.delay(T.HintTime, function()
				if glow and os.clock() >= hintUntil then
					glow.Color = Palette.Duo
				end
			end)
		end)

		local pos: Vector3? = nil
		RunService.RenderStepped:Connect(function(dt)
			local me = rootOf(player)
			if not me then
				return
			end
			local target: Vector3
			if os.clock() < hintUntil then
				-- beside your head, on the camera's right, so it reads as talking to you
				target = me.Position + camera.CFrame.RightVector * 3 + Vector3.new(0, 3, 0)
			else
				local other = rootOf(partner())
				local mid = if other and (other.Position - me.Position).Magnitude < T.Leash
					then (me.Position + other.Position) / 2
					else me.Position
				target = mid + Vector3.new(0, T.Height, 0)
			end
			target += Vector3.new(0, math.sin(os.clock() * T.BobSpeed) * T.BobHeight, 0)

			pos = if pos then pos:Lerp(target, 1 - math.exp(-dt * T.Sharpness)) else target
			local at = pos :: Vector3
			local look = Vector3.new(camera.CFrame.Position.X, at.Y, camera.CFrame.Position.Z)
			if (look - at).Magnitude > 0.1 then
				pip:PivotTo(CFrame.lookAt(at, look)) -- Pip's face is its -Z side
			end
		end)
	end)
end

return PipController
