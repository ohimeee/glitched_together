-- Carry tools (ToolFx `Carry`: ray gun, grapple pistol, copier) ride a small spring in the hand instead of being
-- glued to it (user, Oct 17: "it feels like the items are glued in their hands"). Every client sways every
-- character's item on its own: the hand's acceleration throws the item back, the spring pulls it to the grip with one
-- small overshoot. Only the weld's C0 moves, locally (it never replicates), so each client sees the same motion.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)

local S = Tuning.HeldSway

type Sway = { weld: Weld, base: CFrame, last: Vector3?, vel: Vector3?, x: Vector3, v: Vector3 }

local HeldSwayController = {}

local sways: { [BasePart]: Sway } = {}

local function step(dt: number)
	if dt <= 0 then
		return
	end
	dt = math.min(dt, 1 / 20) -- a hitch must not fling it
	for _, p in Players:GetPlayers() do
		local character = p.Character
		for _, item in if character then character:GetChildren() else {} do
			if item:IsA("BasePart") and item:GetAttribute("Carry") and not sways[item] then
				local weld = item:FindFirstChildOfClass("Weld")
				if weld then
					sways[item] = { weld = weld, base = weld.C0, x = Vector3.zero, v = Vector3.zero }
				end
			end
		end
	end
	for item, s in sways do
		local hand = s.weld.Part0
		if not (item.Parent and s.weld.Parent and hand) then
			sways[item] = nil
			continue
		end
		local pos = hand.Position
		local vel = if s.last then (pos - s.last) / dt else Vector3.zero
		local acc = if s.vel then (vel - s.vel) / dt else Vector3.zero
		s.last, s.vel = pos, vel
		if acc.Magnitude > 600 then
			acc = Vector3.zero -- a respawn / teleport, not a swing
		end
		local push = hand.CFrame:VectorToObjectSpace(-acc) * S.Push
		s.v += (push - s.x * S.Stiffness - s.v * S.Damping) * dt
		s.x += s.v * dt
		if s.x.Magnitude > S.Max then
			s.x = s.x.Unit * S.Max
			s.v *= 0.5
		end
		-- lag along the hand's X / Z tips the item about the other axis, plus a little slide
		local x = s.x
		s.weld.C0 = CFrame.new(x * S.Shift) * CFrame.Angles(-x.Z * S.Tilt, 0, x.X * S.Tilt) * s.base
	end
end

function HeldSwayController.Init()
	RunService.RenderStepped:Connect(step)
end

return HeldSwayController
