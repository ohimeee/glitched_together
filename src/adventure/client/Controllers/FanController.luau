-- Vent fan blades (ArtService/VentFan tags them "FanBlades"): spun locally on each client at the model's `Speed`
-- attribute (radians per second; the sign flips with the vent's direction). Purely visual.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)

local FanController = {}

local fans: { [Model]: { home: CFrame, angle: number } } = {}

function FanController.Init()
	Tags.each("FanBlades", function(inst)
		if inst:IsA("Model") then
			fans[inst] = { home = inst:GetPivot(), angle = 0 }
		end
	end, function(inst)
		fans[inst :: Model] = nil
	end)

	RunService.RenderStepped:Connect(function(dt)
		for model, fan in fans do
			local speed = (model:GetAttribute("Speed") or 0) :: number
			if speed ~= 0 and model.PrimaryPart then
				fan.angle = (fan.angle + speed * dt) % (2 * math.pi)
				-- turn about the world's up axis through the hub (the hub cylinder itself lies rotated)
				model:PivotTo(CFrame.new(fan.home.Position) * CFrame.Angles(0, fan.angle, 0) * fan.home.Rotation)
			end
		end
	end)
end

return FanController
