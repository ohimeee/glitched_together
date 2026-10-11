-- Kai, Starfall Castle (mechanics.md §4 World 2). The client aims at a point on the floor (top-down) and sends it
-- as `aim`; everything is validated and simulated here through CombatService.
--   1 Fireball    projectile, 10 dmg, reflectable by Miko's shield (Bigger Fireball: ×1.5 size; Faster Cast: 0.25 s)
--   2 Flame Wall  12-stud line across the aim direction for 5 s (Double Flame Wall: two parallel walls)
--   3 Ignite      a Brazier / Burnable within 30 studs
--   4 Meteor      when Ultimate is full: 12-stud blast after a 1.2 s marked cast
--   5 Blink       client moves Kai 10 studs (through iron bars); server only adds the Ember Trail upgrade
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local CombatService = require(script.Parent.Parent.CombatService)
local CombatFx = require(script.Parent.Parent.CombatFx)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)

local T = Tuning.FireMage
local C = Tuning.Combat
local SLACK = 5

local FireMage = {
	BlockedBy = { "Downed", "InCutscene", "Picking" },
	Cooldowns = {
		[1] = C.FasterCast, -- the base 0.35 s is enforced below unless Kai picked Faster Cast
		[2] = T.FlameWall.Cooldown,
		[3] = T.Ignite.Cooldown,
		[5] = T.Blink.Cooldown,
	},
}

local lastFireball: { [Player]: number } = {}

local function rootOf(p: Player): BasePart?
	return p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function flatDir(from: Vector3, to: Vector3, fallback: Vector3): Vector3
	local v = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	return if v.Magnitude > 0.1 then v.Unit else fallback
end

local function fireball(p: Player, root: BasePart, aim: Vector3)
	local cooldown = if p:GetAttribute("Up_FasterCast") then C.FasterCast else T.Fireball.Cooldown
	local now = os.clock()
	if now - (lastFireball[p] or -math.huge) < cooldown * 0.9 then
		return
	end
	lastFireball[p] = now
	local dir = flatDir(root.Position, aim, root.CFrame.LookVector)
	local bigger = p:GetAttribute("Up_BiggerFireball") == true
	local size = if bigger then 1.4 * C.BiggerFireball else 1.4
	CombatService.Fire({
		origin = root.Position + dir * 2.5,
		dir = dir,
		speed = T.Fireball.Speed,
		damage = if bigger then T.Fireball.Damage * C.BiggerFireballDamage else T.Fireball.Damage,
		friendly = true,
		owner = p,
		kind = "Fireball",
		size = size,
	})
end

local function flameWall(p: Player, root: BasePart, aim: Vector3)
	local dir = flatDir(root.Position, aim, root.CFrame.LookVector)
	local dist = math.min(Vector3.new(aim.X - root.Position.X, 0, aim.Z - root.Position.Z).Magnitude, 40)
	local center = root.Position + dir * math.max(dist, 6)
	-- the wall's length runs across the aim direction (local X), its thin side faces Kai
	local cf = CFrame.lookAt(center, center + dir)
	CombatService.FlameWall(cf, p)
	if p:GetAttribute("Up_DoubleFlameWall") then
		CombatService.FlameWall(cf * CFrame.new(0, 0, -3), p)
	end
end

local function ignite(p: Player, root: BasePart, target: Instance?)
	local range = T.Ignite.Range + SLACK
	local function ok(inst: Instance): boolean
		return (
			Tags.has(inst, "Brazier")
			or Tags.has(inst, "Burnable")
			or Tags.has(inst, "GolemPillar")
			or Tags.has(inst, "FuseStart")
			or Tags.has(inst, "FuseBreak")
		)
			and inst:IsDescendantOf(workspace)
			and (Tags.position(inst) - root.Position).Magnitude <= range
	end
	-- a spark flicks from Kai's hand to the target (the cast animation's snap), then it catches
	local function light(inst: Instance)
		local delay = CombatFx.IgniteBolt(root.Position + root.CFrame.LookVector * 1.5, Tags.position(inst))
		task.delay(delay, CombatService.Ignite, inst)
	end
	if target and ok(target) then
		light(target)
		return
	end
	-- no (valid) target sent: light the nearest thing in range
	local best: Instance?, bestD = nil, math.huge
	for _, tag in { "Brazier", "Burnable", "GolemPillar", "FuseStart", "FuseBreak" } do
		for _, inst in game:GetService("CollectionService"):GetTagged(tag) do
			if ok(inst) and not inst:GetAttribute("Lit") and not inst:GetAttribute("Weakened") then
				local d = (Tags.position(inst) - root.Position).Magnitude
				if d < bestD then
					best, bestD = inst, d
				end
			end
		end
	end
	if best then
		light(best)
	end
end

function FireMage.Use(p: Player, useIndex: number, target: Instance?, aim: any)
	local root = rootOf(p)
	if not root then
		return
	end
	local point = if typeof(aim) == "Vector3" then aim else root.Position + root.CFrame.LookVector * 20
	if useIndex == 1 then
		fireball(p, root, point)
	elseif useIndex == 2 then
		flameWall(p, root, point)
	elseif useIndex == 3 then
		ignite(p, root, target)
	elseif useIndex == 4 then
		if (point - root.Position).Magnitude <= C.MeteorAim + SLACK and CombatService.SpendUltimate(p) then
			CombatService.Meteor(Vector3.new(point.X, root.Position.Y - 2.5, point.Z), p)
		end
	elseif useIndex == 5 then
		-- aim = the spot Kai blinked from (the client already moved him)
		Audio.play("Blink", root)
		if p:GetAttribute("Up_EmberTrail") and typeof(aim) == "Vector3" then
			if (aim - root.Position).Magnitude <= T.Blink.Distance + SLACK then
				CombatService.Embers(aim, root.Position, p)
			end
		end
	end
end

function FireMage.Init()
	game:GetService("Players").PlayerRemoving:Connect(function(p)
		lastFireball[p] = nil
	end)
end

return FireMage
