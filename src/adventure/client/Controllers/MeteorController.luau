-- Shooting stars over the Epilogue (user, Oct 11: "with meteors") and over Starfall Castle (Oct 12: the Hollow Dragon's
-- open-roofed hall). Client only, pure decoration: every few seconds a
-- white-blue streak crosses the sky dome far from the camera (in front of the baked panorama, behind the level),
-- falling at a slant, its trail fading behind it. Numbers: Tuning.Meteors.
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)

local MeteorController = {}

local T = Tuning.Meteors
local WORLDS = { Epilogue = true, StarfallCastle = true }
local rng = Random.new()

local function streak()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	-- start: a random bearing, a random height in the sky; travel: across and down
	local yaw = rng:NextNumber(0, math.pi * 2)
	local el = math.rad(rng:NextNumber(T.ElevationMin, T.ElevationMax))
	local dir = Vector3.new(math.cos(yaw) * math.cos(el), math.sin(el), math.sin(yaw) * math.cos(el))
	local origin = cam.CFrame.Position
	local start = origin + dir * T.Distance
	local side = dir:Cross(Vector3.yAxis).Unit * (if rng:NextNumber() < 0.5 then -1 else 1)
	local travel = (side + Vector3.new(0, -rng:NextNumber(0.35, 0.8), 0)).Unit * T.Length
	local time = rng:NextNumber(T.TimeMin, T.TimeMax)

	local head = Instance.new("Part")
	head.Name = "Meteor"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.one * T.Head
	head.Material = Enum.Material.Neon
	head.Color = Color3.fromRGB(235, 242, 255)
	head.Anchored = true
	head.CanCollide = false
	head.CanQuery = false
	head.CanTouch = false
	head.CastShadow = false
	head.CFrame = CFrame.new(start)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, T.TrailWidth / 2, 0)
	a0.Parent = head
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -T.TrailWidth / 2, 0)
	a1.Parent = head
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.FaceCamera = true
	trail.Lifetime = T.TrailTime
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 175, 255))
	trail.Transparency = NumberSequence.new(0, 1)
	trail.WidthScale = NumberSequence.new(1, 0)
	trail.Parent = head
	head.Parent = workspace

	local t = 0
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function(dt)
		t += dt
		local k = math.min(t / time, 1)
		head.CFrame = CFrame.new(start + travel * k)
		head.Transparency = math.max(0, (k - 0.7) / 0.3) -- burns out at the end
		if k >= 1 then
			conn:Disconnect()
			task.delay(T.TrailTime, head.Destroy, head)
		end
	end)
end

function MeteorController.Init()
	task.spawn(function()
		while true do
			task.wait(rng:NextNumber(T.GapMin, T.GapMax))
			if WORLDS[workspace:GetAttribute("World") :: string] then
				streak()
				if rng:NextNumber() < T.BurstChance then
					for _ = 1, rng:NextInteger(1, 2) do
						task.wait(rng:NextNumber(0.15, 0.6))
						streak()
					end
				end
			end
		end
	end)
end

return MeteorController
