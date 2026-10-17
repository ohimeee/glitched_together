-- Miko, Starfall Castle (mechanics.md §4 World 2). Aim = a point on the floor (top-down), sent by the client.
--   1 Sword        3-hit chain 8 / 8 / 14 in a box in front (chain resets after Combat.SwordCombo.Window)
--   2 Block (hold) `Blocking` attribute: 120° shield (Wider Block 160°), taunts enemies, reflects shots
--                  (the reflection itself lives in CombatService). Movement slows on the client.
--   3 Charge       client rushes 16 studs (Longer Charge 22); server damages + shoves along the line, breaks
--                  CrackedWall, knocks Shield Guards' shields aside
--   4 Rally        when Ultimate is full: 14-stud shockwave, 15 dmg, 2 s stun (Second Wind: heals 20)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local CombatService = require(script.Parent.Parent.CombatService)
local HealthService = require(script.Parent.Parent.HealthService)

local T = Tuning.ShieldKnight
local C = Tuning.Combat

local ShieldKnight = {
	BlockedBy = { "Downed", "InCutscene", "Picking" },
	Cooldowns = { [1] = C.SwordCombo.Swing, [3] = T.Charge.Cooldown },
}

local combo: { [Player]: { step: number, last: number } } = {}

local function rootOf(p: Player): BasePart?
	return p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function flatDir(from: Vector3, to: Vector3, fallback: Vector3): Vector3
	local v = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	return if v.Magnitude > 0.1 then v.Unit else fallback
end

local function sword(p: Player, root: BasePart, aim: Vector3)
	local c = combo[p] or { step = 0, last = 0 }
	combo[p] = c
	local now = os.clock()
	c.step = if now - c.last > C.SwordCombo.Window then 1 else (c.step % #T.Sword.Damage) + 1
	c.last = now
	local dir = flatDir(root.Position, aim, root.CFrame.LookVector)
	local reach = C.SwordCombo.Reach
	local cf = CFrame.lookAt(root.Position, root.Position + dir) * CFrame.new(0, 0, -reach / 2 - 0.5)
	CombatService.MeleeBox(cf, Vector3.new(C.SwordCombo.Width, 5, reach), T.Sword.Damage[c.step], p, c.step)
	-- the blade's swoosh trail (ArtService, ToolFx TrailWhile) for this swing
	p:SetAttribute("SwordSwing", true)
	task.delay(C.SwordCombo.Swing * 0.85, function()
		if c.last == now then
			p:SetAttribute("SwordSwing", nil)
		end
	end)
end

function ShieldKnight.Use(p: Player, useIndex: number, _target: Instance?, aim: any)
	local root = rootOf(p)
	if not root then
		return
	end
	if useIndex == 2 then
		p:SetAttribute("Blocking", aim == true or nil)
		return
	end
	local point = if typeof(aim) == "Vector3" then aim else root.Position + root.CFrame.LookVector * 10
	if useIndex == 1 then
		sword(p, root, point)
	elseif useIndex == 3 then
		-- aim = where the charge started (the client already moved Miko); the line runs from there to her now
		local from = if typeof(aim) == "Vector3" then aim else root.Position
		local length = if p:GetAttribute("Up_LongerCharge") then C.LongerCharge else T.Charge.Distance
		local travelled = Vector3.new(root.Position.X - from.X, 0, root.Position.Z - from.Z)
		if travelled.Magnitude > length + 6 then
			from = root.Position - root.CFrame.LookVector * length -- implausible start: trust the server's view
		end
		local dir = flatDir(from, root.Position, root.CFrame.LookVector)
		CombatService.ChargeLine(from, dir, math.max(travelled.Magnitude, 4) + 2, T.Charge.Damage, p)
	elseif useIndex == 4 or useIndex == 5 then
		-- 5 = Rally leap (touch drag): aim = where she lands; the wave goes out there, not where the server last
		-- saw her mid-air (replication lags the 0.42 s leap)
		local land: Vector3? = nil
		if useIndex == 5 and typeof(aim) == "Vector3" then
			local flat = Vector3.new(aim.X - root.Position.X, 0, aim.Z - root.Position.Z)
			if flat.Magnitude <= T.Rally.LeapReach + 6 and math.abs(aim.Y - root.Position.Y) < 20 then
				land = aim
			end
		end
		if CombatService.SpendUltimate(p) then
			CombatService.Rally(root.Position, p, land)
			if p:GetAttribute("Up_SecondWind") then
				local hp = (p:GetAttribute("Health") or 0) :: number
				HealthService.Restore(p, hp + C.SecondWind.RallyHeal)
			end
		end
	end
end

function ShieldKnight.Init()
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		combo[p] = nil
	end)
end

return ShieldKnight
