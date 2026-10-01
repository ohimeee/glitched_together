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
-- brick foundation into the dark (the rooms read as one castle mass, not tiles in a void), the cart track gets
-- timber trestle legs (nothing floats), and a night meadow lies far below the kill floor.
local FOUNDATION_DEPTH = 38
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
			art(
				folder,
				"Foundation",
				Vector3.new(floor.Size.X, FOUNDATION_DEPTH, floor.Size.Z),
				CFrame.new(floor.Position.X, bottom - FOUNDATION_DEPTH / 2, floor.Position.Z),
				{
					Material = Enum.Material.Slate,
					MaterialVariant = "CastleWall",
					Color = Color3.fromRGB(120, 104, 150),
				}
			)
		elseif floor:IsA("BasePart") and floor.Name == "TrackBend" then
			local top = floor.Position.Y - 0.5
			art(
				folder,
				"Trestle",
				Vector3.new(FOUNDATION_DEPTH, 1.6, 1.6),
				CFrame.new(floor.Position.X, top - FOUNDATION_DEPTH / 2, floor.Position.Z)
					* CFrame.Angles(0, 0, math.rad(90)),
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

-- Starfall Castle rides a sea of night clouds: soft lavender clouds drift below and around the rooms (well under the
-- floors, non-colliding), so the top-down view looks down onto a sky instead of an empty void.
local CLOUD_DESIGN = Vector3.new(22, 8, 8) -- PixelPlains Cloud skin
local function cloudSea(world: Instance, apply: (BasePart, string) -> boolean)
	local folder = world:FindFirstChild("Environment") or world
	local rng = Random.new(1997)
	for z = -60, 1560, 26 do
		for _ = 1, 3 do
			local side = if rng:NextNumber() < 0.5 then -1 else 1
			local x = side * rng:NextNumber(18, 140)
			local scale = rng:NextNumber(1.6, 3.4)
			local holder = art(
				folder,
				"NightCloud",
				CLOUD_DESIGN * scale,
				CFrame.new(x, rng:NextNumber(-58, -30), z + rng:NextNumber(-10, 10))
					* CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), 0),
				{ Transparency = 1 }
			)
			if apply(holder, "Cloud") then
				for _, mesh in holder:GetChildren() do
					if mesh:IsA("MeshPart") then
						mesh.MaterialVariant = "" -- soft, not Pixel Plains' pixel plastic
						mesh.Material = Enum.Material.SmoothPlastic
						mesh.Color = Color3.fromRGB(150, 128, 200)
						mesh.CastShadow = false
					end
				end
			else
				holder:Destroy()
			end
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
	task.spawn(cloudSea, world, apply)
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
			CombatFx.Emit(flame, "Flame", 1.1, 22)
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
