-- Vent fan blades (ArtService/VentFan tags them "FanBlades"): spun locally on each client at the model's `Speed`
-- attribute (radians per second; the sign flips with the vent's direction). Purely visual.
-- The spin pivot comes from the model's `Home` attribute (set by the server), and each blade part is placed from its
-- own offset to it, taken as the part arrives: with StreamingEnabled the Model can stream in before its parts (an
-- empty Model's pivot is the world origin, which once spun a fan on the Prologue's first save pad).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)

local FanController = {}

type Fan = { home: CFrame, angle: number, parts: { [BasePart]: CFrame }, conns: { RBXScriptConnection } }
local fans: { [Model]: Fan } = {}

local function track(model: Model)
	local home = model:GetAttribute("Home") :: CFrame?
	if not home then
		return
	end
	local parts = {}
	-- the server never moves the blades, so a part arrives at its server placement
	local function add(p: Instance)
		if p:IsA("BasePart") then
			parts[p] = home:ToObjectSpace(p.CFrame)
		end
	end
	for _, p in model:GetChildren() do
		add(p)
	end
	fans[model] = {
		home = home,
		angle = 0,
		parts = parts,
		conns = {
			model.ChildAdded:Connect(add),
			model.ChildRemoved:Connect(function(p)
				parts[p :: BasePart] = nil
			end),
		},
	}
end

local function untrack(model: Model)
	local fan = fans[model]
	if fan then
		for _, c in fan.conns do
			c:Disconnect()
		end
		fans[model] = nil
	end
end

function FanController.Init()
	Tags.each("FanBlades", function(inst)
		if inst:IsA("Model") then
			track(inst)
		end
	end, function(inst)
		untrack(inst :: Model)
	end)

	RunService.RenderStepped:Connect(function(dt)
		for model, fan in fans do
			local speed = (model:GetAttribute("Speed") or 0) :: number
			if speed ~= 0 then
				fan.angle = (fan.angle + speed * dt) % (2 * math.pi)
				-- turn about the world's up axis through the hub (the hub cylinder itself lies rotated)
				local cf = CFrame.new(fan.home.Position) * CFrame.Angles(0, fan.angle, 0) * fan.home.Rotation
				for p, offset in fan.parts do
					if p.Parent then
						p.CFrame = cf * offset
					end
				end
			end
		end
	end)
end

return FanController
