-- Soft lock-on aiming for tools: the best tagged target inside a cone around the crosshair (screen center).
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Aim = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

function Aim.root(): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

function Aim.centerRay(): Ray
	local size = camera.ViewportSize
	return camera:ViewportPointToRay(size.X / 2, size.Y / 2)
end

-- What the crosshair is pointing at (ignores your own character).
function Aim.hit(distance: number): RaycastResult?
	rayParams.FilterDescendantsInstances = if player.Character then { player.Character } else {}
	local ray = Aim.centerRay()
	return workspace:Raycast(ray.Origin, ray.Direction * distance, rayParams)
end

-- Best instance with any of `tags` (and passing `accept`) within `range` of the character and
-- `coneDegrees` of the crosshair. Direct crosshair hits win.
function Aim.best(tags: { string }, range: number, coneDegrees: number, accept: ((Instance) -> boolean)?): Instance?
	local root = Aim.root()
	if not root then
		return nil
	end
	local direct = Aim.hit(range + 60)
	if direct then
		for _, tag in tags do
			local found = Tags.find(direct.Instance, tag)
			if
				found
				and (not accept or accept(found))
				and (Tags.position(found) - root.Position).Magnitude <= range
			then
				return found
			end
		end
	end

	local ray = Aim.centerRay()
	local cosCone = math.cos(math.rad(coneDegrees))
	local best, bestDot = nil, cosCone
	for _, tag in tags do
		for _, inst in CollectionService:GetTagged(tag) do
			if inst:IsDescendantOf(workspace) and (not accept or accept(inst)) then
				local pos = Tags.position(inst)
				if (pos - root.Position).Magnitude <= range then
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

return Aim
