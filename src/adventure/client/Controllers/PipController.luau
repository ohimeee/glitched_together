-- Pip in the world: hidden in normal play (user, Oct 19: "only appear when needed"); glitches in beside you when
-- it has something to say (a hint, a cutscene) and glitches out after. While shown it flies to your shoulder. Its glow takes the color of whoever it talks to (art-direction.md §5):
-- white while floating between you, your role color while it talks to you. Local-only copy of ReplicatedStorage.PipModel (published by ArtService);
-- if the meshes never load, the hint bubble still works on its own.
-- Motion (Tuning.Pip): spring follow that overshoots and settles, a lazy figure-8 drift, banking into its
-- motion, a spin + hop when it has something to say, wing flaps, and a short glitch stutter now and then.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Net = require(ReplicatedStorage.Shared.Net)
local Roles = require(ReplicatedStorage.Shared.Config.Roles)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local Settings = require(ReplicatedStorage.Shared.Util.Settings)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local T = Tuning.Pip

local PipController = {}

local function partner(): Player?
	local myRole = player:GetAttribute("Role")
	for _, p in Players:GetPlayers() do
		local role = p:GetAttribute("Role")
		if p ~= player and role and role ~= myRole then
			return p
		end
	end
	return nil
end

local function rootOf(p: Player?): BasePart?
	local character = p and p.Character
	return character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Where Pip wants to be, before drift/bob.
local function anchorTarget(me: BasePart, hinting: boolean): Vector3
	if hinting then
		-- beside your head, on the camera's right, so it reads as talking to you
		return me.Position + camera.CFrame.RightVector * 3 + Vector3.new(0, 3, 0)
	end
	local other = rootOf(partner())
	local mid = if other and (other.Position - me.Position).Magnitude < T.Leash
		then (me.Position + other.Position) / 2
		else me.Position
	return mid + Vector3.new(0, T.Height, 0)
end

local function easeOutBack(x: number): number
	local c = 1.4
	return 1 + (c + 1) * (x - 1) ^ 3 + c * (x - 1) ^ 2
end

function PipController.Init()
	task.spawn(function()
		local template = ReplicatedStorage:WaitForChild("PipModel", 60) :: Model?
		if not template then
			return
		end
		local pip = template:Clone()
		pip:ScaleTo(T.Scale)
		for _, d in pip:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
			end
		end
		pip.Parent = workspace

		-- every part's pose relative to the model pivot, so wings can flap on top of the body's motion
		-- (position only: the parts carry their own Yaw, and a rotated pivot would cancel it)
		local pivot0 = CFrame.new(pip:GetPivot().Position)
		local parts: { BasePart } = {}
		local rest: { CFrame } = {}
		local flapSign: { number } = {}
		local hinge: { Vector3 } = {} -- wing root, in pivot space
		for _, d in pip:GetDescendants() do
			if d:IsA("BasePart") then
				table.insert(parts, d)
				local rel = pivot0:ToObjectSpace(d.CFrame)
				table.insert(rest, rel)
				local sign = if d.Name == "WingL" then -1 elseif d.Name == "WingR" then 1 else 0
				table.insert(flapSign, sign)
				-- inner edge of the wing (toward the body's center line)
				table.insert(hinge, rel.Position - Vector3.new(sign * d.Size.X / 2, 0, 0))
			end
		end

		local glow = pip:FindFirstChildWhichIsA("PointLight", true)
		-- shown only while talking: hint bubble up, or a cutscene; glitch flicker on the way in and out
		local shown, flickerUntil = false, 0
		local function setVisible(on: boolean)
			for _, part in parts do
				part.LocalTransparencyModifier = if on then 0 else 1
			end
			if glow then
				glow.Enabled = on
			end
		end
		setVisible(false)
		local hintUntil, spinStart = 0, -math.huge
		Net.event("Hint").OnClientEvent:Connect(function()
			if not Settings.Get("PipHints") then
				return
			end
			hintUntil = os.clock() + T.HintTime
			spinStart = os.clock()
			local role = (Roles :: any)[player:GetAttribute("Role") or ""]
			if glow then
				glow.Color = if role then role.Color else Palette.Duo
			end
			task.delay(T.HintTime, function()
				if glow and os.clock() >= hintUntil then
					glow.Color = Palette.Duo
				end
			end)
		end)

		local rng = Random.new()
		local nextJitter = os.clock() + rng:NextNumber(T.JitterMin, T.JitterMax)
		local jitterUntil = 0
		local pos: Vector3? = nil
		local vel = Vector3.zero
		local bank, pitch = 0, 0
		local cframes: { CFrame } = table.create(#parts)

		RunService.RenderStepped:Connect(function(dt)
			local me = rootOf(player)
			if not me then
				return
			end
			dt = math.min(dt, 1 / 20) -- keep the spring stable through frame hitches
			local now = os.clock()
			local want = now < hintUntil or player:GetAttribute("InCutscene") == true
			if want ~= shown then
				shown = want
				flickerUntil = now + T.GlitchTime
				if want then
					pos = nil -- pop in right beside you, no fly-over from far away
				end
			end
			if now < flickerUntil then
				-- hard on/off snaps while it glitches in or out (art-direction.md §7)
				setVisible(math.floor(now * 24) % 2 == (if shown then 0 else 1))
			else
				setVisible(shown)
				if not shown then
					return
				end
			end
			local cam = camera.CFrame

			-- target: anchor + figure-8 in the camera's view plane + bob
			local w = now * T.DriftSpeed
			local drift = cam.RightVector * (math.sin(w) * T.DriftRadius)
				+ Vector3.new(0, math.sin(w * 2) * T.DriftRadius * 0.5 + math.sin(now * T.BobSpeed) * T.BobHeight, 0)
			local target = anchorTarget(me, shown) + drift

			-- spring follow (semi-implicit Euler)
			if not pos or (target - pos).Magnitude > T.SnapDistance then
				pos, vel = target, Vector3.zero
			end
			local p = pos :: Vector3
			vel += ((target - p) * T.Stiffness - vel * T.Damping) * dt
			if vel.Magnitude > T.MaxSpeed then
				vel = vel.Unit * T.MaxSpeed
			end
			p += vel * dt
			pos = p

			-- lean into sideways motion; dip toward/away from the camera
			local side = vel:Dot(cam.RightVector)
			local toward = vel:Dot(-cam.LookVector)
			local k = 1 - math.exp(-dt * T.BankSharpness)
			bank += (math.clamp(-side * T.BankPerSpeed, -T.MaxBank, T.MaxBank) - bank) * k
			pitch += (math.clamp(toward * T.BankPerSpeed * 0.5, -T.MaxBank, T.MaxBank) - pitch) * k

			-- excited spin + hop after a hint
			local spin, hop = 0, 0
			local s = (now - spinStart) / T.SpinTime
			if s >= 0 and s < 1 then
				spin = easeOutBack(s) * math.pi * 2
				hop = math.sin(s * math.pi) * T.SpinHop
			end

			-- glitch stutter: hard snaps, never smooth (art-direction.md §7)
			local jitter = Vector3.zero
			if now >= nextJitter then
				jitterUntil = now + T.JitterTime
				nextJitter = now + rng:NextNumber(T.JitterMin, T.JitterMax)
			end
			if now < jitterUntil and math.floor(now * 30) % 2 == 0 then
				local a = T.JitterAmount
				jitter = Vector3.new(rng:NextNumber(-a, a), rng:NextNumber(-a, a) * 0.5, rng:NextNumber(-a, a))
			end

			local at = p + Vector3.new(0, hop, 0) + jitter
			local look = Vector3.new(cam.Position.X, at.Y, cam.Position.Z)
			if (look - at).Magnitude < 0.1 then
				return
			end
			-- Pip's face is its -Z side
			local root = CFrame.lookAt(at, look) * CFrame.Angles(pitch, spin, bank)

			local flap = math.sin(now * T.FlapSpeed) * T.FlapAngle
			for i, rel in rest do
				local sign = flapSign[i]
				if sign ~= 0 then
					local h = hinge[i]
					rel = CFrame.new(h) * CFrame.Angles(0, 0, sign * flap) * CFrame.new(-h) * rel
				end
				cframes[i] = root * rel
			end
			workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
		end)
	end)
end

return PipController
