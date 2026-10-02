-- Starfall Castle enemies: Roblox Studio generate_mesh (textured, stylized-realistic; the approved graphics
-- baseline). Each skin fits its CombatService collider: scaled to the collider height, feet on its floor, and
-- turned by Yaw so the model faces the enemy's -Z (generations come out facing different ways).
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local CombatFx = require(script.Parent.Parent.CombatFx)

local SMOOTH = Enum.Material.SmoothPlastic
local v = Vector3.new

local function enemy(
	design: Vector3,
	id: string,
	tex: string,
	size: Vector3,
	offsetY: number,
	yaw: number
): MeshAssets.Skin
	return {
		Design = design,
		Meshes = {
			Body = { Id = id, TextureId = tex, Offset = v(0, offsetY, 0), Size = size, Material = SMOOTH, Yaw = yaw },
		},
	}
end

local Skins: { [string]: MeshAssets.Skin } = {
	Skeleton = enemy(v(3, 5, 2), "rbxassetid://88134488705730", "rbxassetid://95933721649119", v(4.44, 5, 3.4), 0, 180),
	SplitSlime = enemy(
		v(4, 3, 4),
		"rbxassetid://110664994505790",
		"rbxassetid://97033380093381",
		v(2.44, 3.6, 2.47),
		0.3,
		-90
	),
	StaticArcher = enemy(
		v(3, 5, 2),
		"rbxassetid://118578770192715",
		"rbxassetid://118500400968383",
		v(2.44, 5, 1.91),
		0,
		-90
	),
	ShieldGuard = enemy(
		v(4, 6, 3),
		"rbxassetid://126445535567686",
		"rbxassetid://113921575497616",
		v(4.74, 6, 2.66),
		0,
		180
	),
	GuardShield = enemy(
		v(5, 5, 0.6),
		"rbxassetid://100528865986665",
		"rbxassetid://73287764386506",
		v(3.85, 4.99, 0.84),
		0,
		0
	),
	StaticMage = enemy(
		v(3, 6, 3),
		"rbxassetid://82008586970811",
		"rbxassetid://128866102886080",
		v(3.36, 6, 2.38),
		0,
		90
	),
}

-- 2-2 Dark Library + Golem Hall props (Oct 1, obstacles.md 2.3): generated to the same storybook-realistic finish.
-- Offsets put each model's foot on the floor (the grey-box parts float a little).
Skins.IronGolem = enemy( -- a little castle-tower guardian; its visor faces +Z as generated
	v(6, 7, 5),
	"rbxassetid://75830825215040",
	"rbxassetid://82069423211803",
	v(7.4, 7, 4.6),
	0,
	180
)
Skins.SpikeRoller = enemy(v(10, 4, 3), "rbxassetid://135577631972243", "rbxassetid://71542413269555", v(10, 4, 4), 0, 0)
Skins.GolemPillar = enemy(v(4, 10, 4), "rbxassetid://102180491432565", "rbxassetid://89145144615487", v(4, 10, 4), 0, 0)
Skins.MirrorSkin =
	enemy(v(6, 5, 0.6), "rbxassetid://102537945337069", "rbxassetid://112257945113121", v(5, 5.5, 1), -0.75, 0)
Skins.CrystalTeal =
	enemy(v(2, 4, 2), "rbxassetid://134206761685461", "rbxassetid://127713500326076", v(2.4, 4.4, 2.4), -0.8, 0)
Skins.CrystalOrange =
	enemy(v(2, 4, 2), "rbxassetid://90780134347317", "rbxassetid://94503427299730", v(2.4, 4.4, 2.4), -0.8, 0)

-- Castle props (Oct 1, 7th session art pass): Rose's Room-style toy castle, real materials (worn wood, rope, hammered
-- iron). Sizes keep each generation's proportions and stand it on its part's floor.
Skins.TorchSkin = enemy( -- sits on the wall top; its neon flame part becomes painted fire (Extras)
	v(1, 2, 1),
	"rbxassetid://70681470264651",
	"rbxassetid://113628937957554",
	v(1.16, 2.93, 1.68),
	0.47,
	0
)
Skins.BrazierSkin =
	enemy(v(2, 3, 2), "rbxassetid://107795354589966", "rbxassetid://95045249802447", v(3.6, 3, 3.6), 0, 0)
-- the archers' posts: a lookout platform, squashed a little so its deck sits where the archer stands (2 up)
Skins.LookoutSkin =
	enemy(v(6, 2, 6), "rbxassetid://110960545732210", "rbxassetid://75028846197346", v(6, 2.9, 6), 0.45, 0)
Skins.ArrowTrapSkin =
	enemy(v(2, 2, 2), "rbxassetid://120914557930002", "rbxassetid://87319073910538", v(2.2, 2.5, 2), 0, 0)
Skins.KegSkin = enemy(v(3, 3.5, 3), "rbxassetid://128811076776832", "rbxassetid://118383684707806", v(3, 3.5, 3), 0, 0)
local DOOR, DOOR_TEX = "rbxassetid://92590501034362", "rbxassetid://80776194066568"
Skins.WoodenDoorSkin = { -- two arched oak doors side by side fill the 12-stud doorway
	Design = v(12, 6, 1),
	Meshes = {
		Left = { Id = DOOR, TextureId = DOOR_TEX, Offset = v(-3, 0, 0), Size = v(6, 6, 1.1), Material = SMOOTH },
		Right = { Id = DOOR, TextureId = DOOR_TEX, Offset = v(3, 0, 0), Size = v(6, 6, 1.1), Material = SMOOTH },
	},
}
-- riveted iron bars: over the IronBars rows (Kai blinks through) and as a portcullis on every castle gate
local BARS, BARS_TEX = "rbxassetid://139056889510355", "rbxassetid://135185022867453"
Skins.BarsSkin = {
	Design = v(10, 6, 0.8),
	Meshes = {
		Left = { Id = BARS, TextureId = BARS_TEX, Offset = v(-2.5, 0, 0), Size = v(5, 6, 0.8), Material = SMOOTH },
		Right = { Id = BARS, TextureId = BARS_TEX, Offset = v(2.5, 0, 0), Size = v(5, 6, 0.8), Material = SMOOTH },
	},
}
Skins.PlateSkin =
	enemy(v(4, 0.6, 4), "rbxassetid://134379174216747", "rbxassetid://111592491650912", v(4.2, 0.7, 4.2), 0, 0)
-- the Siege Cart: an iron-bound mine cart over the plank base (the grey-box walls hide; they still hold the riders)
Skins.CartSkin =
	enemy(v(8, 1, 12), "rbxassetid://79521926071595", "rbxassetid://97938596728357", v(8.4, 5, 12.4), 1.4, 0)
local CRACK, CRACK_TEX = "rbxassetid://106199613711263", "rbxassetid://118275306142450"
Skins.CrackedWallSkin = { -- three cracked sandstone columns across the wall Miko charges through
	Design = v(10, 6, 2),
	Meshes = {
		A = { Id = CRACK, TextureId = CRACK_TEX, Offset = v(-3.33, 0, 0), Size = v(3.5, 6, 2), Material = SMOOTH },
		B = {
			Id = CRACK,
			TextureId = CRACK_TEX,
			Offset = v(0, 0, 0),
			Size = v(3.5, 6, 2),
			Material = SMOOTH,
			Yaw = 180,
		},
		C = { Id = CRACK, TextureId = CRACK_TEX, Offset = v(3.33, 0, 0), Size = v(3.5, 6, 2), Material = SMOOTH },
	},
}
Skins.CheckpointBanner =
	enemy(v(3, 8, 3), "rbxassetid://77877113311583", "rbxassetid://94044277911094", v(3, 8, 3), 0, 0)
Skins.BarricadeSkin =
	enemy(v(10, 5, 1.5), "rbxassetid://96691084781583", "rbxassetid://124296174769582", v(10, 5.2, 2), -0.1, 0)

-- Moonlit courtyard far below the rooms (user's pick, Oct 1, 8th session): realistic-leaning generations
-- (weathered stone, real bark and needles) with only slight stylization, It Takes Two cinematic look.
Skins.CourtTowerTop =
	enemy(v(10, 11.23, 9.82), "rbxassetid://125892169190951", "rbxassetid://106561434667716", v(10, 11.23, 9.82), 0, 0)
Skins.CourtSpruce =
	enemy(v(10, 14.66, 9.92), "rbxassetid://139206506575042", "rbxassetid://73918508940539", v(10, 14.66, 9.92), 0, 0)
Skins.CourtLinden =
	enemy(v(14.96, 17.36, 16), "rbxassetid://126609478543684", "rbxassetid://95011821570692", v(14.96, 17.36, 16), 0, 0)
Skins.CourtLantern =
	enemy(v(3, 8.68, 2.99), "rbxassetid://102429793334089", "rbxassetid://94669498947211", v(3, 8.68, 2.99), 0, 0)
Skins.CourtWell =
	enemy(v(6, 7.74, 4.89), "rbxassetid://115921641059654", "rbxassetid://74742023775359", v(6, 7.74, 4.89), 0, 0)
Skins.CourtCart =
	enemy(v(4.47, 5, 5.72), "rbxassetid://129495207708574", "rbxassetid://137075705561361", v(4.47, 5, 5.72), 0, 0)

local Dressing: { [string]: string } = {
	Torch = "TorchSkin",
	Brazier = "BrazierSkin",
	Barricade = "BarricadeSkin",
	ArcherPost = "LookoutSkin",
	ArrowTrap = "ArrowTrapSkin",
	Keg = "KegSkin",
	WoodenDoor = "WoodenDoorSkin",
	CartBase = "CartSkin",
	CrackedWall = "CrackedWallSkin",
	IronGolem = "IronGolem",
	SpikeRoller = "SpikeRoller",
	GolemPillar = "GolemPillar",
	Mirror = "MirrorSkin",
	Skeleton = "Skeleton",
	SplitSlime = "SplitSlime",
	StaticArcher = "StaticArcher",
	ShieldGuard = "ShieldGuard",
	Shield = "GuardShield",
	StaticMage = "StaticMage",
}

-- Crystals: the skin depends on which fire they take (teal = only Miko's reflected shots, orange = Kai's own), and
-- a light in the crystal's color comes on while it's lit (the grey-box part, which used to turn green, is hidden).
-- Real surfaces (Poly Haven CC0, textures/polyhaven/, MaterialVariants in adventure.project.json): flagstones on
-- every floor, warm sandstone brick on the walls, dark planks on the cart track. The variant's map is tinted by the
-- part's own color, so the palette still reads (warm stone floors, cool purple walls).
local SURFACES: { [Enum.Material]: { any } } = {
	[Enum.Material.Cobblestone] = { "CastleFloor", Color3.fromRGB(205, 196, 214) },
	[Enum.Material.Slate] = { "CastleWall", Color3.fromRGB(178, 160, 210) }, -- cools the warm brick toward purple
	[Enum.Material.WoodPlanks] = { "CastlePlanks", nil },
}

-- Environment fill: the top-down camera looks DOWN, so what's below the rooms fills the frame. Every room floor gets a
-- brick foundation into the dark (the rooms read as one castle mass, not tiles in a void), the cart track gets
-- timber trestle legs (nothing floats), and a night meadow lies far below the kill floor.
local GROUND_Y = -90 -- the moonlit courtyard floor (below KillY, so a fall never lands on it)
local function art(parent: Instance, name: string, size: Vector3, cf: CFrame, props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	for k, value in props do
		(p :: any)[k] = value
	end
	p.Parent = parent
	return p
end

local function fillEnvironment(world: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Environment"
	for _, floor in world:GetDescendants() do
		if floor:IsA("BasePart") and floor.Material == Enum.Material.Cobblestone and floor.Size.Y <= 2.5 then
			local bottom = floor.Position.Y - floor.Size.Y / 2
			local depth = bottom - GROUND_Y -- every room stands on the courtyard (nothing floats)
			art(
				folder,
				"Foundation",
				Vector3.new(floor.Size.X, depth, floor.Size.Z),
				CFrame.new(floor.Position.X, bottom - depth / 2, floor.Position.Z),
				{
					Material = Enum.Material.Slate,
					MaterialVariant = "CastleWall",
					Color = Color3.fromRGB(190, 170, 205), -- lighter: the deep foundations read black at night
				}
			)
		elseif floor:IsA("BasePart") and floor.Name == "TrackBend" then
			local top = floor.Position.Y - 0.5
			local depth = top - GROUND_Y
			art(
				folder,
				"Trestle",
				Vector3.new(depth, 1.6, 1.6),
				CFrame.new(floor.Position.X, top - depth / 2, floor.Position.Z) * CFrame.Angles(0, 0, math.rad(90)),
				{
					Shape = Enum.PartType.Cylinder,
					Material = Enum.Material.WoodPlanks,
					MaterialVariant = "CastlePlanks",
					Color = Color3.fromRGB(150, 110, 70),
				}
			)
		end
	end
	folder.Parent = world
end

-- The moonlit courtyard: a lawn far below with cobbled lanes, curtain walls with battlements on both sides,
-- tall brick towers crowned with slate roofs and a few warm windows, spruce and linden groves, lanterns (small
-- warm pools, memory subtle-lighting), wells and hay carts. Props never sit under a room (foundations are there).
local WALL_GAP, WALL_H, WALL_T = 130, 46, 10
local function courtyard(world: Instance, apply: (BasePart, string) -> boolean)
	local folder = Instance.new("Folder")
	folder.Name = "Courtyard"
	folder.Parent = world
	local rooms = {}
	local x0, x1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge
	for _, f in world:GetDescendants() do
		local isFloor = f:IsA("BasePart")
			and f.Size.Y <= 2.5
			and (f.Material == Enum.Material.Cobblestone or f.Name == "TrackBend")
		if isFloor then
			local a, b = f.Position - f.Size / 2, f.Position + f.Size / 2
			table.insert(rooms, { a.X - 6, b.X + 6, a.Z - 6, b.Z + 6 })
			x0, x1, z0, z1 = math.min(x0, a.X), math.max(x1, b.X), math.min(z0, a.Z), math.max(z1, b.Z)
		end
	end
	if #rooms == 0 then
		return
	end
	local function clear(x: number, z: number, r: number): boolean
		for _, rm in rooms do
			if x + r > rm[1] and x - r < rm[2] and z + r > rm[3] and z - r < rm[4] then
				return false
			end
		end
		return true
	end
	local function prop(name: string, skin: string, scale: number, x: number, z: number, yaw: number): Part?
		local design = Skins[skin].Design * scale
		local holder = art(
			folder,
			name,
			design,
			CFrame.new(x, GROUND_Y + design.Y / 2, z) * CFrame.Angles(0, math.rad(yaw), 0),
			{ Transparency = 1 }
		)
		if apply(holder, skin) then
			return holder
		end
		holder:Destroy()
		return nil
	end

	local wx0, wx1 = x0 - WALL_GAP, x1 + WALL_GAP
	local cz, lz = (z0 + z1) / 2, z1 - z0 + 400
	-- lawn + a cobbled lane inside each wall
	art(
		folder,
		"Lawn",
		Vector3.new(math.min(wx1 - wx0 + 200, 2048), 4, math.min(lz + 200, 2048)),
		CFrame.new((wx0 + wx1) / 2, GROUND_Y - 2, cz),
		{
			Material = Enum.Material.Grass,
			MaterialVariant = "CastleGrass",
			Color = Color3.fromRGB(170, 190, 165),
		}
	)
	for _, lx in { wx0 + 28, wx1 - 28 } do
		art(folder, "Lane", Vector3.new(16, 0.4, lz), CFrame.new(lx, GROUND_Y + 0.2, cz), {
			Material = Enum.Material.Cobblestone,
			MaterialVariant = "CastleFloor",
			Color = Color3.fromRGB(150, 140, 160),
		})
	end
	-- curtain walls with merlons, towers every ~200 studs (brick shaft + generated slate-roofed crown)
	local wallLook =
		{ Material = Enum.Material.Slate, MaterialVariant = "CastleWall", Color = Color3.fromRGB(205, 185, 215) }
	for _, wx in { wx0, wx1 } do
		art(folder, "CurtainWall", Vector3.new(WALL_T, WALL_H, lz), CFrame.new(wx, GROUND_Y + WALL_H / 2, cz), wallLook)
		for z = cz - lz / 2 + 4, cz + lz / 2 - 4, 8 do
			art(folder, "Merlon", Vector3.new(WALL_T + 0.6, 4, 4), CFrame.new(wx, GROUND_Y + WALL_H + 2, z), wallLook)
		end
		local count = math.max(2, math.floor(lz / 200))
		for i = 0, count do
			local tz = cz - lz / 2 + i * lz / count
			local shaftH = WALL_H + 18
			art(
				folder,
				"TowerShaft",
				Vector3.new(shaftH, 24, 24),
				CFrame.new(wx, GROUND_Y + shaftH / 2, tz) * CFrame.Angles(0, 0, math.rad(90)),
				{
					Shape = Enum.PartType.Cylinder,
					Material = Enum.Material.Slate,
					MaterialVariant = "CastleWall",
					Color = Color3.fromRGB(215, 195, 220),
				}
			)
			local crown = art(
				folder,
				"TowerCrown",
				Skins.CourtTowerTop.Design * 2.8,
				CFrame.new(wx, GROUND_Y + shaftH - 4 + Skins.CourtTowerTop.Design.Y * 1.4, tz),
				{ Transparency = 1 }
			)
			if not apply(crown, "CourtTowerTop") then
				crown:Destroy()
			end
			-- two warm slit windows facing the castle (neon only: a light per window cost more than it showed)
			local face = if wx < x0 then 1 else -1
			for k, wy in { 20, 38 } do
				art(
					folder,
					"TowerWindow",
					Vector3.new(0.4, 3.2, 1.6),
					CFrame.new(wx + face * 12, GROUND_Y + wy, tz + (k - 1.5) * 4),
					{ Material = Enum.Material.Neon, Color = Color3.fromRGB(190, 115, 45) }
				)
			end
		end
	end
	-- groves, lanterns along the lanes, wells and carts
	local rng = Random.new(2026)
	for _ = 1, 170 do
		local x = rng:NextNumber(wx0 + 12, wx1 - 12)
		local z = rng:NextNumber(cz - lz / 2, cz + lz / 2)
		local nearLane = math.abs(x - (wx0 + 28)) < 14 or math.abs(x - (wx1 - 28)) < 14
		if not nearLane and clear(x, z, 10) then
			if rng:NextNumber() < 0.65 then
				prop("Spruce", "CourtSpruce", rng:NextNumber(1.8, 3), x, z, rng:NextNumber(0, 360))
			else
				prop("Linden", "CourtLinden", rng:NextNumber(1.4, 2.2), x, z, rng:NextNumber(0, 360))
			end
		end
	end
	for _, lx in { wx0 + 28, wx1 - 28 } do
		local side = if lx < x0 then 1 else -1
		local lit = false
		for z = cz - lz / 2 + 20, cz + lz / 2 - 20, 60 do
			local lantern = prop("Lantern", "CourtLantern", 1.4, lx + side * 10, z, 0)
			lit = not lit
			if lantern and lit then -- every other lantern glows: half the lights, the lanes still read
				local light = Instance.new("PointLight")
				light.Color = Color3.fromRGB(255, 175, 95)
				light.Range = 12
				light.Brightness = 0.6
				light.Parent = lantern
			end
			if rng:NextNumber() < 0.25 then
				prop("Well", "CourtWell", 1.6, lx + side * 22, z + 25, rng:NextNumber(0, 360))
			elseif rng:NextNumber() < 0.35 then
				prop("HayCart", "CourtCart", 1.6, lx - side * 2, z + 30, rng:NextNumber(-20, 20))
			end
		end
	end
	-- the backdrop lies 90+ studs below in the dark: shadows there cost a lot and never show
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then
			d.CastShadow = false
		end
	end
end

local function Extras(world: Instance, apply: (BasePart, string) -> boolean)
	for _, part in world:GetDescendants() do
		local surface = part:IsA("BasePart") and not part:IsA("MeshPart") and SURFACES[part.Material]
		if surface and part.Transparency < 1 then
			part.MaterialVariant = surface[1]
			if surface[2] then
				part.Color = surface[2]
			end
		end
	end
	fillEnvironment(world) -- after the surfaces, so the foundations keep their darker stone
	task.spawn(courtyard, world, apply) -- meshes load async; the rooms never wait on the backdrop
	-- checkpoints: a royal banner standard beside a faint gold pad (the neon pad glared from above)
	for _, pad in world:GetDescendants() do
		if pad:IsA("BasePart") and CollectionService:HasTag(pad, "Checkpoint") then
			pad.Transparency = 0.85
			local banner = art(
				pad.Parent or world,
				"CheckpointBanner",
				Vector3.new(3, 8, 3),
				CFrame.new(pad.Position.X + pad.Size.X / 2 - 1, pad.Position.Y - pad.Size.Y / 2 + 4, pad.Position.Z),
				{ Transparency = 1 }
			)
			if not apply(banner, "CheckpointBanner") then
				banner:Destroy()
			end
		end
	end
	-- every pressure plate: a stone plate in a brass frame with a star rune
	for _, plate in world:GetDescendants() do
		if plate:IsA("BasePart") and CollectionService:HasTag(plate, "PressurePlate") then
			apply(plate, "PlateSkin")
		end
	end
	-- the cart's grey-box walls go invisible under the cart mesh
	for _, wall in world:GetDescendants() do
		if wall:IsA("BasePart") and (wall.Name:match("^Cart%u") and wall.Name ~= "CartBase") then
			if wall.Parent and wall.Parent.Name == "Cart" then
				wall.Transparency = 1
				wall:SetAttribute("ArtHidden", true)
			end
		end
	end
	-- portcullis gates (DuoGate parts named Gate_<group>): iron bars instead of a glowing slab
	for _, gate in world:GetDescendants() do
		if gate:IsA("BasePart") and gate.Name:match("^Gate_") and gate.Material == Enum.Material.Neon then
			apply(gate, "BarsSkin")
		end
	end
	-- rows of grey-box bars (IronBars models): one bars mesh over the whole row
	for _, row in world:GetDescendants() do
		if row:IsA("Model") and row.Name == "IronBars" then
			local cf, size = row:GetBoundingBox()
			local holder = Instance.new("Part")
			holder.Name = "BarsArt"
			holder.Anchored = true
			holder.CanCollide = false
			holder.CanQuery = false
			holder.CanTouch = false
			holder.Transparency = 1
			holder.Size = Vector3.new(math.max(size.X, size.Z), size.Y, 0.8)
			holder.CFrame = if size.Z > size.X then cf * CFrame.Angles(0, math.rad(90), 0) else cf
			holder.Parent = row.Parent
			if apply(holder, "BarsSkin") then
				for _, bar in row:GetChildren() do
					if bar:IsA("BasePart") then
						bar.Transparency = 1
					end
				end
			else
				holder:Destroy()
			end
		end
	end
	-- torch flames: painted fire instead of a neon cube
	for _, flame in world:GetDescendants() do
		if flame.Name == "Flame" and flame:IsA("BasePart") and flame.Parent and flame.Parent.Name == "Torch" then
			flame.Transparency = 1
			CombatFx.Emit(flame, "Flame", 0.8, 14)
			CombatFx.Emit(flame, "Stars", 0.5, 3, CombatFx.Gold)
		end
	end
	for _, crystal in world:GetDescendants() do
		if crystal.Name ~= "Crystal" or not crystal:IsA("BasePart") then
			continue
		end
		local teal = crystal:GetAttribute("Needs") == "Reflected"
		apply(crystal, if teal then "CrystalTeal" else "CrystalOrange")
		local light = Instance.new("PointLight")
		light.Color = if teal then Palette.Miko else Palette.Kai
		light.Range = 14
		light.Brightness = 3
		light.Enabled = false
		light.Parent = crystal
		crystal:GetAttributeChangedSignal("Active"):Connect(function()
			light.Enabled = crystal:GetAttribute("Active") == true
		end)
	end
end

return { Skins = Skins, Dressing = Dressing, Decor = {}, Extras = Extras }
