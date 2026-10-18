-- The bookshelf ladder leans 6° (LobbyRoom: stepped truss pieces, attrs LadderAnchor / LadderLean on the Room
-- folder). Roblox climbing only moves straight up, so while climbing near it this keeps the climber on the lean:
-- each frame the root eases toward the line just in front of the rungs.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local REACH = 7 -- studs either side of the ladder's centre (z) that count as on it
local FRONT = 2.2 -- root distance in front of the rung line
local EASE = 0.3 -- share of the gap closed per frame

local player = Players.LocalPlayer
local room = workspace:WaitForChild("Lobby"):WaitForChild("Room")
local anchor = room:GetAttribute("LadderAnchor") :: Vector3?
local lean = math.rad(room:GetAttribute("LadderLean") or 0)
if not anchor then
	return
end

RunService.Heartbeat:Connect(function()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (humanoid and root) or humanoid:GetState() ~= Enum.HumanoidStateType.Climbing then
		return
	end
	local p = root.Position
	local want = anchor.X + (p.Y - anchor.Y) * math.tan(lean) - FRONT
	if math.abs(p.Z - anchor.Z) > REACH or math.abs(p.X - want) > 6 then
		return -- climbing something else
	end
	root.CFrame += Vector3.new((want - p.X) * EASE, 0, 0)
end)
