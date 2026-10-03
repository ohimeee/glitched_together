-- The lobby bed is a trampoline (LobbyRoom tags the mattress and quilt "Bouncy"): landing on it throws you back up,
-- higher if you hold jump. Local and purely for fun while waiting for a partner.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local BOUNCE = 46 -- studs/s up on a plain landing
local BOUNCE_JUMP = 72 -- with jump held

local player = Players.LocalPlayer

local function hook(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	humanoid.StateChanged:Connect(function(_, new)
		if new ~= Enum.HumanoidStateType.Landed then
			return
		end
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -6, 0), params)
		if hit and CollectionService:HasTag(hit.Instance, "Bouncy") then
			local up = if UserInputService:IsKeyDown(Enum.KeyCode.Space) then BOUNCE_JUMP else BOUNCE
			local vel = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(vel.X, up, vel.Z)
		end
	end)
end

if player.Character then
	task.spawn(hook, player.Character)
end
player.CharacterAdded:Connect(hook)
