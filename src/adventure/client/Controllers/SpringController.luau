-- Spring pad skins (ArtService tags them "SpringStretch"): the coil's foot stays on the pit floor and its board
-- follows the pad, so the spring squashes and stretches as it pumps instead of floating. Purely visual, per client.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)

local SpringController = {}

local springs: { [BasePart]: true } = {}

function SpringController.Init()
	Tags.each("SpringStretch", function(inst)
		if inst:IsA("BasePart") then
			springs[inst] = true
		end
	end, function(inst)
		springs[inst :: BasePart] = nil
	end)

	RunService.RenderStepped:Connect(function()
		for body in springs do
			local pad = body.Parent
			local floor = body:GetAttribute("Floor") :: number?
			local rotation = body:GetAttribute("Rotation") :: CFrame?
			if not (pad and pad:IsA("BasePart") and floor and rotation) then
				continue
			end
			local top = (pad.CFrame * Vector3.new(0, pad.Size.Y / 2, 0)).Y
			local height = math.max(top - floor, 0.5)
			body.Size = Vector3.new(body.Size.X, height, body.Size.Z)
			body.CFrame = CFrame.new(pad.Position.X, floor + height / 2, pad.Position.Z)
				* pad.CFrame.Rotation
				* rotation
		end
	end)
end

return SpringController
