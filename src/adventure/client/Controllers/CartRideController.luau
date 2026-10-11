-- Riding the Siege Cart (2P playtest Oct 11: "when you're in the cart I shouldn't slide because of the cart moving").
-- The cart is a server-owned physics assembly, so this client sees it a beat late and the humanoid's floor carry
-- slips: riders slid backwards as it rolled. While standing on a `Cart` model this keeps the character's spot on
-- the cart floor and adds only its own walking, every frame after physics. Walls still stop the walking (physics
-- pushes back next frame); jumping or stepping off ends the ride.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)

local player = Players.LocalPlayer

local CartRideController = {}

local function cartUnder(root: BasePart, character: Model): Model?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local hit = workspace:Raycast(root.Position, Vector3.new(0, -4.5, 0), params)
	local cart = hit and Tags.find(hit.Instance, "Cart")
	return if cart and cart:IsA("Model") then cart else nil
end

function CartRideController.Init()
	local riding: Model? = nil
	local rel: CFrame? = nil -- the root in the cart's space after last frame's correction
	RunService.Heartbeat:Connect(function(dt)
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (root and humanoid) or humanoid.FloorMaterial == Enum.Material.Air then
			riding, rel = nil, nil
			return
		end
		local cart = cartUnder(root, character :: Model)
		if not cart then
			riding, rel = nil, nil
			return
		end
		local cartCf = cart:GetPivot()
		if cart == riding and rel then
			-- where the cart carried our old spot, plus this frame's own walking; height stays with physics
			local carried = cartCf * rel
			local walk = humanoid.MoveDirection * humanoid.WalkSpeed * dt
			local target = Vector3.new(carried.X + walk.X, root.Position.Y, carried.Z + walk.Z)
			root.CFrame = root.CFrame.Rotation + target
			-- start the next physics step at the cart's speed, so the humanoid doesn't fight the correction
			local v = root.AssemblyLinearVelocity
			local cartV = (cart.PrimaryPart and cart.PrimaryPart:GetVelocityAtPosition(target)) or Vector3.zero
			root.AssemblyLinearVelocity = Vector3.new(
				cartV.X + humanoid.MoveDirection.X * humanoid.WalkSpeed,
				v.Y,
				cartV.Z + humanoid.MoveDirection.Z * humanoid.WalkSpeed
			)
		end
		riding = cart
		rel = cartCf:ToObjectSpace(root.CFrame)
	end)
end

return CartRideController
