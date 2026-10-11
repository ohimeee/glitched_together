-- Breakable castle props (user, Oct 11: "make the wooden boxes ... breakable except the metals"): the wooden and
-- cloth room dressing (crates, kegs, sacks, bookcases, writing desks; ArtService/StarfallCastle tags them
-- `Breakable` with a `Breakable` = kind attribute) bursts when a tool hits it. Armour, candelabras and weapon racks
-- stay. Props are visual only (no collision, no queries), so hits are tested against this registry instead of the
-- physics world. A break reads as: a squash on the hit, then the prop bursts into tumbling shards (planks, burlap,
-- books) with a dust puff and a crunch, and the shards settle on the floor and fade.
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)
local CombatFx = require(script.Parent.CombatFx)

local B = Tuning.Breakables

type Shard = { material: Enum.Material, colors: { Color3 }, size: { Vector3 } } -- size = min, max
type Kind = { sound: string, dust: Color3, shards: { { shard: Shard, count: number } } }

local OAK = { Color3.fromRGB(122, 84, 52), Color3.fromRGB(104, 70, 43), Color3.fromRGB(140, 99, 62) }
local PLANK: Shard = {
	material = Enum.Material.WoodPlanks,
	colors = OAK,
	size = { Vector3.new(0.25, 0.15, 1.2), Vector3.new(0.6, 0.25, 2.4) },
}
local SPLINTER: Shard = {
	material = Enum.Material.Wood,
	colors = OAK,
	size = { Vector3.new(0.15, 0.15, 0.4), Vector3.new(0.3, 0.25, 0.9) },
}
local BURLAP: Shard = {
	material = Enum.Material.Fabric,
	colors = { Color3.fromRGB(176, 146, 100), Color3.fromRGB(158, 128, 86) },
	size = { Vector3.new(0.5, 0.08, 0.5), Vector3.new(1.1, 0.12, 0.9) },
}
local GRAIN: Shard = {
	material = Enum.Material.Sand,
	colors = { Color3.fromRGB(214, 186, 120), Color3.fromRGB(196, 166, 104) },
	size = { Vector3.new(0.3, 0.2, 0.3), Vector3.new(0.5, 0.3, 0.5) },
}
local BOOK: Shard = {
	material = Enum.Material.Leather,
	-- old bindings; never the reserved owner teal / magenta (art-direction §6)
	colors = {
		Color3.fromRGB(120, 36, 32),
		Color3.fromRGB(46, 70, 46),
		Color3.fromRGB(40, 48, 82),
		Color3.fromRGB(96, 62, 38),
		Color3.fromRGB(150, 112, 50),
	},
	size = { Vector3.new(0.5, 0.15, 0.7), Vector3.new(0.7, 0.25, 0.95) },
}

local KINDS: { [string]: Kind } = {
	Wood = {
		sound = "CrateBreak",
		dust = Color3.fromRGB(150, 128, 104),
		shards = { { shard = PLANK, count = 7 }, { shard = SPLINTER, count = 6 } },
	},
	Sack = {
		sound = "SackBreak",
		dust = Color3.fromRGB(222, 202, 156),
		shards = { { shard = BURLAP, count = 5 }, { shard = GRAIN, count = 9 } },
	},
	Books = {
		sound = "BookcaseBreak",
		dust = Color3.fromRGB(150, 128, 104),
		shards = { { shard = PLANK, count = 6 }, { shard = BOOK, count = 9 }, { shard = SPLINTER, count = 3 } },
	},
}

local Breakables = {}

local rng = Random.new()

local function lerpV(a: Vector3, b: Vector3): Vector3
	return Vector3.new(rng:NextNumber(a.X, b.X), rng:NextNumber(a.Y, b.Y), rng:NextNumber(a.Z, b.Z))
end

-- the burst: shards fly out of the prop's box, mostly into the room (props stand against walls, front = -Z) and
-- away from whatever hit it
local function burst(prop: BasePart, kind: Kind, from: Vector3?)
	local cf, size = prop.CFrame, prop.Size
	local look = cf.LookVector
	local away = if from then (prop.Position - from) * Vector3.new(1, 0, 1) else Vector3.zero
	-- only the sideways part of "away from the hit": the into-the-wall part would throw shards into the wall
	local sideways = away - look * away:Dot(look)
	sideways = if sideways.Magnitude > 0.1 then sideways.Unit else Vector3.zero
	local out = (look + sideways * 0.7).Unit
	for _, group in kind.shards do
		local s = group.shard
		for _ = 1, group.count do
			local p = Instance.new("Part")
			p.Name = "PropShard"
			p.Material = s.material
			p.Color = s.colors[rng:NextInteger(1, #s.colors)]
			p.Size = lerpV(s.size[1], s.size[2])
			p.CFrame = cf
				* CFrame.new(lerpV(-size / 2.6, size / 2.6))
				* CFrame.Angles(rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28), rng:NextNumber(0, 6.28))
			p.CollisionGroup = "Debris"
			p.CanTouch = false
			p.CustomPhysicalProperties = PhysicalProperties.new(0.4, 0.6, 0.15)
			CollectionService:AddTag(p, "ShotPass")
			local dir = (out + cf.RightVector * rng:NextNumber(-1, 1) * 0.9).Unit
			p.AssemblyLinearVelocity = dir * rng:NextNumber(B.ShardSpeed[1], B.ShardSpeed[2])
				+ Vector3.new(0, rng:NextNumber(B.ShardUp[1], B.ShardUp[2]), 0)
			p.AssemblyAngularVelocity = lerpV(-Vector3.one * B.ShardSpin, Vector3.one * B.ShardSpin)
			p.Parent = workspace
			p:SetNetworkOwner(nil)
			task.delay(B.ShardLife, function()
				if p.Parent then
					TweenService:Create(p, TweenInfo.new(B.ShardFade), { Transparency = 1 }):Play()
				end
			end)
			Debris:AddItem(p, B.ShardLife + B.ShardFade + 0.1)
		end
	end
	-- dust puffs out of the middle, a second lower one rolls along the floor
	CombatFx.Burst(prop.Position, { { "Smoke", 7, size.Y * 0.45, kind.dust } })
	CombatFx.Burst(prop.Position - Vector3.new(0, size.Y * 0.4, 0), { { "Smoke", 5, size.Y * 0.3, kind.dust } })
end

-- Break one prop (`from` = where the hit came from, for the shard direction). Safe to call twice.
function Breakables.Break(prop: BasePart, from: Vector3?)
	if prop:GetAttribute("Broken") or not prop.Parent then
		return
	end
	prop:SetAttribute("Broken", true)
	CollectionService:RemoveTag(prop, "Breakable")
	local kind = KINDS[prop:GetAttribute("Breakable") :: string] or KINDS.Wood
	Audio.play(kind.sound, prop.Position)
	-- the hit lands: a quick squash before it gives way
	local size = prop.Size
	TweenService:Create(prop, TweenInfo.new(B.Squash, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = size * Vector3.new(1.12, 0.86, 1.12),
		CFrame = prop.CFrame * CFrame.new(0, -size.Y * 0.07, 0),
	}):Play()
	task.delay(B.Squash, function()
		if prop.Parent then
			prop.Size = size
			burst(prop, kind, from)
			prop:Destroy()
		end
	end)
end

local function each(test: (BasePart) -> boolean, from: Vector3?): number
	local n = 0
	for _, inst in CollectionService:GetTagged("Breakable") do
		if inst:IsA("BasePart") and test(inst) then
			Breakables.Break(inst, from)
			n += 1
		end
	end
	return n
end

-- Props touching a box (sword arc, shield-charge path, flame wall).
function Breakables.InBox(cf: CFrame, size: Vector3, from: Vector3?): number
	return each(function(prop)
		local lp = cf:PointToObjectSpace(prop.Position)
		local r = math.max(prop.Size.X, prop.Size.Z) * B.BoxReach -- how far into the prop the box must reach
		return math.abs(lp.X) <= size.X / 2 + r
			and math.abs(lp.Z) <= size.Z / 2 + r
			and math.abs(lp.Y) <= size.Y / 2 + prop.Size.Y / 2
	end, from or cf.Position)
end

-- Props within `radius` (flat) of a point (meteor, rally).
function Breakables.Near(pos: Vector3, radius: number): number
	return each(function(prop)
		local d = (prop.Position - pos) * Vector3.new(1, 0, 1)
		return d.Magnitude <= radius + math.max(prop.Size.X, prop.Size.Z) / 2
			and math.abs(prop.Position.Y - pos.Y) <= radius + prop.Size.Y
	end, pos)
end

-- A shot's step from `pos` along `move`: breaks the first prop it passes through and returns where, or nil.
function Breakables.Segment(pos: Vector3, move: Vector3): Vector3?
	local best: BasePart?, bestT = nil, math.huge
	for _, inst in CollectionService:GetTagged("Breakable") do
		if inst:IsA("BasePart") then
			-- ray against the prop's box, padded by the shot's radius
			local lp = inst.CFrame:PointToObjectSpace(pos)
			local ld = inst.CFrame:VectorToObjectSpace(move)
			local half = inst.Size / 2 + Vector3.one * B.ShotRadius
			local t0, t1 = 0, 1
			local ok = true
			for _, axis in { "X", "Y", "Z" } do
				local o, d, h = (lp :: any)[axis], (ld :: any)[axis], (half :: any)[axis]
				if math.abs(d) < 1e-6 then
					if math.abs(o) > h then
						ok = false
						break
					end
				else
					local a, b = (-h - o) / d, (h - o) / d
					if a > b then
						a, b = b, a
					end
					t0, t1 = math.max(t0, a), math.min(t1, b)
					if t0 > t1 then
						ok = false
						break
					end
				end
			end
			if ok and t0 < bestT then
				best, bestT = inst, t0
			end
		end
	end
	if not best then
		return nil
	end
	local at = pos + move * bestT
	Breakables.Break(best, pos)
	return at
end

return Breakables
