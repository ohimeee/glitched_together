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
-- brick foundation down to the castle's rock (the rooms read as one castle mass, not tiles in a void), the cart track
-- gets timber trestle legs, and under it all a mountain of real Terrain rock widens down toward the valley of the
-- Blender panorama, so the castle reads as standing on a peak high above the kingdom (Oct 3: replaced box-tier crags).
local GROUND_Y = -90 -- where the brick foundations end, buried in the rock
local ROCK_TOP = -66 -- the rock's crown: just under KillY (-60), so it hugs the foundations but never catches a fall
local MOUNTAIN = {
	Depth = 640, -- how far below the crown the rock reaches (the panorama's valley mist hides the rest)
	Step = 22, -- one faceted block (+ a jutting ledge) per step down
	Spread = 0.15, -- extra half-width per stud of depth: the peak widens into a ridge
	Wander = 0.28, -- sideways noise (studs per stud of depth), so the rock leans and bulges like a real crag
}
-- terrain colors: cool purple-grey rock to sit in the moonlit render, darker slate seams
local TERRAIN_COLORS = {
	[Enum.Material.Rock] = Color3.fromRGB(122, 114, 134),
	[Enum.Material.Slate] = Color3.fromRGB(96, 90, 110),
	[Enum.Material.Basalt] = Color3.fromRGB(84, 78, 96),
}
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

-- A rock column under one footprint: rotated, slightly tilted blocks step down (angular cliff facets, not round
-- lumps), growing and wandering with noise, each with a smaller ledge jutting out; neighboring columns merge into one
-- ridge. Noise seeds keep it the same on every load.
local function rockColumn(terrain: Terrain, x: number, z: number, radius: number)
	local seedX, seedZ = x / 97 + 0.31, z / 89 + 0.17
	local h = MOUNTAIN.Step * 1.8
	for d = 0, MOUNTAIN.Depth, MOUNTAIN.Step do
		local r = radius + d * MOUNTAIN.Spread * (1 + math.noise(seedX, d / 140, seedZ) * 0.6)
		local cx = x + math.noise(seedX, d / 210, 1.7) * d * MOUNTAIN.Wander
		local cz = z + math.noise(2.3, d / 210, seedZ) * d * MOUNTAIN.Wander
		local n = math.noise(cx / 60, d / 45, cz / 60)
		local material = if n > 0.25
			then Enum.Material.Slate
			elseif n < -0.3 then Enum.Material.Basalt
			else Enum.Material.Rock
		local yaw = math.noise(seedX, d / 37, seedZ) * math.pi * 2
		local tilt = math.rad(math.noise(d / 29, seedX, seedZ) * 10)
		local y = ROCK_TOP - h / 2 - d
		terrain:FillBlock(
			CFrame.new(cx, y, cz) * CFrame.Angles(tilt, yaw, -tilt * 0.6),
			Vector3.new(r * 1.9, h, r * 1.6),
			material
		)
		if d > 0 then -- a ledge or buttress of rock jutting out of the face
			local out = math.noise(d / 23, seedZ, seedX) * math.pi * 2
			local lr = r * (0.35 + (math.noise(seedZ, d / 19, 3.1) + 0.5) * 0.3)
			terrain:FillBlock(
				CFrame.new(cx + math.cos(out) * r * 0.85, y - h * 0.2, cz + math.sin(out) * r * 0.85)
					* CFrame.Angles(tilt * 1.5, yaw + out, tilt),
				Vector3.new(lr * 1.6, h * 1.3, lr * 1.2),
				material
			)
		end
	end
end

-- Outer walls: a bare brick cliff of a foundation reads as a Roblox block, so every face that looks out (not into a
-- neighboring room's foundation) gets what a real castle wall has: a stone string course under the floor, buttresses
-- with sloped caps, and arrow slits between them (a few lit warm from inside).
local WALL_TRIM = Color3.fromRGB(214, 200, 222)
local SLIT_DARK = Color3.fromRGB(26, 20, 36)
local SLIT_LIT = Color3.fromRGB(235, 190, 130)
local function dressFoundations(folder: Instance, foundations: { BasePart })
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances = foundations
	local function covered(f: BasePart, at: Vector3): boolean
		for _, other in workspace:GetPartBoundsInBox(CFrame.new(at), Vector3.one, overlap) do
			if other ~= f then
				return true
			end
		end
		return false
	end
	local count = 0
	for _, f in foundations do
		local top = f.Position.Y + f.Size.Y / 2
		local height = f.Size.Y
		for _, n in { Vector3.xAxis, -Vector3.xAxis, Vector3.zAxis, -Vector3.zAxis } do
			local along = Vector3.new(math.abs(n.Z), 0, math.abs(n.X)) -- the face's horizontal direction
			local length = if n.X ~= 0 then f.Size.Z else f.Size.X
			local half = if n.X ~= 0 then f.Size.X / 2 else f.Size.Z / 2
			local face = Vector3.new(f.Position.X, 0, f.Position.Z) + n * half
			local function at(s: number, y: number, out: number): Vector3
				return face + along * s + n * out + Vector3.new(0, y, 0)
			end
			if length >= 10 and not covered(f, at(0, top - 4, 1.5)) then
				art(
					folder,
					"StringCourse",
					Vector3.new(length + 1.2, 1.2, 1.4),
					CFrame.lookAt(at(0, top - 3, 0.5), at(0, top - 3, 2)),
					{
						Material = Enum.Material.Slate,
						MaterialVariant = "CastleWall",
						Color = WALL_TRIM,
					}
				)
				local bays = math.max(1, math.floor(length / 18))
				local bay = length / bays
				for i = 0, bays do
					local s = -length / 2 + i * bay
					if i > 0 and i < bays and not covered(f, at(s, top - 10, 1.5)) then
						local h = height - 10
						art(
							folder,
							"Buttress",
							Vector3.new(3.2, h, 2.4),
							CFrame.lookAt(at(s, top - 8 - h / 2, 1.2), at(s, top - 8 - h / 2, 3)),
							{
								Material = Enum.Material.Slate,
								MaterialVariant = "CastleWall",
								Color = Color3.fromRGB(176, 158, 194),
							}
						)
						local cap = Instance.new("WedgePart")
						cap.Size = Vector3.new(3.2, 3, 2.4)
						cap.CFrame = CFrame.lookAt(at(s, top - 6.5, 1.2), at(s, top - 6.5, 3))
						cap.Material = Enum.Material.Slate
						cap.MaterialVariant = "CastleWall"
						cap.Color = WALL_TRIM
						cap.Anchored, cap.CanCollide, cap.CanQuery, cap.CanTouch = true, false, false, false
						cap.Name = "ButtressCap"
						cap.Parent = folder
					end
					if i < bays then -- arrow slits in the middle of the bay, one per 20 studs of wall height
						local ms = s + bay / 2
						for y = top - 14, top - height + 12, -20 do
							if not covered(f, at(ms, y, 1.5)) then
								count += 1
								local lit = count % 5 == 0
								art(
									folder,
									"ArrowSlit",
									Vector3.new(1, 4.5, 0.3),
									CFrame.lookAt(at(ms, y, 0.1), at(ms, y, 2)),
									{
										Material = if lit then Enum.Material.SmoothPlastic else Enum.Material.Slate,
										Color = if lit then SLIT_LIT else SLIT_DARK,
										CastShadow = false,
									}
								)
							end
						end
					end
				end
			end
		end
	end
end

-- Corner turrets: round towers at every exposed room corner give the long castle a real silhouette from the wide
-- shots (cutscenes, the panorama-side view). The top-down camera sits on the +Z side, so only the far (−Z) corners
-- get tall stepped slate roofs; near corners stop at a crenellated ring just above the wall tops.
local TURRET_R = 5.5
local SLATE_ROOF = Color3.fromRGB(122, 112, 156)
local function turrets(folder: Instance, foundations: { BasePart })
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances = foundations
	local function stone(name: string, size: Vector3, cf: CFrame, color: Color3?, cylinder: boolean?)
		return art(folder, name, size, cf, {
			Material = Enum.Material.Slate,
			MaterialVariant = "CastleWall",
			Color = color or Color3.fromRGB(184, 166, 202),
			Shape = if cylinder then Enum.PartType.Cylinder else Enum.PartType.Block,
		})
	end
	local placed: { Vector3 } = {}
	for _, f in foundations do
		if f.Size.X < 20 or f.Size.Z < 20 then
			continue -- tiles and small pads inside rooms
		end
		local top = f.Position.Y + f.Size.Y / 2 + 1.5 -- the floor's top
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local corner = Vector3.new(f.Position.X + sx * f.Size.X / 2, 0, f.Position.Z + sz * f.Size.Z / 2)
				local out = Vector3.new(sx, 0, sz).Unit
				-- an outer corner: the corner itself and the ground just outside it on all three sides are free of
				-- every other foundation (else it's a joint between rooms or inside a bigger room)
				local covered = false
				for _, d in { Vector3.zero, out * 4, Vector3.new(sx * 4, 0, 0), Vector3.new(0, 0, sz * 4) } do
					local probe = corner + d * 1 + Vector3.new(0, top - 10, 0) - out * 0.5
					if d ~= Vector3.zero then
						probe += out * 0.5
					end
					for _, other in workspace:GetPartBoundsInBox(CFrame.new(probe), Vector3.one, overlap) do
						if other ~= f then
							covered = true
						end
					end
				end
				for _, p in placed do
					if (p - corner).Magnitude < 14 then
						covered = true
					end
				end
				if covered then
					continue
				end
				table.insert(placed, corner)
				local c = corner + out * 3.2
				-- roofs only where nothing of the castle lies behind the turret (on screen, above it): at room joints a
				-- roof would sit in the middle of the top-down view
				local far = sz < 0
				if far then
					local behind = CFrame.new(c.X, top - 10, c.Z - 30)
					for _, other in workspace:GetPartBoundsInBox(behind, Vector3.new(12, 4, 56), overlap) do
						if other ~= f then
							far = false
						end
					end
				end
				local height = if far then 9 else 7.5
				local bottomY = ROCK_TOP - 4
				local shaftH = top + height - bottomY
				stone(
					"Turret",
					Vector3.new(shaftH, TURRET_R * 2, TURRET_R * 2),
					CFrame.new(c.X, bottomY + shaftH / 2, c.Z) * CFrame.Angles(0, 0, math.rad(90)),
					nil,
					true
				)
				-- corbelled parapet ring + merlons
				stone(
					"TurretParapet",
					Vector3.new(1.4, TURRET_R * 2 + 1.6, TURRET_R * 2 + 1.6),
					CFrame.new(c.X, top + height - 0.3, c.Z) * CFrame.Angles(0, 0, math.rad(90)),
					WALL_TRIM,
					true
				)
				for k = 0, 7 do
					local a = k / 8 * math.pi * 2
					local p = c + Vector3.new(math.cos(a), 0, math.sin(a)) * (TURRET_R + 0.3)
					stone(
						"TurretMerlon",
						Vector3.new(1.6, 1.8, 1.2),
						CFrame.new(p.X, top + height + 1.3, p.Z) * CFrame.Angles(0, -a, 0),
						WALL_TRIM
					)
				end
				-- arrow slits up the shaft, one lit
				for y = top - 10, bottomY + 14, -18 do
					local a = math.atan2(out.Z, out.X)
					local p = c + out * (TURRET_R - 0.05)
					art(
						folder,
						"ArrowSlit",
						Vector3.new(0.3, 4, 1),
						CFrame.new(p.X, y, p.Z) * CFrame.Angles(0, -a, 0),
						{
							Material = Enum.Material.Slate,
							Color = if y == top - 10 then SLIT_LIT else SLIT_DARK,
							CastShadow = false,
						}
					)
				end
				if far then -- a stepped slate cone roof with a little banner pole
					local steps = 14
					for k = 0, steps - 1 do
						local r = (TURRET_R + 1.2) * (1 - k / steps)
						stone(
							"TurretRoof",
							Vector3.new(0.9, r * 2, r * 2),
							CFrame.new(c.X, top + height + 0.8 + k * 0.8, c.Z) * CFrame.Angles(0, 0, math.rad(90)),
							SLATE_ROOF,
							true
						)
					end
					local poleTop = top + height + 0.8 + steps * 0.8 + 4
					art(folder, "TurretPole", Vector3.new(0.3, 5, 0.3), CFrame.new(c.X, poleTop - 2.5, c.Z), {
						Material = Enum.Material.Metal,
						Color = Color3.fromRGB(60, 58, 70),
					})
					art(
						folder,
						"TurretPennant",
						Vector3.new(2.4, 1.2, 0.1),
						CFrame.new(c.X + 1.25, poleTop - 0.8, c.Z),
						{
							Material = Enum.Material.Fabric,
							Color = Color3.fromRGB(110, 70, 160), -- castle night purple (not an owner color)
						}
					)
				end
			end
		end
	end
end

local function fillEnvironment(world: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Environment"
	local terrain = workspace.Terrain
	for material, color in TERRAIN_COLORS do
		terrain:SetMaterialColor(material, color)
	end
	local columns: { { number } } = {}
	local foundations: { BasePart } = {}
	local function column(x: number, z: number, radius: number)
		for _, c in columns do -- a footprint already covered by a bigger column nearby: skip it (keeps the fill fast)
			if (c[1] - x) ^ 2 + (c[2] - z) ^ 2 < (c[3] * 0.6) ^ 2 and c[3] >= radius * 0.8 then
				return
			end
		end
		table.insert(columns, { x, z, radius })
	end
	for _, floor in world:GetDescendants() do
		if floor:IsA("BasePart") and floor.Material == Enum.Material.Cobblestone and floor.Size.Y <= 2.5 then
			local bottom = floor.Position.Y - floor.Size.Y / 2
			local depth = bottom - GROUND_Y -- every room stands on the mountain (nothing floats)
			-- rock under the whole footprint: one column per ~40 studs of floor
			local nx = math.max(1, math.round(floor.Size.X / 40))
			local nz = math.max(1, math.round(floor.Size.Z / 40))
			local cell = math.max(floor.Size.X / nx, floor.Size.Z / nz)
			for i = 1, nx do
				for k = 1, nz do
					local lx = (i - 0.5) / nx * floor.Size.X - floor.Size.X / 2
					local lz = (k - 0.5) / nz * floor.Size.Z - floor.Size.Z / 2
					local p = floor.CFrame * Vector3.new(lx, 0, lz)
					column(p.X, p.Z, cell * 0.72 + 6)
				end
			end
			foundations[#foundations + 1] = art(
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
			column(floor.Position.X, floor.Position.Z, 7) -- a rock spur under each trestle leg
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
	dressFoundations(folder, foundations)
	turrets(folder, foundations)
	task.spawn(function() -- in the background: the rest of the dressing doesn't wait for the rock
		for _, c in columns do
			if not world.Parent then
				return -- the world was unloaded mid-fill (ArtService clears the terrain on the next load)
			end
			rockColumn(terrain, c[1], c[2], c[3])
			task.wait()
		end
	end)
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
	-- textiles (Poly Haven CC0, textures/make_castle_fabric.py): the long royal rug is patterned jacquard, the
	-- hanging sign banners are velvet; both keep their own color (the maps are grey and tintable)
	for _, part in world:GetDescendants() do
		if part:IsA("BasePart") and part.Material == Enum.Material.Fabric then
			if part.Name == "Rug" then
				part.MaterialVariant = "CastleRug"
			elseif part.Name == "Sign" then
				part.MaterialVariant = "CastleVelvet"
			end
		end
	end
	fillEnvironment(world) -- after the surfaces, so the foundations keep their darker stone
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
