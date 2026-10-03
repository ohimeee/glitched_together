-- The wooden engine on the floor's track loop (LobbyKit FloorToys: oval centre (82, -160), radii 28 x 26) chugs
-- round slowly. Local only: each client moves its copy of the anchored prop, so it stays smooth.
local RunService = game:GetService("RunService")

local CX, CZ, RX, RZ = 82, -160, 28, 26
local Y = -48.5 -- track top (floor -50, rails 1.5 high)
local SPEED = 0.16 -- radians per second around the loop

local train: BasePart? = nil
local half = 0

task.spawn(function()
	local lobby = workspace:WaitForChild("Lobby")
	local props = lobby:WaitForChild("Props")
	train = props:WaitForChild("Train", 120) :: BasePart?
	if train then
		half = train.Size.Y / 2
	end
end)

local a = 0
RunService.RenderStepped:Connect(function(dt)
	local t = train
	if not t or not t.Parent then
		return
	end
	a = (a + dt * SPEED) % (math.pi * 2)
	local pos = Vector3.new(CX + math.cos(a) * RX, Y + half, CZ + math.sin(a) * RZ)
	local ahead = Vector3.new(CX + math.cos(a + 0.05) * RX, Y + half, CZ + math.sin(a + 0.05) * RZ)
	t.CFrame = CFrame.lookAt(pos, ahead)
end)
