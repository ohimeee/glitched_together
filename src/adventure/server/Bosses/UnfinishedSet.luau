-- The Unfinished's stage set (CLAUDE.md next step 4, "per-phase stage props"): eight wagons round the stage rim
-- (Greybox FINAL STAGE builds the decks + truss arms) carry the props of the world whose rules are on. When the
-- rules change, the old props sink into their decks and the next world's rise out of them, wagon after wagon, like
-- a theatre set change: Pixel Plains voxel trees on grass blocks, castle braziers and broken pillars on flagstones,
-- the Core's wire cubes and terminals on primer. Every slot the duo fills in phase 4 turns one wagon to gold.
-- Scenery only: nothing here collides or takes shots.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local Services = script.Parent.Parent.Services
local ArtService = require(Services.ArtService)
local CombatFx = require(Services.CombatFx)

local T = Tuning.Unfinished
local GOLD = Color3.fromRGB(255, 196, 92) -- the finished level (Unfinished's GOLD)
local FIRE = Color3.fromRGB(255, 170, 96)

-- { skin, scale, x, z, yaw }: x right / z away from the stage, in the deck's frame (its -Z faces the stage centre)
type Prop = { any }
type Look = { deck: { any }, base: Prop?, sets: { { Prop } } }

local LOOKS: { [string]: Look } = {
	PixelPlains = {
		deck = { Enum.Material.Concrete, "CoreFloor", Color3.fromRGB(232, 233, 236) }, -- hidden under the grass block
		base = { "GrassBlock", 0.7, 0, 0, 0 }, -- a voxel grass block over the whole deck; the rest stands on it
		sets = {
			{ { "Tree", 0.8, 0, 2, 0 }, { "Bush", 1, -4, -3, 30 }, { "Flowers", 1, 3.5, -3.5, 0 } },
			{ { "TreePine", 0.8, 1, 2, 0 }, { "Crate", 0.9, -3.5, -2.5, 15 }, { "Flowers2", 1, 3, -3.5, 0 } },
			{ { "TreeApple", 0.8, -1, 2, 0 }, { "Rock2", 1, 3.5, -2.5, 40 }, { "Flowers3", 1, -3.5, -3.5, 0 } },
			{ { "TreeBirch", 0.8, 0, 2, 0 }, { "Bush2", 1, 3.5, -3, 0 }, { "Flowers", 1, -3.5, -3.5, 90 } },
		},
	},
	StarfallCastle = {
		deck = { Enum.Material.Cobblestone, "CastleFloor", Color3.fromRGB(205, 196, 214) },
		sets = {
			{ { "GolemPillar", 1, 0, 2.5, 0 }, { "BrazierSkin", 1.6, 0, -3, 0 } },
			{ { "KegSkin", 1, -3.5, -2.5, 0 }, { "KegSkin", 0.9, -1, 2.5, 50 }, { "BarricadeSkin", 0.8, 3, -3, 20 } },
			{ { "CrackedWallSkin", 1, 0, 4, 0 }, { "BrazierSkin", 1.4, -3, -2.5, 0 }, { "KegSkin", 1, 3.5, -2.5, 0 } },
			{ { "GolemPillar", 0.9, -4, 3, 0 }, { "GolemPillar", 0.9, 4, 3, 0 }, { "BrazierSkin", 1.6, 0, -2.5, 0 } },
		},
	},
	GlitchedCore = {
		deck = { Enum.Material.Concrete, "CoreFloor", Color3.fromRGB(232, 233, 236) }, -- as ArtService/GlitchedCore dresses it
		sets = {
			{ { "WireCube", 2, 0, 2.5, 20 }, { "UnfRock", 1, -4, -3, 0 } },
			{ { "CoreTerminal", 2.4, 0, 3, 0 }, { "WireCube", 1, 3.5, -3, 35 } },
			{ { "SavePoint", 1.6, 0, 3.5, 0 }, { "UnfRock", 0.9, 3.5, -3, 70 }, { "WireCube", 0.9, -3.5, -2.5, 10 } },
			{ { "WireCube", 1.4, -2.5, 2, 0 }, { "WireCube", 1, 3, 3, 25 }, { "ScannerSkin", 2, 0, -3, 0 } },
		},
	},
}

type Wagon = { model: Model, deck: BasePart, props: { BasePart }, gold: boolean }
export type Set = { folder: Instance, wagons: { Wagon }, look: string? }

local UnfinishedSet = {}

-- The set as the world holds it now (props already standing, e.g. from the intro, are kept track of).
function UnfinishedSet.Find(world: Instance): Set?
	local folder = world:FindFirstChild("StageSet", true)
	if not folder then
		return nil
	end
	local wagons = {}
	for _, model in folder:GetChildren() do
		local deck = model:FindFirstChild("Deck")
		if model:IsA("Model") and deck and deck:IsA("BasePart") then
			local props = {}
			for _, p in model:GetChildren() do
				if p.Name == "SetProp" and p:IsA("BasePart") then
					table.insert(props, p)
				end
			end
			table.insert(wagons, {
				model = model,
				deck = deck,
				props = props,
				gold = false,
			})
		end
	end
	table.sort(wagons, function(a, b)
		return (a.model:GetAttribute("Index") or 0) < (b.model:GetAttribute("Index") or 0)
	end)
	return { folder = folder, wagons = wagons, look = folder:GetAttribute("Look") }
end

-- every skin a look uses, so the server can download them before the rules change
function UnfinishedSet.Warm()
	local names = {}
	for _, look in LOOKS do
		if look.base then
			table.insert(names, look.base[1])
		end
		for _, set in look.sets do
			for _, prop in set do
				table.insert(names, prop[1])
			end
		end
	end
	ArtService.Warm(names)
end

-- one prop's holder (skinned, its meshes welded to it so a tween moves them all), standing on `floorY`
local function makeProp(w: Wagon, prop: Prop, floorY: number): (BasePart?, CFrame?)
	local design = ArtService.DesignOf(prop[1])
	if not design then
		return nil
	end
	local size = design * prop[2]
	local deckCf = w.deck.CFrame
	local at = deckCf * CFrame.new(prop[3], 0, prop[4])
	local cf = CFrame.new(at.Position.X, floorY + size.Y / 2, at.Position.Z)
		* deckCf.Rotation
		* CFrame.Angles(0, math.rad(prop[5] or 0), 0)
	local holder = Instance.new("Part")
	holder.Name = "SetProp"
	holder.Size = size
	holder.CFrame = cf - Vector3.new(0, size.Y + 1, 0) -- hidden under the deck until it rises
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder:SetAttribute("Weld", true) -- ArtService welds the skin's meshes to it
	holder.Parent = w.model
	if prop[1]:match("Brazier") then
		local light = Instance.new("PointLight")
		light.Color = FIRE
		light.Range = 10
		light.Brightness = 0.8 -- small warm pools (memory subtle-lighting)
		light.Parent = holder
		-- painted fire over the coals, like the castle's torches
		local top = Instance.new("Attachment")
		top.Position = Vector3.new(0, size.Y * 0.45, 0)
		top.Parent = holder
		CombatFx.Emit(top, "Flame", 0.6 * prop[2], 12)
	end
	return holder, cf
end

local function sink(part: BasePart, time: number)
	TweenService:Create(part, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		CFrame = part.CFrame - Vector3.new(0, part.Size.Y + 1.5, 0),
	}):Play()
	task.delay(time + 0.05, part.Destroy, part)
end

local function dressWagon(set: Set, w: Wagon, lookName: string, instant: boolean)
	local look = LOOKS[lookName]
	local half = if instant then 0 else T.SetSwap * 0.5
	for _, old in w.props do
		if instant then
			old:Destroy()
		else
			sink(old, half)
		end
	end
	w.props = {}
	w.gold = false
	if not instant then
		CombatFx.Burst(w.deck.Position, { { "Stars", 12, 1.5, Palette.Glitch } })
	end
	task.delay(half, function()
		if set.look ~= lookName or not w.deck.Parent then
			return -- the rules changed again meanwhile
		end
		local d = look.deck
		w.deck.Material, w.deck.MaterialVariant, w.deck.Color = d[1], d[2], d[3]
		local floorY = w.deck.Position.Y + w.deck.Size.Y / 2
		local props = {}
		if look.base then
			table.insert(props, look.base)
		end
		local baseTop = floorY
		if look.base then
			local design = ArtService.DesignOf(look.base[1])
			baseTop += if design then design.Y * look.base[2] else 0
		end
		local index = w.model:GetAttribute("Index") or 1
		for _, prop in look.sets[(index - 1) % #look.sets + 1] do
			table.insert(props, prop)
		end
		for n, prop in props do
			local holder, cf = makeProp(w, prop, if n == 1 and look.base then floorY else baseTop)
			if not (holder and cf) then
				continue
			end
			table.insert(w.props, holder)
			task.spawn(function()
				if not ArtService.Apply(holder, prop[1]) then
					holder:Destroy() -- the skin couldn't load: no grey box in the scenery
					return
				end
				if not holder.Parent then
					return
				end
				if instant then
					holder.CFrame = cf
				else
					TweenService:Create(holder, TweenInfo.new(T.SetSwap, Enum.EasingStyle.Back), { CFrame = cf }):Play()
				end
			end)
		end
	end)
end

-- Swap every wagon to a world's props (no-op if it already shows them, unless `force`: e.g. un-gilding after a stop).
function UnfinishedSet.Show(set: Set?, lookName: string, instant: boolean?, force: boolean?)
	if not set or (set.look == lookName and not force) or not LOOKS[lookName] then
		return
	end
	set.look = lookName
	set.folder:SetAttribute("Look", lookName)
	for i, w in set.wagons do
		if instant then
			dressWagon(set, w, lookName, true)
		else
			task.delay((i - 1) * T.SetStagger, dressWagon, set, w, lookName, false)
		end
	end
end

local function gild(w: Wagon)
	w.gold = true
	for _, holder in w.props do
		for _, d in holder:GetDescendants() do
			if d:IsA("MeshPart") then
				d.TextureID = ""
				d.Material = Enum.Material.Foil -- polished gold like the Epilogue trophies (Metal reads flat ochre)
				d.Color = GOLD
			elseif d:IsA("SurfaceAppearance") then
				d:Destroy()
			end
		end
	end
	CombatFx.Burst(w.deck.Position + Vector3.new(0, 3, 0), { { "Stars", 14, 1.5, GOLD } }, GOLD, 10)
end

-- A slot was filled at `pos`: the nearest wagon still unfinished turns to gold.
function UnfinishedSet.Gild(set: Set?, pos: Vector3)
	if not set then
		return
	end
	local best, bestD = nil, math.huge
	for _, w in set.wagons do
		local d = (w.deck.Position - pos).Magnitude
		if not w.gold and d < bestD then
			best, bestD = w, d
		end
	end
	if best then
		gild(best)
	end
end

function UnfinishedSet.GildAll(set: Set?)
	for _, w in if set then set.wagons else {} do
		if not w.gold then
			gild(w)
		end
	end
end

return UnfinishedSet
