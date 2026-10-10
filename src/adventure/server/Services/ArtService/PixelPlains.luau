-- Pixel Plains art (blender_assets/PixelPlains.*, briefs/PixelPlains.md). 1-stud voxels with small bevels, exact
-- art-direction.md palette; gameplay pieces wear their OWNER's color (Kai orange frames on freezables, Miko teal
-- ring and crate handles). Offsets/sizes are generated from Blender (studs, front = -Z) at each Design size.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)
local StateInlay = require(script.Parent.StateInlay)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local CombatFx = require(script.Parent.Parent.CombatFx)
local ToolFx = require(ReplicatedStorage.Shared.Config.ToolFx)

local PP = Palette.PixelPlains
local SMOOTH = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon
local PLASTIC = "PixelPlastic" -- ArtService/Materials: toy plastic with a soft pixel grid
local v = Vector3.new

local KING_ATLAS = "rbxassetid://101000082699383"

local Skins: { [string]: MeshAssets.Skin } = {
	-- The Crusher King (tools/crusher_king/kit.py): painted wooden toy cubes, one mesh per grey-box part, all on one
	-- palette atlas (textures/make_king_palette.py)
	KingArm = {
		Design = v(8, 18, 10),
		Meshes = {
			CK_Arm = {
				Id = "rbxassetid://139603453996521",
				TextureId = KING_ATLAS,
				Offset = v(0, 0, 0),
				Size = v(8, 18, 10),
				Material = SMOOTH,
				Color = Color3.new(1, 1, 1),
			},
		},
	},
	KingBelt = {
		Design = v(30, 12, 4),
		Meshes = {
			CK_Belt = {
				Id = "rbxassetid://84926330741099",
				TextureId = KING_ATLAS,
				Offset = v(0, 0, 0),
				Size = v(30, 12, 4),
				Material = SMOOTH,
				Color = Color3.new(1, 1, 1),
			},
		},
	},
	KingCrown = {
		Design = v(14, 8, 14),
		Meshes = {
			CK_Crown = {
				Id = "rbxassetid://112801799315417",
				TextureId = KING_ATLAS,
				Offset = v(0, 0, 0),
				Size = v(14, 8, 14),
				Material = SMOOTH,
				Color = Color3.new(1, 1, 1),
			},
		},
	},
	KingFist = {
		Design = v(12, 10, 12),
		Meshes = {
			CK_Fist = {
				Id = "rbxassetid://114716790022423",
				TextureId = KING_ATLAS,
				Offset = v(0, 0, 0),
				Size = v(12, 10, 12),
				Material = SMOOTH,
				Color = Color3.new(1, 1, 1),
			},
		},
	},
	KingHead = {
		Design = v(20, 18, 18),
		Meshes = {
			CK_Head = {
				Id = "rbxassetid://103502743668611",
				TextureId = KING_ATLAS,
				Offset = v(0, 0, 0),
				Size = v(20, 18, 18),
				Material = SMOOTH,
				Color = Color3.new(1, 1, 1),
			},
		},
	},
	KingLap = {
		Design = v(40, 18, 12),
		Meshes = {
			CK_Lap = {
				Id = "rbxassetid://124566979589837",
				TextureId = KING_ATLAS,
				Offset = v(0, 0, 0),
				Size = v(40, 18, 12),
				Material = SMOOTH,
				Color = Color3.new(1, 1, 1),
			},
		},
	},
	KingShoulder = {
		Design = v(12, 6, 14),
		Meshes = {
			CK_Shoulder = {
				Id = "rbxassetid://103810746977690",
				TextureId = KING_ATLAS,
				Offset = v(0, 0, 0),
				Size = v(12, 6, 14),
				Material = SMOOTH,
				Color = Color3.new(1, 1, 1),
			},
		},
	},
	KingThrone = {
		Design = v(44, 17, 28),
		Meshes = {
			CK_Throne = {
				Id = "rbxassetid://74735935285484",
				TextureId = KING_ATLAS,
				Offset = v(0, 0, 0),
				Size = v(44, 17, 28),
				Material = SMOOTH,
				Color = Color3.new(1, 1, 1),
			},
		},
	},
	KingThroneBack = {
		Design = v(44, 48, 6),
		Meshes = {
			CK_ThroneBack = {
				Id = "rbxassetid://72797592136849",
				TextureId = KING_ATLAS,
				Offset = v(0, 0, 0),
				Size = v(44, 48, 6),
				Material = SMOOTH,
				Color = Color3.new(1, 1, 1),
			},
		},
	},
	KingTorso = {
		Design = v(36, 24, 16),
		Meshes = {
			CK_Torso = {
				Id = "rbxassetid://112613268278407",
				TextureId = KING_ATLAS,
				Offset = v(0, 0, 0),
				Size = v(36, 24, 16),
				Material = SMOOTH,
				Color = Color3.new(1, 1, 1),
			},
		},
	},
	GrassBlock = {
		Design = v(20, 6, 20),
		Meshes = {
			PP_Kit_GrassBlock_Top = {
				Id = "rbxassetid://100845406324953",
				Offset = v(0, 1, 0),
				Size = v(20.4, 4, 20.4),
				Material = SMOOTH,
				Variant = PLASTIC,
				Color = PP.Grass,
			},
			PP_Kit_GrassBlock_Dirt = {
				Id = "rbxassetid://82021329167270",
				Offset = v(0, -0.475, 0),
				Size = v(19.7, 5.05, 19.7),
				Material = SMOOTH,
				Variant = PLASTIC,
				Color = PP.Dirt,
			},
			PP_Kit_GrassBlock_Spots = {
				Id = "rbxassetid://100055342018700",
				Offset = v(0, -1.65, 0),
				Size = v(19.9, 1.5, 19.9),
				Material = SMOOTH,
				Variant = PLASTIC,
				Color = Color3.fromHex("#8A5A2E"),
			},
		},
	},
	MoveBlock = {
		Design = v(10, 2, 10),
		Meshes = {
			PP_Kit_MoveBlock_Body = {
				Id = "rbxassetid://131819066639725",
				Offset = v(0, 0, 0),
				Size = v(9.7, 1.9, 9.7),
				Material = SMOOTH,
				Variant = PLASTIC,
				Color = Color3.fromHex("#E8E4D8"),
			},
			PP_Kit_MoveBlock_Frame = {
				Id = "rbxassetid://121713743901075",
				Offset = v(0, 0, 0),
				Size = v(10, 2, 10),
				Material = NEON,
				Color = Palette.Glow.Kai, -- freezable = Kai's target
			},
		},
	},
	Crusher = {
		Design = v(9, 8, 12),
		Meshes = {
			PP_Prop_Crusher_Body = {
				Id = "rbxassetid://133845631228282",
				Offset = v(0, 0.3, 0),
				Size = v(9.1, 6.6, 11.6),
				Material = SMOOTH,
				Variant = PLASTIC,
				Color = Color3.fromHex("#3C3C4B"),
			},
			PP_Prop_Crusher_Hazard = {
				Id = "rbxassetid://108211916950350",
				Offset = v(0.15, 0.4, 0),
				Size = v(7.7, 2, 12),
				Material = NEON,
				Color = Palette.Glow.Danger,
			},
			PP_Prop_Crusher_Teeth = {
				Id = "rbxassetid://124152329070211",
				Offset = v(-0.2, -3.45, 0.4),
				Size = v(8.1, 1.1, 11.3),
				Material = SMOOTH,
				Color = Color3.fromHex("#2A2A35"),
			},
			PP_Prop_Crusher_Frame = {
				Id = "rbxassetid://121775142188691",
				Offset = v(0, 3.675, 0),
				Size = v(9, 0.65, 12),
				Material = NEON,
				Color = Palette.Glow.Kai, -- freezable = Kai's target
			},
		},
	},
	GrappleRing = {
		Design = v(1, 3, 3),
		Meshes = {
			PP_Prop_GrappleRing = {
				Id = "rbxassetid://75993006199428",
				Offset = v(0, 0, 0),
				Size = v(0.6, 3, 3),
				Material = NEON,
				Color = Palette.Glow.Miko, -- Miko's target
			},
		},
	},
	Crate = {
		Design = v(4, 4, 4),
		Meshes = {
			PP_Prop_Crate_Wood = {
				Id = "rbxassetid://80189721082332",
				Offset = v(0, 0, 0),
				Size = v(3.6, 3.9, 3.6),
				Material = Enum.Material.WoodPlanks,
				Color = Color3.fromHex("#C8964B"),
			},
			PP_Prop_Crate_Edge = {
				Id = "rbxassetid://93456286978753",
				Offset = v(0, 0, 0),
				Size = v(3.9, 4, 3.9),
				Material = Enum.Material.Wood,
				Color = Color3.fromHex("#7A5230"),
			},
			PP_Prop_Crate_Handle = {
				Id = "rbxassetid://139921594652396",
				Offset = v(0, 0.45, 0),
				Size = v(4, 0.6, 4),
				Material = NEON,
				Color = Palette.Glow.Miko, -- pullable = Miko's target
			},
		},
	},
	Cloud = {
		Design = v(22, 8, 8),
		Meshes = {
			PP_Prop_Cloud = {
				Id = "rbxassetid://90904373864800",
				Offset = v(0, 0, 0),
				Size = v(22, 8, 7),
				Material = SMOOTH,
				Variant = PLASTIC,
				Color = PP.Cloud,
			},
		},
	},
	CoinBlock = {
		Design = v(4, 4, 4),
		Meshes = {
			PP_Prop_CoinBlock_Body = {
				Id = "rbxassetid://120682677424503",
				Offset = v(0, 0, 0),
				Size = v(3.7, 3.7, 3.7),
				Material = SMOOTH,
				Variant = PLASTIC,
				Color = PP.Gold,
			},
			PP_Prop_CoinBlock_Frame = {
				Id = "rbxassetid://139212127358567",
				Offset = v(0, 0, 0),
				Size = v(4, 4, 4),
				Material = SMOOTH,
				Variant = PLASTIC,
				Color = Color3.fromHex("#C8961E"),
			},
			PP_Prop_CoinBlock_Mark = {
				Id = "rbxassetid://84329453189889",
				Offset = v(0, 0, 0),
				Size = v(3.9, 2.5, 3.9),
				Material = SMOOTH,
				Color = Palette.Duo, -- a white pixel star (our own coin block, not a "?")
			},
		},
	},
}

-- Art pass 2 (briefs/PixelPlains2.md): Blender kit for the rebuilt layout (PixelPlainsKit2.*) and generated props.
-- Kit offsets are from Blender (piece bbox center relative to the part center, Roblox axes).
local function gen(
	id: string,
	tex: string,
	design: Vector3,
	size: Vector3,
	offset: Vector3?,
	yaw: number?
): MeshAssets.Skin
	return {
		Design = design,
		Meshes = {
			Body = {
				Id = id,
				TextureId = tex,
				Offset = offset or v(0, 0, 0),
				Size = size,
				Material = SMOOTH,
				Yaw = yaw,
			},
		},
	}
end

Skins.Cliff = {
	Design = v(20, 20, 20),
	Meshes = {
		PP_Kit_Cliff_Top = {
			Id = "rbxassetid://73194612964423",
			Offset = v(0, 7.5, 0),
			Size = v(20.5, 5, 20.5),
			Material = SMOOTH,
			Variant = PLASTIC,
			Color = PP.Grass,
		},
		PP_Kit_Cliff_Dirt = {
			Id = "rbxassetid://132715282506690",
			Offset = v(0, -0.8, 0),
			Size = v(20, 18.4, 20),
			Material = SMOOTH,
			Variant = PLASTIC,
			Color = PP.Dirt,
		},
		PP_Kit_Cliff_Strata = {
			Id = "rbxassetid://95695557584433",
			Offset = v(0, -1.4, 0),
			Size = v(20.24, 6.2, 20.24),
			Material = SMOOTH,
			Variant = PLASTIC,
			Color = Color3.fromHex("#8A5A2E"),
		},
		PP_Kit_Cliff_Stones = {
			Id = "rbxassetid://131737597349680",
			Offset = v(0.099, -2.452, -0.039),
			Size = v(21.49, 13.2, 21.62),
			Material = SMOOTH,
			Color = Color3.fromHex("#9A9AA6"),
		},
	},
}
Skins.DirtWall = {
	Design = v(2, 20, 20),
	Meshes = {
		PP_Kit_DirtWall_Bricks = {
			Id = "rbxassetid://127532238967506",
			Offset = v(0, 0, 0),
			Size = v(2, 19.84, 20),
			Material = SMOOTH,
			Color = PP.Dirt,
		},
		PP_Kit_DirtWall_Core = {
			Id = "rbxassetid://88505239808610",
			Offset = v(0, -0.5, 0),
			Size = v(1.6, 19, 20),
			Material = SMOOTH,
			Variant = PLASTIC,
			Color = Color3.fromHex("#8A5A2E"),
		},
		PP_Kit_DirtWall_Top = {
			Id = "rbxassetid://73396039066734",
			Offset = v(0, 9.1, 0),
			Size = v(2.3, 1.8, 20.2),
			Material = SMOOTH,
			Variant = PLASTIC,
			Color = PP.Grass,
		},
	},
}
-- Voxel ground (Oct 3, 15th session; user: "remake the ground, the walls, the stone"): instead of one mesh stretched
-- over every floor size, the grey-box part itself becomes a block of one-stud cubes through tiling MaterialVariants
-- (PPGrass / PPDirt / PPStone, textures/make_pp_voxel_surfaces.py), with bands as thin shells just outside it:
-- a grass cap on top, and on cliffs a dirt band under the grass over a stone body. Same look at any size.
local WHITE = Color3.new(1, 1, 1)
-- a soft multiply on the maps: direct sun made the grass read lime and the dirt orange (playtest shots, Oct 4)
local VOXEL_TINT = {
	PPGrass = Color3.fromRGB(214, 222, 204),
	PPDirt = Color3.fromRGB(228, 218, 208),
}
local function shell(part: BasePart, name: string, height: number, fromTop: number, variant: string, weld: boolean)
	local size = part.Size
	local h = math.min(height, size.Y - fromTop)
	if h <= 0.05 then
		return
	end
	local grow = 0.08 * (1 + fromTop * 0.01) -- each band a hair wider than the one above it never z-fights
	local p = Instance.new("Part")
	p.Name = name
	p.Size = Vector3.new(size.X + grow, h + 0.04, size.Z + grow)
	p.CFrame = part.CFrame * CFrame.new(0, size.Y / 2 - fromTop - h / 2 + 0.02, 0)
	p.Material = SMOOTH
	p.MaterialVariant = variant
	p.Color = VOXEL_TINT[variant] or WHITE
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Anchored = not weld
	p.Massless = true
	if weld then
		local w = Instance.new("WeldConstraint")
		w.Part0 = part
		w.Part1 = p
		w.Parent = p
	end
	p.Parent = part
end
local function body(part: BasePart, variant: string)
	part.Material = SMOOTH
	part.MaterialVariant = variant
	part.Color = VOXEL_TINT[variant] or WHITE
	part.Transparency = 0
end
local function voxelSkin(design: Vector3, build: (BasePart, boolean) -> ()): MeshAssets.Skin
	return { Design = design, Meshes = {}, Build = build }
end
Skins.GrassBlock = voxelSkin(v(20, 6, 20), function(part, weld)
	body(part, "PPDirt")
	shell(part, "GrassCap", 1, 0, "PPGrass", weld)
end)
Skins.Cliff = voxelSkin(v(20, 20, 20), function(part, weld)
	body(part, "PPStone")
	shell(part, "GrassCap", 1, 0, "PPGrass", weld)
	shell(part, "DirtBand", math.clamp(part.Size.Y * 0.2, 2, 5), 1, "PPDirt", weld)
end)
Skins.DirtWall = voxelSkin(v(4, 10, 20), function(part, weld)
	body(part, "PPDirt")
	shell(part, "GrassCap", 1, 0, "PPGrass", weld)
end)

Skins.Belt = {
	Design = v(14, 2.45, 30),
	Meshes = {
		PP_Kit_Belt_Frame = {
			Id = "rbxassetid://131185547489554",
			Offset = v(0, -0.075, 0),
			Size = v(14, 2.3, 30),
			Material = Enum.Material.Metal,
			Color = Color3.fromHex("#5A5A66"),
		},
		PP_Kit_Belt_Belt = {
			Id = "rbxassetid://104161523408844",
			Offset = v(0, 0.55, 0),
			Size = v(12, 0.45, 30),
			Material = Enum.Material.Rubber,
			Color = Color3.fromHex("#2E2E36"),
			-- tread with painted chevrons (textures/PP_BeltTread3.png); BeltController scrolls it at the belt's speed
			Texture = {
				Id = "rbxassetid://108056695290827",
				Face = Enum.NormalId.Top,
				StudsPerTile = Vector2.new(12, 12),
				Offset = Vector2.new(6, 0), -- centers the chevrons across the belt
				Tag = "BeltScroll",
			},
		},
		PP_Kit_Belt_Glow = {
			Id = "rbxassetid://134386850518263",
			Offset = v(0, 1.15, 0),
			Size = v(14.1, 0.15, 30),
			Material = NEON,
			Color = Palette.Glow.Kai, -- freezable = Kai's target
		},
	},
}
-- generated (textured) props and enemies
Skins.GlitchBlobSkin =
	gen("rbxassetid://111365424915916", "rbxassetid://105026392006200", v(4, 3, 4), v(3.7, 4.05, 2.9), v(0, 0.5, 0))
Skins.BouncePadSkin =
	gen("rbxassetid://127413358129106", "rbxassetid://86478495845252", v(8, 1, 8), v(7.6, 1.8, 7.6), v(0, 0.35, 0))
Skins.StaticBatSkin = gen("rbxassetid://138838808176158", "rbxassetid://134256509753880", v(3, 2, 3), v(4.7, 2.5, 2.25))
-- Voxel trees and bushes (tools/pp_trees/trees.py, atlas textures/tree_palette.png): fitted into the old Tree / Bush
-- design boxes, base on the box bottom, so every placement keeps working. Placements mix the variants (TREES/BUSHES).
local TREE_ATLAS = "rbxassetid://130966209816773"
Skins.Tree = gen("rbxassetid://72409509512406", TREE_ATLAS, v(12, 16, 12), v(12, 12.96, 11.52), v(0, -1.52, 0))
Skins.TreeApple = gen("rbxassetid://114520128966291", TREE_ATLAS, v(12, 16, 12), v(12, 13.09, 11.45), v(0, -1.455, 0))
Skins.TreePine = gen("rbxassetid://93784432245555", TREE_ATLAS, v(12, 16, 12), v(10.86, 16, 12))
Skins.TreeBirch = gen("rbxassetid://130735768036343", TREE_ATLAS, v(12, 16, 12), v(8.26, 16, 7.23))
-- voxel props (tools/pp_trees/trees.py: flowers / rock / tuft, same atlas family as the trees)
local PROP_ATLAS = "rbxassetid://111423425443469"
Skins.Flowers = gen("rbxassetid://138607135488831", PROP_ATLAS, v(3.3, 3, 2.2), v(3.3, 2.28, 2.03), v(0, -0.36, 0))
Skins.Flowers2 = gen("rbxassetid://140248905620754", PROP_ATLAS, v(3.3, 3, 2.2), v(2.93, 2.2, 2.2), v(0, -0.4, 0))
Skins.Flowers3 = gen("rbxassetid://95729661197876", PROP_ATLAS, v(3.3, 3, 2.2), v(3.3, 2.7, 2.1), v(0, -0.15, 0))
Skins.Rock = gen("rbxassetid://126431877788942", PROP_ATLAS, v(2.5, 2.5, 3.5), v(2.5, 2.5, 3.5))
Skins.Rock2 = gen("rbxassetid://105935790012403", PROP_ATLAS, v(4, 3, 4), v(4, 3, 4))
Skins.Tuft = gen("rbxassetid://77719326350444", PROP_ATLAS, v(1.25, 1.25, 1.25), v(1.25, 1.25, 1.25))
local FLOWERS = { "Flowers", "Flowers2", "Flowers3" }
Skins.Bush = gen("rbxassetid://116906613547234", TREE_ATLAS, v(2.9, 4, 2.9), v(2.9, 2.54, 2.9), v(0, -0.73, 0))
Skins.Bush2 = gen("rbxassetid://99808273007113", TREE_ATLAS, v(2.9, 4, 2.9), v(2.54, 2.9, 2.9), v(0, -0.55, 0))
local TREES = { "Tree", "TreeApple", "TreePine", "TreeBirch" }
local BUSHES = { "Bush", "Bush2" }
-- Crusher King throne hall (tools/boss_arena/kit.py, atlas textures/arena_palette.png): voxel ruin pieces at their
-- real size (Design = mesh size), placed by bossHall below
local ARENA_ATLAS = "rbxassetid://84416091769164"
local ARENA: { [string]: { any } } = { -- name → { mesh id, size }
	BA_Pillar = { "rbxassetid://125757701055742", v(12, 75, 12) },
	BA_PillarBroken = { "rbxassetid://120930010774517", v(12, 52, 12) },
	BA_PillarStump = { "rbxassetid://93380107224178", v(12, 27, 12) },
	BA_Lintel = { "rbxassetid://98415486021594", v(28, 7, 8) },
	BA_Banner = { "rbxassetid://103140405128731", v(12, 32, 3.5) },
	BA_BannerTorn = { "rbxassetid://72126327008136", v(12, 32, 3.5) },
	BA_BackWall = { "rbxassetid://117825756850990", v(84, 136, 12) },
	BA_Tower = { "rbxassetid://127269975718155", v(26, 154, 28) },
	BA_TowerBroken = { "rbxassetid://112924534029546", v(26, 108, 24) },
	BA_Gate = { "rbxassetid://96179893394641", v(32, 41, 8) },
	BA_Carpet = { "rbxassetid://89792813995144", v(8, 0.5, 20) },
	BA_Rubble1 = { "rbxassetid://89189290516774", v(13, 7, 12) },
	BA_Rubble2 = { "rbxassetid://127888772057192", v(10, 7, 14) },
	BA_Brazier = { "rbxassetid://71754839277874", v(5, 6, 5) },
}
for name, info in ARENA do
	if info[1] ~= "" then
		Skins[name] = gen(info[1], ARENA_ATLAS, info[2], info[2])
	end
end

-- Kit 3 (blender_assets/PixelPlainsKit3.*): signs, timed door, pull lever, dropper chute, "BY KAI + MIKO" letters.
-- Real surfaces from Roblox materials (wood grain, metal); owner glow only on the gameplay part of each target.
local WOOD = Color3.fromHex("#C8964B")
local WOOD_DARK = Color3.fromHex("#7A5230")
local IRON = Color3.fromHex("#4A4A55")
-- Voxel notice board (tools/pp_trees/trees.py sign_board; refs: stylized game signs: uneven planks in three tones,
-- a shingle cap, iron brackets and battens behind so the painted text on the grey-box part's front face stays clear)
local SIGN_ATLAS = "rbxassetid://133498206345624"
Skins.Sign = {
	Design = v(14, 3, 0.4),
	Meshes = {
		PP_SignBoard = {
			Id = "rbxassetid://85936959636038",
			TextureId = SIGN_ATLAS,
			Offset = v(0, 0.25, 0.125),
			Size = v(15.25, 4.25, 1.5),
			Material = SMOOTH,
			Color = Color3.new(1, 1, 1),
		},
	},
}
Skins.SignPost = {
	Design = v(0.9, 6, 0.9),
	Meshes = {
		PP_SignPost = {
			Id = "rbxassetid://135303045095115",
			TextureId = SIGN_ATLAS,
			Offset = v(0, 0, 0),
			Size = v(0.9, 6, 0.9),
			Material = SMOOTH,
			Color = Color3.new(1, 1, 1),
		},
	},
}
Skins.TimedDoor = {
	Design = v(8, 12, 1.5),
	Meshes = {
		PP_Prop_TimedDoor_Frame = {
			Id = "rbxassetid://132087797472788",
			Offset = v(0, 0, 0),
			Size = v(8, 12, 1.5),
			Material = NEON,
			Color = Palette.Glow.Kai, -- freezable = Kai's target
		},
		PP_Prop_TimedDoor_Body = {
			Id = "rbxassetid://73092785320641",
			Offset = v(0.016, -0.074, 0),
			Size = v(6.811, 10.819, 1.1),
			Material = Enum.Material.WoodPlanks,
			Color = Color3.fromHex("#B07A3E"),
		},
		PP_Prop_TimedDoor_Bands = {
			Id = "rbxassetid://110777536701275",
			Offset = v(0.44, 0, 0),
			Size = v(6.52, 7.9, 1.848),
			Material = Enum.Material.Metal,
			Color = IRON,
		},
	},
}
Skins.PullLever = {
	Design = v(1, 5, 1),
	Meshes = {
		PP_Prop_PullLever_Base = {
			Id = "rbxassetid://102182536798766",
			Offset = v(0, -2.045, 0),
			Size = v(1.8, 0.91, 1.8),
			Material = Enum.Material.Metal,
			Color = IRON,
		},
		PP_Prop_PullLever_Shaft = {
			Id = "rbxassetid://137471515726725",
			Offset = v(0, -0.2, 0),
			Size = v(0.5, 3.1, 0.5),
			Material = Enum.Material.Metal,
			Color = Color3.fromHex("#9A9AA6"),
		},
		PP_Prop_PullLever_Grip = {
			Id = "rbxassetid://97623882299147",
			Offset = v(0, 0.245, 0),
			Size = v(1.9, 4.91, 1.9),
			Material = NEON,
			Color = Palette.Glow.Miko, -- pullable = Miko's target
		},
	},
}
Skins.Chute = {
	Design = v(8, 16, 8),
	Meshes = {
		PP_Prop_Chute_Pipe = {
			Id = "rbxassetid://103468657655327",
			Offset = v(0, 0.3, 0),
			Size = v(7.877, 15.4, 7.877),
			Material = Enum.Material.Metal,
			Color = Color3.fromHex("#8A8FA0"),
		},
		PP_Prop_Chute_Bands = {
			Id = "rbxassetid://72257420203446",
			Offset = v(0, -0.775, 0),
			Size = v(8.4, 14.25, 8.4),
			Material = Enum.Material.Metal,
			Color = IRON,
		},
		PP_Prop_Chute_Hole = {
			Id = "rbxassetid://99075131701142",
			Offset = v(0, -7.8, 0),
			Size = v(6.8, 0.3, 6.8),
			Material = SMOOTH,
			Color = Color3.fromHex("#16161C"),
		},
	},
}
Skins.HillSign = { -- "BY KAI + MIKO" in chunky pixel letters, readable from the -Z side (art-direction.md §8)
	Design = v(75.55, 8.79, 1.6),
	Meshes = {
		PP_Prop_HillSign = {
			Id = "rbxassetid://114249860822124",
			Offset = v(0, 0, 0),
			Size = v(75.549, 8.79, 1.6),
			Material = SMOOTH,
			Color = Color3.fromHex("#FFF4DC"),
		},
	},
}
-- dropper blocks: the coin-block cube with a Kai-orange edge frame (freezable)
Skins.FallBlock = {
	Design = v(4, 4, 4),
	Meshes = {
		Body = {
			Id = "rbxassetid://120682677424503",
			Offset = v(0, 0, 0),
			Size = v(3.7, 3.7, 3.7),
			Material = SMOOTH,
			Variant = PLASTIC,
			Color = Color3.fromHex("#E8E4D8"),
		},
		Frame = {
			Id = "rbxassetid://139212127358567",
			Offset = v(0, 0, 0),
			Size = v(4, 4, 4),
			Material = NEON,
			Color = Palette.Glow.Kai,
		},
	},
}
-- generated box fan (faces +Z as generated); placed pitched so it blows up, depth squashed into a floor vent
Skins.Fan = gen("rbxassetid://75748223101068", "rbxassetid://128839206690973", v(2.5, 2.5, 2), v(2.49, 2.5, 0.8))

-- Oct 1 obstacles (obstacles.md 2.2), generated with the user's brief "kinda realistic, kinda It Takes Two": real
-- toys at doll scale (chrome spring, rope swing, wooden carriage cannon, rope-lashed raft, cast-iron crank).
-- Offsets put each model's top (or bottom) where the grey-box part's surface is.
Skins.SpringPadSkin = gen( -- top board flush with the pad, the chrome coil hangs below into the pit
	"rbxassetid://125992390845979",
	"rbxassetid://116203241245521",
	v(8, 1, 8),
	v(8, 5, 8),
	v(0, -2, 0)
)
Skins.SwingSkin = gen( -- seat flush with the cradle, ropes up
	"rbxassetid://113564827433679",
	"rbxassetid://93075112416088",
	v(8, 1, 8),
	v(8, 9.4, 8),
	v(0, 4.2, 0)
)
Skins.RaftSkin =
	gen("rbxassetid://121981429443529", "rbxassetid://91569259664439", v(10, 1, 10), v(10, 1.5, 10), v(0, -0.25, 0))
-- the cannon sits on the barrel part (the turntable base stays a wooden disc players stand on); it faces +Z as
-- generated, so it turns 180 to point along the base's LookVector (the launch direction)
Skins.CannonSkin = gen(
	"rbxassetid://87559143022413",
	"rbxassetid://100041832780715",
	v(2.4, 2.4, 6),
	v(4.4, 5.6, 6.6),
	v(0, 1.6, 0),
	180
)
-- the crank wheel stands in the crank part's YZ plane (it spins about X). Its generated texture came out green
-- (decoration green right next to the owner-colored post), so it wears plain cast iron instead.
Skins.CrankSkin = {
	Design = v(0.6, 4, 4),
	Meshes = {
		Body = {
			Id = "rbxassetid://80830869119397",
			Offset = v(0, 0, 0),
			Size = v(4, 4, 1),
			Material = Enum.Material.Metal,
			Color = Color3.fromHex("#55575F"),
			Yaw = 90,
		},
	},
}

-- Oct 2 art pass (8th/9th session): the rest of the grey-box pieces, as real toys (references: retro platformer
-- playsets: glossy molded plastic, bevelled edges, rolled pipe lips, cast-iron and painted-wood parts).
Skins.FirePostSkin = gen( -- riveted cast-iron column with a brass gear hub (the fire bar's pivot)
	"rbxassetid://113537937737960",
	"rbxassetid://110304799388283",
	v(2, 18, 2),
	v(2.5, 18, 2.5)
)
Skins.WarpPipeSkin = gen( -- glossy white molded pipe (white = both players), the dark hole is where you pound in
	"rbxassetid://84704856449664",
	"rbxassetid://129553837547928",
	v(6, 3, 6),
	v(6.2, 3, 6.2)
)
-- ON/OFF blocks: the plastic block kit in each set's color (gold ON, sky OFF); their ON/OFF labels stay on the
-- grey-box faces, and InteractableService ghosts the shell instead of the hidden part
local function switchSkin(body: Color3, rim: Color3): MeshAssets.Skin
	return {
		Design = v(6, 2, 6),
		Meshes = {
			Body = {
				Id = "rbxassetid://131819066639725",
				Offset = v(0, 0, 0),
				Size = v(5.8, 1.9, 5.8),
				Material = SMOOTH,
				Variant = PLASTIC,
				Color = body,
			},
			Frame = {
				Id = "rbxassetid://121713743901075",
				Offset = v(0, 0, 0),
				Size = v(6, 2, 6),
				Material = SMOOTH,
				Variant = PLASTIC,
				Color = rim,
			},
		},
	}
end
Skins.SwitchOn = switchSkin(PP.Gold, Color3.fromHex("#C8961E"))
Skins.SwitchOff = switchSkin(PP.Sky, Color3.fromHex("#3E8FC8"))
-- ? blocks: the coin-block kit in Miko's teal with her glowing rim (pullable); the "?" labels stay on the faces
Skins.BonkSkin = {
	Design = v(4, 4, 4),
	Meshes = {
		Body = {
			Id = "rbxassetid://120682677424503",
			Offset = v(0, 0, 0),
			Size = v(3.7, 3.7, 3.7),
			Material = SMOOTH,
			Variant = PLASTIC,
			Color = Color3.fromHex("#1A9E92"),
		},
		Frame = {
			Id = "rbxassetid://139212127358567",
			Offset = v(0, 0, 0),
			Size = v(4, 4, 4),
			Material = NEON,
			Color = Palette.Glow.Miko,
		},
	},
}
-- the coin step a ? block pops out: a spent brown block with Kai's orange rim (freezable)
Skins.CoinStepSkin = {
	Design = v(6, 2, 6),
	Meshes = {
		Body = {
			Id = "rbxassetid://131819066639725",
			Offset = v(0, 0, 0),
			Size = v(5.8, 1.9, 5.8),
			Material = SMOOTH,
			Variant = PLASTIC,
			Color = Color3.fromHex("#96623A"),
		},
		Frame = {
			Id = "rbxassetid://121713743901075",
			Offset = v(0, 0, 0),
			Size = v(6, 2, 6),
			Material = NEON,
			Color = Palette.Glow.Kai,
		},
	},
}
-- one panel of a white-painted toy fort gate (white = both players); Extras tiles panels along each gate
Skins.GatePanel = gen("rbxassetid://78868320423660", "rbxassetid://115488721112651", v(8, 20, 2), v(8, 20, 2))
-- fire bars: a riveted iron grate around the glowing red core (Extras keeps the core showing and adds flames)
Skins.FireBarSkin =
	gen("rbxassetid://116541654941008", "rbxassetid://86773366652974", v(1.5, 16, 13), v(13, 16, 1.6), nil, 90)
-- pressure plates: a lemon-yellow push button in a steel frame (Extras adds the yellow → green status inlay)
Skins.ButtonPad =
	gen("rbxassetid://90355908254498", "rbxassetid://124486061906722", v(6, 0.6, 6), v(6.2, 0.75, 6.2), v(0, 0.05, 0))
-- checkpoints: a chrome flagpole with a yellow star flag on a stone foot, beside a faint pad
Skins.CheckpointFlag = gen("rbxassetid://102261413887397", "rbxassetid://98929759591630", v(2, 4.78, 3), v(2, 4.78, 3))

local Dressing: { [string]: string } = {
	MoveBlock = "MoveBlock",
	FirePost = "FirePostSkin",
	FireBar = "FireBarSkin",
	WarpPipe = "WarpPipeSkin",
	BonkBlock = "BonkSkin",
	CoinStep = "CoinStepSkin",
	SpringPad = "SpringPadSkin",
	SwingCradle = "SwingSkin",
	Ferry = "RaftSkin",
	CannonBarrel = "CannonSkin",
	Crank = "CrankSkin",
	PixelCrusher = "Crusher",
	GrappleRing = "GrappleRing",
	Crate = "Crate",
	Cliff = "Cliff",
	DirtWall = "DirtWall",
	DoorWall = "DirtWall",
	Conveyor = "Belt",
	GlitchBlob = "GlitchBlobSkin",
	BouncePad = "BouncePadSkin",
	StaticBat = "StaticBatSkin",
	Sign = "Sign",
	TimedDoor = "TimedDoor",
	PullLever = "PullLever",
	FallBlock = "FallBlock", -- dropper blocks are Kai's freeze targets too (dressed as they spawn)
}
-- every walkable grass platform of the Greybox layout (Greybox/init.luau buildPixelPlains)
for _, name in
	{
		"Grass",
		"StarterMeadow",
		"KaiPath",
		"KaiStart",
		"KaiMid",
		"CrusherLane",
		"KaiEnd",
		"KaiReturn",
		"MikoPath",
		"MikoStart",
		"MikoMid",
		"Plaza",
		"CloudBase",
		"SkyGate",
		"BeltEnd",
		"DropperFar",
		"DoorRoom",
		"FactoryExit",
		"ChaseStart",
		"ChaseEnd",
		"BossArena",
		-- sections added Oct 1 (Windmill Hill, Cloud Tower, Coin Press)
		"MillPath",
		"MillFar",
		"MillTop",
		"MillExit",
		"TowerPath",
		"TowerBase",
		"Ledge",
		"TowerTop",
		"TowerExit",
		"PressPath",
		"BlobYard",
		"PressLane",
		"CoinVault",
		"VaultExit",
		-- Spring Yard, Swing Works (Oct 1)
		"YardPath",
		"Yard",
		"SpringPit",
		"FarCliff",
		"YardExit",
		"WorksPath",
		"WorksLedge",
		"WorksFar",
		"CannonIsland",
		"WorksExit",
		-- Switch Towers (Oct 1, 5th session)
		"TowerWalk",
		"TowerYard",
		"SwitchPillar", -- (TowerTop / TowerExit are already listed with Cloud Tower)
	}
do
	Dressing[name] = "GrassBlock"
end

-- Pure decoration placed with the world: { skin, CFrame, scale }. Clouds sit high and to the sides so they frame
-- the route without blocking the camera (art-direction.md §10); coin blocks are scale moments along the way.
-- The 4th field is the Greybox section (by where it sits in that section's own coordinates), so decor follows
-- its section when sections are chained further along.
local function sectionAt(z: number): string
	return if z < 210
		then "StarterMeadow"
		elseif z < 437 then "CloudClimb"
		elseif z < 747 then "CoinFactory"
		else "GlitchChase"
end
local function cloud(x: number, y: number, z: number, yaw: number, scale: number): { any }
	return { "Cloud", CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0), scale, sectionAt(z) }
end
local function coin(x: number, y: number, z: number, yaw: number, scale: number): { any }
	return { "CoinBlock", CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0), scale, sectionAt(z) }
end
local Decor: { { any } } = {
	cloud(-50, 34, -30, 0, 1.3),
	cloud(55, 40, -35, 20, 1.6),
	cloud(-125, 42, 80, -15, 2),
	cloud(128, 46, 60, 10, 1.8),
	cloud(-45, 70, 300, 0, 2.2),
	cloud(48, 84, 365, 25, 2),
	cloud(-50, 104, 450, -10, 2.4),
	cloud(52, 96, 600, 15, 2),
	cloud(-55, 92, 770, 0, 2.4),
	cloud(45, 64, 950, -20, 2.6),
	cloud(-40, 52, 1080, 10, 2.8),
	coin(-12, 9, 6, 15, 1),
	coin(-7.5, 9, 6, 15, 1),
	coin(12, 10, 185, -20, 1.5),
	coin(-16, 76, 505, 10, 1.5),
	coin(16, 78, 700, -15, 1.5),
	coin(0, 44, 1060, 0, 2.5),
	{ "Flowers", CFrame.new(-24, 1.95, -14) * CFrame.Angles(0, math.rad(178), 0), 1.3, "StarterMeadow" },
	{ "Flowers", CFrame.new(22, 1.8, -12) * CFrame.Angles(0, math.rad(142), 0), 1.2, "StarterMeadow" },
	{ "Bush", CFrame.new(-26, 3.2, 8) * CFrame.Angles(0, math.rad(186), 0), 1.6, "StarterMeadow" },
	{ "Bush", CFrame.new(26, 2.8, 6) * CFrame.Angles(0, math.rad(188), 0), 1.4, "StarterMeadow" },
	{ "Flowers", CFrame.new(-86, 1.8, -10) * CFrame.Angles(0, math.rad(108), 0), 1.2, "StarterMeadow" },
	{ "Bush", CFrame.new(-86, 3, 94) * CFrame.Angles(0, math.rad(212), 0), 1.5, "StarterMeadow" },
	{ "Flowers", CFrame.new(86, 1.8, 10) * CFrame.Angles(0, math.rad(252), 0), 1.2, "StarterMeadow" },
	{ "Bush", CFrame.new(86, 3, 82) * CFrame.Angles(0, math.rad(324), 0), 1.5, "StarterMeadow" },
	{ "Flowers", CFrame.new(-16, 1.95, 196) * CFrame.Angles(0, math.rad(84), 0), 1.3, "StarterMeadow" },
	{ "Flowers", CFrame.new(16, 1.8, 158) * CFrame.Angles(0, math.rad(270), 0), 1.2, "StarterMeadow" },
	{ "Bush", CFrame.new(16, 3.2, 206) * CFrame.Angles(0, math.rad(318), 0), 1.6, "StarterMeadow" },
	{ "Bush", CFrame.new(-12, 2.8, 226) * CFrame.Angles(0, math.rad(142), 0), 1.4, "CloudClimb" },
	{ "Flowers", CFrame.new(10, 21.8, 250) * CFrame.Angles(0, math.rad(320), 0), 1.2, "CloudClimb" },
	{ "Bush", CFrame.new(-10, 23, 342) * CFrame.Angles(0, math.rad(272), 0), 1.5, "CloudClimb" },
	{ "Flowers", CFrame.new(12, 63.8, 414) * CFrame.Angles(0, math.rad(138), 0), 1.2, "CloudClimb" },
	-- the chase landing (the throne hall's gate posts stand at x ±13, z 1190; braziers at x ±11, z 1209). Nothing on
	-- the boss tiles: they drop away in phase 2 and decor would be left floating
	{ "Bush", CFrame.new(-12, 23.2, 1201) * CFrame.Angles(0, math.rad(212), 0), 1.6, "GlitchChase" },
	{ "Flowers", CFrame.new(12, 22.1, 1201) * CFrame.Angles(0, math.rad(120), 0), 1.4, "GlitchChase" },
	{ "Tree", CFrame.new(-25, 6.4, -15) * CFrame.Angles(0, math.rad(20), 0), 0.8, "StarterMeadow" },
	{ "Tree", CFrame.new(25, 5.6, -16) * CFrame.Angles(0, math.rad(309), 0), 0.7, "StarterMeadow" },
	{ "Tree", CFrame.new(-87, 6.4, 12) * CFrame.Angles(0, math.rad(321), 0), 0.8, "StarterMeadow" },
	{ "Tree", CFrame.new(87, 6.4, -12) * CFrame.Angles(0, math.rad(39), 0), 0.8, "StarterMeadow" },
	{ "Tree", CFrame.new(-16, 5.6, 205) * CFrame.Angles(0, math.rad(357), 0), 0.7, "StarterMeadow" },
	-- kid details: the "BY KAI + MIKO" hill west of the meadow, facing the plaza; a floor fan under the vent;
	-- the dropper's chute coming out of a cloud
	-- a stepped voxel hill far out west (terraces, so it reads as a hill, not a wall); letters on the low front step
	{ "Cliff", CFrame.new(-230, -40, 110), 4 }, -- front step, top y 0
	{ "Cliff", CFrame.new(-262, -12, 104), 3 }, -- middle step, top y 18
	{ "Cliff", CFrame.new(-282, 12, 112), 1.6 }, -- summit, top y 28
	{ "HillSign", CFrame.lookAt(Vector3.new(-205, 4.4, 110), Vector3.new(0, 4.4, 110)), 1, "StarterMeadow" },
	{ "Tree", CFrame.new(-282, 34.4, 112) * CFrame.Angles(0, math.rad(40), 0), 0.8, "StarterMeadow" },
	{ "Tree", CFrame.new(-248, 24.4, 82) * CFrame.Angles(0, math.rad(200), 0), 0.8, "StarterMeadow" },
	{ "Tree", CFrame.new(-250, 23.6, 128) * CFrame.Angles(0, math.rad(120), 0), 0.7, "StarterMeadow" },
	{ "Bush", CFrame.new(-222, 3.6, 76) * CFrame.Angles(0, math.rad(12), 0), 1.8, "StarterMeadow" },
	{ "Bush", CFrame.new(-218, 3.2, 146) * CFrame.Angles(0, math.rad(190), 0), 1.6, "StarterMeadow" },
	{ "Fan", CFrame.new(0, 43, 379) * CFrame.Angles(math.rad(-90), 0, 0), 3.2, "CloudClimb" },
	{ "Chute", CFrame.new(0, 107.8, 551), 1.1, "CoinFactory" },
	cloud(0, 117, 551, 0, 1.5),
	-- Windmill Hill (its own coordinates: entry at the origin, heading +Z)
	{ "Tree", CFrame.new(-11, 5.6, 100) * CFrame.Angles(0, math.rad(40), 0), 0.7, "WindmillHill" },
	{ "Bush", CFrame.new(11, 3, 96) * CFrame.Angles(0, math.rad(200), 0), 1.4, "WindmillHill" },
	{ "Flowers", CFrame.new(-12, 1.8, 180) * CFrame.Angles(0, math.rad(80), 0), 1.2, "WindmillHill" },
	{ "Tree", CFrame.new(12, 5.6, 186) * CFrame.Angles(0, math.rad(300), 0), 0.7, "WindmillHill" },
	{ "Cloud", CFrame.new(-45, 36, 150), 2, "WindmillHill" },
	{ "Cloud", CFrame.new(50, 44, 60) * CFrame.Angles(0, math.rad(20), 0), 1.8, "WindmillHill" },
	-- Cloud Tower
	{ "Cloud", CFrame.new(-40, 60, 60), 2.2, "CloudTower" },
	{ "Cloud", CFrame.new(45, 80, 150) * CFrame.Angles(0, math.rad(-15), 0), 2.4, "CloudTower" },
	{ "Flowers", CFrame.new(10, 43.8, 200) * CFrame.Angles(0, math.rad(40), 0), 1.2, "CloudTower" },
	-- Coin Press: the vault is stacked with coin blocks
	{ "CoinBlock", CFrame.new(-10, 8, 200) * CFrame.Angles(0, math.rad(10), 0), 1.5, "CoinPress" },
	{ "CoinBlock", CFrame.new(10, 8, 200) * CFrame.Angles(0, math.rad(-10), 0), 1.5, "CoinPress" },
	{ "CoinBlock", CFrame.new(0, 14, 202), 2, "CoinPress" },
	{ "Cloud", CFrame.new(40, 40, 110), 2, "CoinPress" },
}
-- mix the tree / bush variants through the hand-placed decor
for i, item in Decor do
	if item[1] == "Tree" then
		item[1] = TREES[i % #TREES + 1]
	elseif item[1] == "Bush" then
		item[1] = BUSHES[i % #BUSHES + 1]
	elseif item[1] == "Flowers" then
		item[1] = FLOWERS[i % #FLOWERS + 1]
	end
end

-- Spring pads: the coil stands on the pit floor and its board rides the pad, so the skin can't be welded (it
-- floated over the floor at the top of the pump and sank through it at the bottom). It's anchored with its foot on
-- the floor instead; the client SpringController stretches it to the pad's top every frame.
local function rootSprings(world: Instance, params: RaycastParams)
	for _, pad in world:GetDescendants() do
		if pad.Name ~= "SpringPad" or not pad:IsA("BasePart") or pad:GetAttribute("Skinned") ~= "SpringPadSkin" then
			continue
		end
		local body = pad:FindFirstChildWhichIsA("MeshPart")
		local hit = workspace:Raycast(pad.Position, Vector3.new(0, -30, 0), params)
		if not (body and hit) then
			continue
		end
		local weld = body:FindFirstChildWhichIsA("WeldConstraint")
		if weld then
			weld:Destroy()
		end
		body.Anchored = true
		local floor = hit.Position.Y
		local top = pad.Position.Y + pad.Size.Y / 2
		local height = math.max(top - floor, 0.5)
		body:SetAttribute("Floor", floor)
		body:SetAttribute("Rotation", pad.CFrame.Rotation:ToObjectSpace(body.CFrame.Rotation))
		body.Size = Vector3.new(body.Size.X, height, body.Size.Z)
		body.CFrame = CFrame.new(pad.Position.X, floor + height / 2, pad.Position.Z) * body.CFrame.Rotation
		body:AddTag("SpringStretch")
	end
end

-- Swing cradles: the generated seat's two rope-wrapped poles stopped in mid-air. A wooden gantry now spans the
-- chasm (an A-frame on each ledge, a beam high above the launch arc), and a trolley riding the beam carries the
-- seat on a V of ropes. The trolley is welded to the cradle, so freezes and launches are untouched.
local GANTRY_HEIGHT = 32 -- beam above the seat: the release launch peaks ~24 up, so it never reaches the beam
local GANTRY_HALF = 14 -- legs stand at the ledge edges, clear of plates, crates and Kai's drawbridge lane
local POLE_TOPS = { v(-3.4, 8.85, 0), v(3.4, 8.85, 0) } -- measured on the SwingSkin at Design size
local ROPE = Color3.fromHex("#CDB98A")

local function rigGantries(world: Instance, params: RaycastParams, apply: (BasePart, string) -> boolean)
	for _, cradle in world:GetDescendants() do
		if
			cradle.Name ~= "SwingCradle"
			or not cradle:IsA("BasePart")
			or cradle:GetAttribute("Skinned") ~= "SwingSkin"
		then
			continue
		end
		local waypoints = cradle:FindFirstChild("Waypoints")
		local a, b = waypoints and waypoints:FindFirstChild("1"), waypoints and waypoints:FindFirstChild("2")
		if not (a and b and a:IsA("BasePart") and b:IsA("BasePart")) then
			continue
		end
		local holder = Instance.new("Folder")
		holder.Name = "Gantry"
		holder.Parent = cradle.Parent
		local function wood(name: string, size: Vector3, cf: CFrame, collide: boolean)
			local p = Instance.new("Part")
			p.Name = name
			p.Size = size
			p.CFrame = cf
			p.Anchored = true
			p.CanCollide = collide
			p.CanQuery = false -- never in the way of aim rays (Grapple, Pause Beam)
			p.CanTouch = false
			p.Material = Enum.Material.Wood
			p.Color = Color3.fromHex("#7A4E2A")
			p.Parent = holder
			apply(p, "SignPost")
		end
		-- the beam runs from just behind the near end of the path to past the far ledge's edge
		local dir = (b.Position - a.Position).Unit
		local beamY = a.Position.Y + GANTRY_HEIGHT
		local near = a.Position - dir * 20
		local far = b.Position + dir * 27
		local flat = CFrame.lookAt(a.Position, a.Position + dir).Rotation
		local length = (far - near).Magnitude
		local mid = (near + far) / 2
		wood(
			"Beam",
			v(2, length, 2),
			CFrame.new(mid.X, beamY + 1, mid.Z) * flat * CFrame.Angles(math.rad(90), 0, 0),
			false
		)
		for _, foot in { near, far } do
			wood(
				"Crossbar",
				v(1.8, GANTRY_HALF * 2 + 3, 1.8),
				CFrame.new(foot.X, beamY - 0.9, foot.Z) * flat * CFrame.Angles(0, 0, math.rad(90)),
				false
			)
			for _, side in { -1, 1 } do
				local top = CFrame.new(foot.X, beamY, foot.Z) * flat * CFrame.new(side * GANTRY_HALF, 0, 0)
				local hit = workspace:Raycast(top.Position, v(0, -GANTRY_HEIGHT - 20, 0), params)
				if hit then
					local h = top.Position.Y - hit.Position.Y
					wood(
						"Leg",
						v(2, h, 2),
						CFrame.new(top.Position.X, hit.Position.Y + h / 2, top.Position.Z) * flat,
						true
					)
				end
			end
		end
		-- trolley under the beam, welded to the cradle; ropes from the seat's pole tops up to it
		local k = cradle.Size.X / 8
		local trolley = Instance.new("Part")
		trolley.Name = "Trolley"
		trolley.Size = v(1.6, 1.2, 3)
		trolley.CFrame = cradle.CFrame * CFrame.new(0, beamY - cradle.Position.Y - 0.6, 0)
		trolley.Material = Enum.Material.Metal
		trolley.Color = Color3.fromHex("#3E3F46")
		trolley.CanCollide = false
		trolley.CanQuery = false
		trolley.CanTouch = false
		trolley.Massless = true
		trolley.Anchored = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = cradle
		weld.Part1 = trolley
		weld.Parent = trolley
		trolley.Parent = cradle
		local hook = Instance.new("Attachment")
		hook.Position = v(0, -0.6, 0)
		hook.Parent = trolley
		for i, pole in POLE_TOPS do
			local at = Instance.new("Attachment")
			at.Name = "RopeTop" .. i
			at.Position = pole * k
			at.Parent = cradle
			local rope = Instance.new("RopeConstraint")
			rope.Attachment0 = at
			rope.Attachment1 = hook
			rope.Length = (trolley.CFrame * hook.Position - cradle.CFrame * at.Position).Magnitude
			rope.Visible = true
			rope.Thickness = 0.3
			rope.Color = BrickColor.new(ROPE)
			rope.Parent = cradle
		end
	end
end

local function hiddenPart(name: string, size: Vector3, cf: CFrame, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Parent = parent
	return p
end

-- Boss arena tiles (tag Crumble) drop away in the Crusher King fight, so each carries its own chunk of island
-- underneath, welded to it: together they read as one jagged voxel island, and a falling tile takes its dirt along.
local function bossTileChunks(world: Instance)
	local rng = Random.new(1300)
	for _, tile in world:GetDescendants() do
		if not (tile:IsA("BasePart") and tile:HasTag("Crumble")) then
			continue
		end
		local size = tile.Size
		local y = tile.Position.Y - size.Y / 2
		local row = (tile:GetAttribute("Row") or 0) :: number
		local depth = rng:NextNumber(10, 22) + row * 1.5 -- deeper toward the king's rock
		for i, k in { 0.98, rng:NextNumber(0.6, 0.85), rng:NextNumber(0.3, 0.55) } do
			local d = depth * ({ 0.45, 0.35, 0.3 })[i]
			local chunk = hiddenPart(
				"TileChunk",
				Vector3.new(size.X * k, d, size.Z * k),
				CFrame.new(
					tile.Position.X + rng:NextNumber(-1, 1) * size.X * (1 - k) / 2,
					y - d / 2 + 0.2,
					tile.Position.Z + rng:NextNumber(-1, 1) * size.Z * (1 - k) / 2
				),
				tile
			)
			chunk.Transparency = 0
			chunk.Material = SMOOTH
			chunk.MaterialVariant = if i < 3 then "PPDirt" else "PPStone"
			chunk.Color = VOXEL_TINT[chunk.MaterialVariant] or WHITE
			chunk.CastShadow = false
			chunk.Anchored = false
			chunk.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0 = tile
			w.Part1 = chunk
			w.Parent = chunk
			y -= d - 0.2
		end
	end
end

-- Oct 2 art pass: surfaces, gates, plates, checkpoints, fire bars and switch blocks (see the skins above).
local SURFACES: { [string]: { any } } = { -- name → { material, variant?, color }: real surfaces, no mesh needed
	Bridge = { Enum.Material.WoodPlanks, "CastlePlanks", Color3.fromRGB(255, 222, 140) }, -- yellow-stained planks:
	Lift = { Enum.Material.WoodPlanks, "CastlePlanks", Color3.fromRGB(255, 222, 140) }, -- still read as the neutral
	KaiLift = { Enum.Material.WoodPlanks, "CastlePlanks", Color3.fromRGB(255, 222, 140) }, -- lever-driven pieces
	WindmillArm = { Enum.Material.WoodPlanks, "CastlePlanks", Color3.fromRGB(235, 215, 185) },
	CrateIsland = { Enum.Material.WoodPlanks, "CastlePlanks", Color3.fromRGB(225, 190, 150) },
	CrateShelf = { Enum.Material.WoodPlanks, "CastlePlanks", Color3.fromRGB(225, 190, 150) },
	CannonBase = { Enum.Material.WoodPlanks, "CastlePlanks", Color3.fromRGB(225, 190, 150) },
	FactoryRoof = { Enum.Material.CorrodedMetal, nil, Color3.fromRGB(150, 152, 160) },
	GrindRail = { Enum.Material.Metal, nil, Color3.fromRGB(205, 210, 220) },
}

local GATE_PANEL = 10 -- target panel width; each gate gets a whole number of panels
local function dressPieces(world: Instance, apply: (BasePart, string) -> boolean)
	for _, part in world:GetDescendants() do
		if not part:IsA("BasePart") or part:GetAttribute("Skinned") then
			continue
		end
		local surface = SURFACES[part.Name]
		if surface then
			part.Material = surface[1]
			part.MaterialVariant = surface[2] or ""
			part.Color = surface[3]
		elseif part.Name:match("^Gate_") and part.Material == Enum.Material.Neon then
			-- white toy fort panels along the gate, welded so they sink with it
			local wide = part.Size.X >= part.Size.Z
			local width = if wide then part.Size.X else part.Size.Z
			local count = math.max(1, math.round(width / GATE_PANEL))
			local w = width / count
			local turn = if wide then CFrame.identity else CFrame.Angles(0, math.rad(90), 0)
			for i = 1, count do
				local panel = hiddenPart(
					"GatePanel",
					v(w, part.Size.Y, 2),
					part.CFrame * turn * CFrame.new(-width / 2 + (i - 0.5) * w, 0, 0),
					part
				)
				panel.Anchored = false
				panel.Massless = true
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = part
				weld.Part1 = panel
				weld.Parent = panel
				apply(panel, "GatePanel")
			end
			part.Transparency = 1
			part:SetAttribute("ArtHidden", true)
		elseif CollectionService:HasTag(part, "PressurePlate") and apply(part, "ButtonPad") then
			-- the plate's state used to show on the grey-box part (green neon while held): an inlay carries it now
			StateInlay(part)
		elseif CollectionService:HasTag(part, "Checkpoint") then
			-- a yellow star flag on a chrome pole at the pad's edge; the pad itself goes faint
			-- a faint yellow square still read as an obby checkpoint pad (13th session QA): the pad goes invisible and
			-- only a thin painted outline stays on the grass, the flag does the talking
			part.Transparency = 1
			local gui = Instance.new("SurfaceGui")
			gui.Face = Enum.NormalId.Top
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 20
			gui.LightInfluence = 1
			gui.Parent = part
			local line = Instance.new("Frame")
			line.AnchorPoint = Vector2.new(0.5, 0.5)
			line.Position = UDim2.fromScale(0.5, 0.5)
			line.Size = UDim2.fromScale(0.9, 0.9)
			line.BackgroundTransparency = 1
			line.Parent = gui
			Instance.new("UICorner", line).CornerRadius = UDim.new(0.08, 0)
			local stroke = Instance.new("UIStroke")
			stroke.Color = Palette.Neutral
			stroke.Thickness = 5
			stroke.Transparency = 0.25
			stroke.Parent = line
			local design = Skins.CheckpointFlag.Design * 1.8
			local flag = hiddenPart(
				"CheckpointFlag",
				design,
				part.CFrame * CFrame.new(part.Size.X / 2 - 1.2, -part.Size.Y / 2 + design.Y / 2, part.Size.Z / 2 - 1.5),
				part.Parent or world
			)
			if not apply(flag, "CheckpointFlag") then
				flag:Destroy()
			end
		end
	end
	-- fire bars (grate skinned by Dressing): the red-hot core glows through the bars, flames lick off it
	for _, bar in world:GetDescendants() do
		if bar.Name == "FireBar" and bar:IsA("BasePart") and bar:GetAttribute("Skinned") then
			bar.Transparency = 0.8 -- a faint red-hot glow: the grate and flames carry the look
			CombatFx.Emit(bar, "Flame", 1.2, 40)
		end
	end
	-- ON/OFF blocks: the shells start in the state the block is already in (the switch runs before the art loads)
	for _, block in CollectionService:GetTagged("SwitchBlock") do
		if block:IsDescendantOf(world) and block:GetAttribute("Skinned") then
			for _, shell in block:GetChildren() do
				if shell:IsA("MeshPart") then
					shell.Transparency = if block:GetAttribute("SwitchSolid") == false then Tuning.SwitchGhost else 0
				end
			end
		end
	end
end

-- Environment fill (Oct 2): the route floated over an empty blue void. Layered sky islands (a grass block on a dirt
-- cliff, sometimes a tree) and clouds drift below and beside it, so there's depth under every jump (It Takes Two's
-- layered foreground/background). Nothing collides, and none sit where a falling player could see a "landing".
local ISLANDS = 48
local HAZE = Color3.fromRGB(232, 228, 210) -- warm pale: sky-blue and grey-blue hazes turned the grass teal/mint (Miko's color)
local function skyIslands(world: Instance, apply: (BasePart, string) -> boolean)
	local floors = {}
	for _, d in world:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Skin") == "GrassBlock" and d.Size.X * d.Size.Z >= 600 then
			table.insert(floors, d)
		end
	end
	if #floors == 0 then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "SkyIslands"
	folder.Parent = world
	local rng = Random.new(1985)
	local function piece(skin: string, size: Vector3, cf: CFrame): Part?
		local p = hiddenPart("Island", size, cf, folder)
		if apply(p, skin) then
			return p
		end
		p:Destroy()
		return nil
	end
	for i = 1, ISLANDS do
		local f = floors[rng:NextInteger(1, #floors)]
		local side = if i % 2 == 0 then -1 else 1
		-- two bands: near islands below the route, and big far ones around its height (the skyline)
		local far = i % 3 == 0
		local w = if far then rng:NextNumber(2.6, 4.2) else rng:NextNumber(1.2, 2.6)
		local base = f.Position
			+ Vector3.new(
				side * (if far then rng:NextNumber(280, 480) else rng:NextNumber(130, 260)),
				if far then rng:NextNumber(-70, 30) else -rng:NextNumber(70, 160),
				rng:NextNumber(-60, 60)
			)
		local yaw = CFrame.Angles(0, math.rad(rng:NextInteger(0, 3) * 90), 0)
		local top = piece("GrassBlock", v(20 * w, 6, 20 * w), CFrame.new(base) * yaw)
		if not top then
			continue
		end
		-- the dirt underside narrows downward: one or two cliff chunks
		local depth = rng:NextNumber(14, 30)
		piece("Cliff", v(18 * w, depth, 18 * w), CFrame.new(base - Vector3.new(0, 3 + depth / 2, 0)) * yaw)
		if rng:NextNumber() < 0.5 then
			local d2 = depth * 0.6
			piece("Cliff", v(11 * w, d2, 11 * w), CFrame.new(base - Vector3.new(0, 3 + depth + d2 / 2, 0)) * yaw)
		end
		if rng:NextNumber() < 0.6 then
			local s = rng:NextNumber(0.8, 1.3)
			piece(
				TREES[rng:NextInteger(1, #TREES)],
				v(12, 16, 12) * s,
				CFrame.new(base + Vector3.new(rng:NextNumber(-4, 4) * w, 3 + 8 * s, rng:NextNumber(-4, 4) * w))
					* CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), 0)
			)
		end
		if rng:NextNumber() < 0.45 then
			local s = rng:NextNumber(1.6, 3)
			piece(
				"Cloud",
				v(22, 8, 8) * s,
				CFrame.new(
					base + Vector3.new(side * rng:NextNumber(10, 40), -rng:NextNumber(10, 35), rng:NextNumber(-30, 30))
				) * CFrame.Angles(0, math.rad(rng:NextNumber(-30, 30)), 0)
			)
		end
	end
	-- aerial haze: scenery leans toward the sky color so it never competes with the route (art-direction pillar 3)
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then
			d.CastShadow = false -- far scenery: no shadow cost
			if d:IsA("MeshPart") then
				d.Color = d.Color:Lerp(HAZE, 0.15) -- lighter since the Blender panorama carries the depth
			end
		end
	end
end

-- The route's grass slabs were thin plates hanging in the sky. Now each is the top of a floating island like the
-- ones in the Blender panorama around the level: a stepped dirt-and-stone underside narrowing downward, with roots
-- and grass vines hanging off it. Undersides never collide, and one is skipped (or kept shallow) wherever a moving
-- piece travels below its slab (lifts, ferries, cradles, falling blocks' lanes).
local ROOT = Color3.fromHex("#6B4423")
local VINE = Color3.fromHex("#3FA34D")

local function islandUndersides(world: Instance, params: RaycastParams, apply: (BasePart, string) -> boolean)
	-- where moving pieces sweep: current pose, every waypoint, and the open pose of lifts and bridges
	local sweeps: { { min: Vector3, max: Vector3 } } = {}
	local function addBox(cf: CFrame, size: Vector3)
		local half = size / 2 + Vector3.new(2, 2, 2)
		table.insert(sweeps, { min = cf.Position - half, max = cf.Position + half })
	end
	for _, d in world:GetDescendants() do
		if not d:IsA("BasePart") then
			continue
		end
		if d:HasTag("Mover") or d:HasTag("DuoGate") or d:HasTag("Pullable") or d.Name == "Dropper" then
			local off = d:GetAttribute("OpenOffset")
			local lo, hi = d.Position, d.Position + (if typeof(off) == "Vector3" then off else Vector3.zero)
			local mid = (lo + hi) / 2
			addBox(CFrame.new(mid), d.Size + Vector3.new(0, math.abs(hi.Y - lo.Y), 0))
			local wps = d:FindFirstChild("Waypoints")
			for _, w in (wps and wps:GetChildren() or {}) do
				if w:IsA("BasePart") then
					addBox(w.CFrame, d.Size)
				end
			end
			if d.Name == "Dropper" then -- blocks fall straight down from it
				addBox(CFrame.new(d.Position - Vector3.new(0, 60, 0)), Vector3.new(d.Size.X, 120, d.Size.Z))
			end
		end
	end
	local function clear(cf: CFrame, size: Vector3, own: BasePart): boolean
		local half = size / 2
		local lo, hi = cf.Position - half, cf.Position + half
		for _, s in sweeps do
			if
				lo.X < s.max.X
				and hi.X > s.min.X
				and lo.Y < s.max.Y
				and hi.Y > s.min.Y
				and lo.Z < s.max.Z
				and hi.Z > s.min.Z
			then
				return false
			end
		end
		-- and nothing solid of the level in the way (a lower path running under this slab)
		local overlap = OverlapParams.new()
		overlap.FilterType = Enum.RaycastFilterType.Include
		overlap.FilterDescendantsInstances = { world }
		overlap.RespectCanCollide = true
		for _, hit in workspace:GetPartBoundsInBox(cf, size, overlap) do
			if hit ~= own then
				return false
			end
		end
		return true
	end
	-- gameplay pieces keep a clear ring around them (plates, levers, checkpoints, gates, rings, pipes...)
	local keepout: { Vector3 } = {}
	for _, d in world:GetDescendants() do
		if
			d:IsA("BasePart")
			and (
				d:HasTag("PressurePlate")
				or d:HasTag("Checkpoint")
				or d:HasTag("DuoPound")
				or d:HasTag("HeavyLever")
				or d:HasTag("Pullable")
				or d:HasTag("GrappleRing")
				or d:HasTag("Station")
				or d:HasTag("DuoGate")
				or d:HasTag("Mover")
				or d:HasTag("Hazard")
				or d:HasTag("JumpVent")
				or d:HasTag("VentButton")
				or d:HasTag("WorldExit")
				or d.Name == "Sign"
				or d.Name == "WarpPipe"
			)
		then
			table.insert(keepout, d.Position)
		end
	end
	local rng = Random.new(2026)
	local folder = Instance.new("Folder")
	folder.Name = "IslandUndersides"
	folder.Parent = world
	local function block(size: Vector3, cf: CFrame, color: Color3)
		local p = hiddenPart("Underside", size, cf, folder)
		p.Transparency = 0
		p.Material = SMOOTH
		-- voxel dirt and stone like the ground above (the old flat colors only pick which one)
		p.MaterialVariant = if color == PP.Dirt or color == Color3.fromHex("#8F5E33") then "PPDirt" else "PPStone"
		p.Color = VOXEL_TINT[p.MaterialVariant] or WHITE
		p.CastShadow = false
		return p
	end
	for _, floor in world:GetDescendants() do
		if
			not floor:IsA("BasePart")
			or (floor:GetAttribute("Skin") ~= "GrassBlock" and floor:GetAttribute("Skin") ~= "Cliff")
			or floor:HasTag("Mover")
			or floor:HasTag("DuoGate")
			or floor:HasTag("Crumble") -- boss floor tiles drop away
			or floor:GetAttribute("Bare") -- no underside/foliage (the Crusher King's rock: the fight happens on it)
			or floor.Parent == folder
			or floor:FindFirstAncestor("SkyIslands")
		then
			continue
		end
		local size = floor.Size
		local w = math.min(size.X, size.Z)
		if w < 8 then
			continue
		end
		local bottom = floor.Position.Y - size.Y / 2
		-- resting on something already (a slab on a cliff or on the ground), or a cliff (its skin has its own rock
		-- sides): nothing hangs below it, but its top edges still get foliage (13th session: cliff tops were bare)
		local rests = floor:GetAttribute("Skin") == "Cliff"
			or workspace:Raycast(
					Vector3.new(floor.Position.X, bottom - 0.05, floor.Position.Z),
					Vector3.new(0, -3, 0),
					params
				)
				~= nil
		local rot = floor.CFrame.Rotation
		local depth = math.clamp(w * 0.55, 6, 20)
		local layers = {
			{ k = 0.86, d = depth * 0.45, color = PP.Dirt },
			{ k = 0.62, d = depth * 0.35, color = Color3.fromHex("#8F5E33") },
			{ k = 0.36, d = depth * 0.3, color = Color3.fromHex("#8C8C96") },
		}
		local y = bottom
		local placed: { { size: Vector3, cf: CFrame } } = {}
		for _, layer in (if rests then {} else layers) do
			local s = Vector3.new(size.X * layer.k, layer.d, size.Z * layer.k)
			local cf = CFrame.new(floor.Position.X, y - layer.d / 2 + 0.2, floor.Position.Z) * rot
			if not clear(cf, s, floor) then
				break
			end
			table.insert(placed, { size = s, cf = cf })
			y -= layer.d - 0.2
		end
		for i, pl in placed do
			block(pl.size, pl.cf, layers[i].color)
		end
		-- flowers and bushes along the slab's free edges (never near a gameplay piece, never where the path goes on)
		local topY = floor.Position.Y + size.Y / 2
		local function freeSpot(at: Vector3): boolean
			for _, k in keepout do
				if (k - at).Magnitude < 9 then -- lever posts and plates stand a little off their grey-box part
					return false
				end
			end
			return true
		end
		for _, side in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
			local alongX = side[1] == 0
			local len = if alongX then size.X else size.Z
			local spacing = 4.5
			for t = -len / 2 + 2.5, len / 2 - 2.5, spacing do
				if rng:NextNumber() > 0.5 then
					continue
				end
				local lx = if alongX then t else side[1] * (size.X / 2 - 1.6)
				local lz = if alongX then side[2] * (size.Z / 2 - 1.6) else t
				local at = floor.CFrame * Vector3.new(lx, size.Y / 2, lz)
				local out = floor.CFrame * Vector3.new(lx + side[1] * 2.4, size.Y / 2, lz + side[2] * 2.4)
				-- the edge continues into more floor (a joined path): leave it open
				if workspace:Raycast(out + Vector3.new(0, 3, 0), Vector3.new(0, -6, 0), params) or not freeSpot(at) then
					continue
				end
				-- edge dressing mix: bushes, flower patches, grass tufts, mossy rocks
				local roll = rng:NextNumber()
				local skin = if roll < 0.3
					then BUSHES[rng:NextInteger(1, #BUSHES)]
					elseif roll < 0.62 then FLOWERS[rng:NextInteger(1, #FLOWERS)]
					elseif roll < 0.85 then "Tuft"
					elseif roll < 0.95 then "Rock"
					else "Rock2"
				local design = Skins[skin].Design
				local scale = if skin == "Tuft" then rng:NextNumber(1, 1.6) else rng:NextNumber(0.85, 1.3)
				local sz = design * scale
				local p = hiddenPart(
					"Foliage",
					sz,
					CFrame.new(at.X, topY + sz.Y / 2 - 0.1, at.Z) * CFrame.Angles(0, rng:NextNumber(0, 2 * math.pi), 0),
					folder
				)
				if not apply(p, skin) then
					p:Destroy()
				end
			end
		end
		-- roots and grass vines hanging off the island's edges
		if #placed > 0 then
			local top = placed[1]
			local count = math.floor(math.clamp((size.X + size.Z) / 8, 2, 10))
			for _ = 1, count do
				local along = rng:NextNumber(-0.45, 0.45)
				local edge = rng:NextInteger(1, 4)
				local hx, hz = top.size.X / 2 - 0.4, top.size.Z / 2 - 0.4
				local lx, lz
				if edge == 1 then
					lx, lz = hx, along * top.size.Z
				elseif edge == 2 then
					lx, lz = -hx, along * top.size.Z
				elseif edge == 3 then
					lx, lz = along * top.size.X, hz
				else
					lx, lz = along * top.size.X, -hz
				end
				local len = rng:NextNumber(1.5, 4.5)
				local start = top.cf * CFrame.new(lx, -top.size.Y / 2, lz)
				local cf = start * CFrame.new(0, -len / 2 + 0.3, 0)
				if clear(cf, Vector3.new(1.4, len, 1.4), floor) then
					local vine = rng:NextNumber() < 0.55
					block(Vector3.new(1.2, len, 1.2), cf, if vine then VINE else ROOT)
					if vine and len > 2.5 then -- a leafy tip
						block(Vector3.new(1.8, 1.2, 1.8), cf * CFrame.new(0, -len / 2, 0), Color3.fromHex("#58B848"))
					end
				end
			end
		end
	end
end

-- Lever bridges and lifts wait below the path until their group is on, and hung in mid-air there. Now they're
-- hoisted: a bridge hangs on ropes from posts on the ledges at both ends, a lift from a crane jib on the ledge it
-- rises to. The ropes are Beams between attachments, so they stay taut while the piece rises and lowers.
local HOIST_POST = 7 -- bridge posts stand this tall above the ledge
local HOIST_ARM = 2.8 -- their arms reach this far out over the gap
local JIB_CLEAR = 12 -- a lift's jib runs this high above its raised top (riders and jumps pass under it)

local function rope(a: Attachment, b: Attachment)
	local beam = Instance.new("Beam")
	beam.Attachment0 = a
	beam.Attachment1 = b
	beam.Texture = ToolFx.Textures.Rope
	beam.TextureMode = Enum.TextureMode.Static
	beam.TextureLength = 2
	beam.Width0 = 0.3
	beam.Width1 = 0.3
	beam.FaceCamera = true
	beam.LightInfluence = 1
	beam.Color = ColorSequence.new(Color3.fromHex("#CDB98A"))
	beam.Segments = 1
	beam.Parent = b
end

local function attach(part: BasePart, at: Vector3): Attachment
	local a = Instance.new("Attachment")
	a.Position = at
	a.Parent = part
	return a
end

local function rigHoists(world: Instance, params: RaycastParams, apply: (BasePart, string) -> boolean)
	-- the ledge top near height `y` under point `p` (within 4 studs), or nil
	local function ledgeAt(p: Vector3, y: number): number?
		local hit = workspace:Raycast(Vector3.new(p.X, y + 4, p.Z), Vector3.new(0, -8, 0), params)
		return hit and not hit.Instance:HasTag("DuoGate") and hit.Position.Y or nil
	end
	local function wood(name: string, size: Vector3, cf: CFrame, parent: Instance): Part
		local p = hiddenPart(name, size, cf, parent)
		apply(p, "SignPost")
		return p
	end
	for _, piece in world:GetDescendants() do
		local off = piece:GetAttribute("OpenOffset")
		if
			not piece:IsA("BasePart")
			or not piece:HasTag("DuoGate")
			or typeof(off) ~= "Vector3"
			or off.Y <= 0
			or not piece:GetAttribute("Solid")
		then
			continue
		end
		local half = piece.Size / 2
		local below =
			workspace:Raycast(piece.Position - Vector3.new(0, half.Y + 0.05, 0), Vector3.new(0, -2, 0), params)
		if below then
			continue -- rests on the floor while lowered
		end
		local openTop = piece.Position.Y + half.Y + off.Y
		local holder = Instance.new("Folder")
		holder.Name = "Hoist"
		holder.Parent = piece.Parent
		local cf = piece.CFrame
		if math.max(piece.Size.X, piece.Size.Z) > 20 then
			-- a bridge: posts on the ledge beyond each end, ropes to the deck's corners
			local long = if piece.Size.Z >= piece.Size.X then cf.LookVector else cf.RightVector
			local across = if piece.Size.Z >= piece.Size.X then cf.RightVector else cf.LookVector
			local len = math.max(piece.Size.X, piece.Size.Z) / 2
			local wide = math.min(piece.Size.X, piece.Size.Z) / 2
			for _, dir in { -1, 1 } do
				for _, side in { -1, 1 } do
					local foot = piece.Position + long * dir * (len + 1.2) + across * side * (wide + 0.8)
					local ground = ledgeAt(foot, openTop)
					if not ground then
						continue
					end
					wood(
						"HoistPost",
						v(0.9, HOIST_POST, 0.9),
						CFrame.new(foot.X, ground + HOIST_POST / 2, foot.Z),
						holder
					)
					-- a davit arm reaches out over the gap so the rope hangs clear of the ledge's face
					local top = Vector3.new(foot.X, ground + HOIST_POST - 0.4, foot.Z)
					local tip = top - long * dir * HOIST_ARM
					local arm = wood(
						"HoistArm",
						v(0.7, HOIST_ARM + 0.5, 0.7),
						CFrame.lookAt((top + tip) / 2, tip) * CFrame.Angles(math.rad(90), 0, 0),
						holder
					)
					local corner = piece.CFrame:PointToObjectSpace(
						piece.Position + long * dir * (len - 0.4) + across * side * (wide - 0.4)
					)
					rope(
						attach(arm, arm.CFrame:PointToObjectSpace(tip - Vector3.new(0, 0.35, 0))),
						attach(piece, Vector3.new(corner.X, half.Y, corner.Z))
					)
				end
			end
		else
			-- a lift: find the ledge it rises to, stand a crane post there and swing a jib out over the lift
			local best: { dir: Vector3, d: number, ground: number }? = nil
			for _, dir in { cf.LookVector, -cf.LookVector, cf.RightVector, -cf.RightVector } do
				local reach = math.abs(dir:Dot(cf.LookVector)) * half.Z + math.abs(dir:Dot(cf.RightVector)) * half.X
				for d = reach + 1, reach + 14 do
					local ground = ledgeAt(piece.Position + dir * d, openTop)
					if ground and math.abs(ground - openTop) < 3 then
						if not best or d < best.d then
							best = { dir = dir, d = d + 1.5, ground = ground }
						end
						break
					end
				end
			end
			if not best then
				holder:Destroy()
				continue
			end
			local jibY = openTop + JIB_CLEAR
			local base = piece.Position + best.dir * best.d
			local h = jibY + 1 - best.ground
			wood("CranePost", v(1.4, h, 1.4), CFrame.new(base.X, best.ground + h / 2, base.Z), holder)
			local tip = Vector3.new(piece.Position.X, jibY, piece.Position.Z)
			local mid = (Vector3.new(base.X, jibY, base.Z) + tip) / 2
			local jibLen = best.d + 1
			wood("CraneJib", v(1.2, jibLen, 1.2), CFrame.lookAt(mid, tip) * CFrame.Angles(math.rad(90), 0, 0), holder)
			local block = hiddenPart("Pulley", v(1, 1.2, 1), CFrame.new(tip - Vector3.new(0, 1.2, 0)), holder)
			block.Transparency = 0
			block.Material = Enum.Material.Metal
			block.Color = IRON
			local hook = attach(block, v(0, -0.6, 0))
			for _, c in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
				rope(hook, attach(piece, v(c[1] * (half.X - 0.4), half.Y, c[2] * (half.Z - 0.4))))
			end
		end
	end
end

-- After dressing: wooden posts under every sign, from the ground up to just above the board (posts stand at the
-- board's ends so they never cover the lettering).
-- The Crusher King's throne hall (user, Oct 4: "the grandest place in Pixel Plains"; picked "Throne hall island" on
-- Oct 10). The fight floor and the king stay exactly as tested: the 6×7 tiles + his rock become the raised dais of a
-- ruined voxel throne hall. Around it, 34 studs down (below the void line, so nothing there is a landing or a safe
-- spot): a U of island terraces carrying colonnades with royal banners, a back wall with a rose window over his
-- head, two corner towers, rubble and crowds of trees. On the chase landing: an entrance arch, a velvet runner and
-- two braziers. Sun shafts stream between the pillars onto the floor; they burn gold once he's beaten. Section-local
-- numbers (Greybox buildPixelPlains, BOSS ARENA) are measured from the BossTrigger, so section shifts carry it.
local HALL_DROP = 34 -- terrace tops under the fight floor (void respawn is 25 under the last ground)
local SHAFT = Color3.fromRGB(255, 236, 196)
local SHAFT_WON = Color3.fromRGB(255, 214, 120)

local function bossHall(world: Instance, apply: (BasePart, string) -> boolean)
	local trigger = world:FindFirstChild("BossTrigger", true)
	if not (trigger and trigger:IsA("BasePart") and Skins.BA_Pillar) then
		return
	end
	-- section-local (x, y above the floor top, z) → world
	local origin = trigger.Position - v(0, 15, 1255)
	local function at(x: number, y: number, z: number): Vector3
		return origin + v(x, y, z)
	end
	local folder = Instance.new("Folder")
	folder.Name = "ThroneHall"
	folder.Parent = world
	local L = -HALL_DROP
	-- a piece standing on y (its base), facing `face` (its front, -Z, looks that way)
	local function piece(skin: string, base: Vector3, face: Vector3?, collide: boolean?): Part?
		local size = Skins[skin] and Skins[skin].Design
		if not size then
			return nil
		end
		local pos = base + v(0, size.Y / 2, 0)
		local cf = if face then CFrame.lookAt(pos, pos + face) else CFrame.new(pos)
		local p = hiddenPart(skin, size, cf, folder)
		p.CanCollide = collide == true
		if not apply(p, skin) then
			p:Destroy()
			return nil
		end
		return p
	end
	-- terraces: voxel ground islands (islandUndersides gives them dirt/stone tiers + edge foliage later)
	for _, t in
		{
			{ v(40, 6, 152), at(-64, L - 3, 1272) },
			{ v(40, 6, 152), at(64, L - 3, 1272) },
			{ v(168, 6, 44), at(0, L - 3, 1370) },
		}
	do
		local p = hiddenPart("HallTerrace", t[1], CFrame.new(t[2]), folder)
		p.Transparency = 0
		p:SetAttribute("Skin", "GrassBlock")
		apply(p, "GrassBlock")
	end
	-- colonnades: six pillars a side, ruined in places; banners on the whole ones, lintels across some pairs
	local ROWS = { 1218, 1240, 1262, 1284, 1306, 1328 }
	local KINDS = {
		[-1] = { "BA_Pillar", "BA_Pillar", "BA_PillarBroken", "BA_Pillar", "BA_Pillar", "BA_PillarStump" },
		[1] = { "BA_Pillar", "BA_PillarStump", "BA_Pillar", "BA_Pillar", "BA_PillarBroken", "BA_Pillar" },
	}
	local LINTELS = { [-1] = { 1, 4 }, [1] = { 3 } } -- the first pillar of each spanned pair
	local rng = Random.new(1326)
	for _, side in { -1, 1 } do
		local inward = v(-side, 0, 0)
		for i, z in ROWS do
			local kind = KINDS[side][i]
			local base = at(side * 52, L, z)
			-- quarter turns so the ivy and chips don't repeat down the row
			piece(kind, base, CFrame.Angles(0, math.rad(rng:NextInteger(0, 3) * 90), 0).LookVector)
			if kind == "BA_Pillar" then
				local banner = if (i + side) % 4 == 0 then "BA_BannerTorn" else "BA_Banner"
				piece(banner, base + inward * 4.75 + v(0, 75 - 11 - 32, 0), inward)
			elseif kind ~= "BA_PillarStump" then
				-- the snapped-off drum lies on the terrace beside it
				piece(
					"BA_Rubble" .. rng:NextInteger(1, 2),
					base - inward * 12 + v(0, 0, rng:NextNumber(-6, 6)),
					CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0).LookVector
				)
			end
		end
		for _, i in LINTELS[side] do
			local z = (ROWS[i] + ROWS[i + 1]) / 2
			piece("BA_Lintel", at(side * 52, L + 75, z), v(side, 0, 0)) -- long axis along the colonnade
		end
	end
	-- the back wall (front face at z 1352, behind the throne) with its rose window over his crown, and the towers
	piece("BA_BackWall", at(0, L, 1350))
	piece("BA_Tower", at(56, L, 1360))
	piece("BA_TowerBroken", at(-56, L, 1360)) -- the wall's collapsed end (Blender +x = Roblox -x)
	piece("BA_Rubble1", at(-36, L, 1372), v(1, 0, 0.3))
	piece("BA_Rubble2", at(72, L, 1300), v(-0.4, 0, 1))
	-- crowds: trees down the outer half of the side terraces and round the towers, flowers and bushes between pillars
	for _, side in { -1, 1 } do
		for z = 1202, 1350, 10 do
			local s = rng:NextNumber(1.4, 2.6)
			local name = TREES[rng:NextInteger(1, #TREES)]
			local design = Skins[name].Design * s
			local p = hiddenPart(
				name,
				design,
				CFrame.new(at(side * rng:NextNumber(68, 78), L + design.Y / 2, z + rng:NextNumber(-3, 3)))
					* CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0),
				folder
			)
			if not apply(p, name) then
				p:Destroy()
			end
		end
		for i = 1, #ROWS - 1 do
			for _, skin in { FLOWERS[rng:NextInteger(1, 3)], BUSHES[rng:NextInteger(1, 2)] } do
				local s = rng:NextNumber(1.2, 1.8)
				local design = Skins[skin].Design * s
				local p = hiddenPart(
					skin,
					design,
					CFrame.new(
						at(
							side * rng:NextNumber(47, 60),
							L + design.Y / 2,
							(ROWS[i] + ROWS[i + 1]) / 2 + rng:NextNumber(-5, 5)
						)
					) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0),
					folder
				)
				if not apply(p, skin) then
					p:Destroy()
				end
			end
		end
	end
	for _, x in { -78, -70, 70, 78 } do
		local s = rng:NextNumber(2, 2.8)
		local name = TREES[rng:NextInteger(1, #TREES)]
		local design = Skins[name].Design * s
		local p = hiddenPart(name, design, CFrame.new(at(x, L + design.Y / 2, 1380 + rng:NextNumber(-4, 4))), folder)
		if not apply(p, name) then
			p:Destroy()
		end
	end
	-- the entrance on the chase landing: an arch (its posts collide), the runner up to the first row, two braziers
	if piece("BA_Gate", at(0, 0, 1190)) then
		for _, side in { -1, 1 } do
			local post = hiddenPart("GatePost", v(4, 32, 4), CFrame.new(at(side * 13, 16, 1190)), folder)
			post.CanCollide = true
		end
	end
	piece("BA_Carpet", at(0, 0.02, 1203))
	for _, side in { -1, 1 } do
		local brazier = piece("BA_Brazier", at(side * 11, 0, 1209), nil, true)
		if brazier then
			local flame = hiddenPart("BrazierFlame", v(3, 1, 3), CFrame.new(at(side * 11, 6, 1209)), brazier)
			CombatFx.Emit(flame, "Flame", 0.9, 30)
			local light = Instance.new("PointLight") -- small warm pool (memory subtle-lighting)
			light.Color = Color3.fromRGB(255, 170, 90)
			light.Range = 12
			light.Brightness = 0.8
			light.Parent = flame
		end
	end
	-- sun shafts: light from the real sun streams through the gaps of the sunny colonnade (under the lintels) onto
	-- the floor, like light through a ruined hall (a shaft through the rose window lit his face like a glare). Faint
	-- in the fight so slam marks stay readable, gold once he's beaten.
	local sun = v(-0.672, 0.672, 0.313) -- Lighting:GetSunDirection() in Pixel Plains (ClockTime 15, measured Oct 10)
	local beams = {}
	local shafts = hiddenPart("SunShafts", v(1, 1, 1), CFrame.new(at(0, 0, 1255)), folder)
	for i, z in { 1212, 1234, 1256, 1278 } do
		-- the floor spot whose ray to the sun passes a gap of the colonnade on the sun's side
		local foot = at(-sun.X / math.abs(sun.X) * 15, 0, z)
		local a0 = Instance.new("Attachment")
		a0.Position = shafts.CFrame:PointToObjectSpace(foot + sun * 110)
		a0.Parent = shafts
		local a1 = Instance.new("Attachment")
		a1.Position = shafts.CFrame:PointToObjectSpace(foot)
		a1.Parent = shafts
		local beam = Instance.new("Beam")
		beam.Name = "SunShaft" .. i
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Texture = "rbxassetid://131326791885754" -- textures/godray.png
		beam.TextureMode = Enum.TextureMode.Stretch
		beam.Width0 = 10
		beam.Width1 = 13
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.LightInfluence = 0
		beam.Brightness = 2
		beam.Segments = 1
		beam.Parent = shafts
		table.insert(beams, beam)
		if i == 3 then
			-- dust hanging in the light (It Takes Two's shed): slow warm motes along one shaft
			local mid = foot + sun * 40
			local dust = hiddenPart("ShaftDust", v(10, 10, 70), CFrame.lookAt(mid, foot), folder)
			local motes = Instance.new("ParticleEmitter")
			motes.Texture = "rbxassetid://107545947174130" -- Ambient.luau MOTE
			motes.Shape = Enum.ParticleEmitterShape.Box
			motes.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
			motes.Rate = 14
			motes.Lifetime = NumberRange.new(6, 10)
			motes.Speed = NumberRange.new(0.1, 0.4)
			motes.SpreadAngle = Vector2.new(180, 180)
			motes.Acceleration = v(0, -0.05, 0)
			motes.Size = NumberSequence.new(0.35)
			motes.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.3, 0.35),
				NumberSequenceKeypoint.new(0.7, 0.35),
				NumberSequenceKeypoint.new(1, 1),
			})
			motes.Color = ColorSequence.new(SHAFT)
			motes.LightEmission = 0.6
			motes.LightInfluence = 0.3
			motes.Parent = dust
		end
	end
	local function light()
		local won = trigger:GetAttribute("Played") == true
		local fight = workspace:GetAttribute("BossFight") == true
		local t = if won then 0.3 elseif fight then 0.75 else 0.55
		for _, beam in beams do
			beam.Transparency = NumberSequence.new(t)
			beam.Color = ColorSequence.new(if won then SHAFT_WON else SHAFT)
		end
	end
	light()
	trigger:GetAttributeChangedSignal("Played"):Connect(light)
	workspace:GetAttributeChangedSignal("BossFight"):Connect(light)
	for _, d in folder:GetDescendants() do
		if d:IsA("BasePart") then
			d.CanQuery = false -- never in the way of aim rays (Grapple, Pause Beam, Pull)
			d.CanTouch = false
		end
	end
end

local function Extras(world: Instance, apply: (BasePart, string) -> boolean)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { world }
	params.RespectCanCollide = true
	rootSprings(world, params)
	rigGantries(world, params, apply)
	rigHoists(world, params, apply)
	dressPieces(world, apply)
	skyIslands(world, apply)
	-- a girder hanging over a chasm (the Spring Yard ferry crusher) stood on nothing: two steel beams run from it to
	-- the ground on both sides, each ending in a leg (memory grounded-props). Roofs already resting on walls are left.
	local STEEL = Color3.fromRGB(150, 152, 160)
	local function steel(name: string, size: Vector3, cf: CFrame, parent: Instance)
		local p = hiddenPart(name, size, cf, parent)
		p.Transparency = 0
		p.Material = Enum.Material.CorrodedMetal
		p.Color = STEEL
	end
	for _, roof in world:GetDescendants() do
		if roof.Name ~= "FactoryRoof" or not roof:IsA("BasePart") then
			continue
		end
		-- supported if anything solid sits under a corner (walls along a lane); its own crusher doesn't count
		local supported = false
		for _, c in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
			local at = roof.CFrame * Vector3.new(c[1] * (roof.Size.X / 2 - 0.5), 0, c[2] * (roof.Size.Z / 2 - 0.5)) -- from mid-height: walls reach into the roof
			local hit = workspace:Raycast(at, Vector3.new(0, -80, 0), params)
			if hit and not CollectionService:HasTag(hit.Instance, "Mover") then
				supported = true
			end
		end
		if supported then
			continue
		end
		for _, axis in { roof.CFrame.LookVector, roof.CFrame.RightVector } do
			local half = if axis == roof.CFrame.LookVector then roof.Size.Z / 2 else roof.Size.X / 2
			local ends = {}
			for _, dir in { -1, 1 } do
				for d = half + 2, half + 70, 2 do
					local at = roof.Position + axis * dir * d
					local hit = workspace:Raycast(at, Vector3.new(0, -80, 0), params)
					if hit then
						ends[dir] = { at = at + axis * dir * 2, ground = hit.Position.Y }
						break
					end
				end
			end
			if ends[-1] and ends[1] then
				local y = roof.Position.Y + roof.Size.Y / 2 + 0.6
				local side = axis:Cross(Vector3.yAxis).Unit
				for _, s in { -1, 1 } do
					local offset = side * s * (math.min(roof.Size.X, roof.Size.Z) / 2 - 1)
					local a, b = ends[-1].at + offset, ends[1].at + offset
					local mid = (a + b) / 2
					steel(
						"Girder",
						v(1.2, 1.2, (b - a).Magnitude),
						CFrame.lookAt(Vector3.new(mid.X, y, mid.Z), Vector3.new(b.X, y, b.Z)),
						roof
					)
					for _, e in { { a, ends[-1].ground }, { b, ends[1].ground } } do
						local h = y - e[2]
						steel("GirderLeg", v(1.2, h, 1.2), CFrame.new(e[1].X, e[2] + h / 2, e[1].Z), roof)
					end
				end
				break
			end
		end
	end
	-- anything still plain grey-box grass (the Miko-cliff ramp, corridor floors with no Skin) becomes voxel ground too
	for _, d in world:GetDescendants() do
		if
			d:IsA("BasePart")
			and not d:GetAttribute("Skinned")
			and d.Transparency < 0.5
			and #d:GetTags() == 0
			and d.Material == SMOOTH
			and (d.Color == PP.Grass or d.Color == PP.Dirt)
		then
			apply(d, if d.Color == PP.Grass then "GrassBlock" else "DirtWall")
		end
	end
	bossHall(world, apply) -- before the undersides: its terraces get theirs too
	islandUndersides(world, params, apply)
	bossTileChunks(world)
	-- the Fire Bar Run gallery glass was a bare pale slab: now real glass in a wooden frame (posts, sill, top rail),
	-- starting at the gallery floor instead of hanging below it. Frame pieces don't collide or block aim rays.
	for _, glass in world:GetDescendants() do
		if glass.Name ~= "GalleryGlass" or not glass:IsA("BasePart") then
			continue
		end
		local cf, size = glass.CFrame, glass.Size
		local long = if size.Z >= size.X then cf.LookVector else cf.RightVector
		local length = math.max(size.X, size.Z)
		local thick = math.min(size.X, size.Z)
		local top = glass.Position.Y + size.Y / 2
		-- the floor on the gallery side (the glass stands on the walk's edge)
		local side = (if size.Z >= size.X then cf.RightVector else cf.LookVector) * (thick / 2 + 0.6)
		local floorY
		for _, s in { -1, 1 } do
			local hit = workspace:Raycast(
				glass.Position + side * s + Vector3.new(0, size.Y / 2, 0),
				Vector3.new(0, -size.Y, 0),
				params
			)
			if hit and (not floorY or hit.Position.Y > floorY) then
				floorY = hit.Position.Y
			end
		end
		if not floorY then
			continue
		end
		local h = top - floorY
		glass.Size = if size.Z >= size.X then v(thick, h, length) else v(length, h, thick)
		glass.CFrame = cf.Rotation + Vector3.new(glass.Position.X, floorY + h / 2, glass.Position.Z)
		glass.Material = Enum.Material.Glass
		glass.Color = Color3.fromRGB(215, 235, 245)
		glass.Transparency = 0.85
		glass.Reflectance = 0.12
		local frame = Instance.new("Folder")
		frame.Name = "GlassFrame"
		frame.Parent = glass.Parent
		local function iron(name: string, sz: Vector3, at: CFrame)
			local p = hiddenPart(name, sz, at, frame)
			p.Transparency = 0
			p.Material = Enum.Material.Wood -- painted metal read navy under the sky; warm wood like the gantries
			p.Color = Color3.fromHex("#7A4E2A")
		end
		local base = CFrame.lookAt(
			Vector3.new(glass.Position.X, floorY, glass.Position.Z),
			Vector3.new(glass.Position.X, floorY, glass.Position.Z) + long
		)
		local posts = math.ceil(length / 11)
		for i = 0, posts do
			local z = -length / 2 + i * length / posts
			iron("GlassPost", v(thick + 0.5, h, 0.6), base * CFrame.new(0, h / 2, -z))
		end
		iron("GlassSill", v(thick + 0.9, 0.8, length + 0.6), base * CFrame.new(0, 0.4, 0))
		iron("GlassRail", v(thick + 0.7, 0.6, length + 0.6), base * CFrame.new(0, h - 0.3, 0))
		iron("GlassRail", v(thick + 0.5, 0.4, length), base * CFrame.new(0, 9, 0))
	end
	for _, sign in world:GetDescendants() do
		if sign.Name ~= "Sign" or not sign:IsA("BasePart") or sign:GetAttribute("Skinned") ~= "Sign" then
			continue
		end
		local top = sign.Position.Y + sign.Size.Y / 2
		for _, side in { -1, 1 } do
			-- behind the board, under its battens (the voxel board keeps them 0.9 in from each end)
			local inset = 0.9 * sign.Size.X / 14
			-- just behind the board if there's ground there, else as close behind/under it as there is (a sign on a
			-- ledge's lip: WARP PIPE SWAP)
			local foot, hit
			for _, back in { 0.6, 0, -0.6, -1.5 } do
				foot = sign.CFrame * Vector3.new(side * (sign.Size.X / 2 - inset), -sign.Size.Y / 2, back)
				hit = workspace:Raycast(foot, Vector3.new(0, -60, 0), params)
				if hit then
					break
				end
			end
			if hit then
				local height = top + 0.5 - hit.Position.Y
				local post = Instance.new("Part")
				post.Name = "SignPost"
				post.Size = Vector3.new(0.9, height, 0.9)
				post.CFrame = CFrame.new(foot.X, hit.Position.Y + height / 2, foot.Z) * sign.CFrame.Rotation
				post.Anchored = true
				post.CanCollide = false
				post.CanQuery = false
				post.CanTouch = false
				post.Transparency = 1
				post.Parent = sign
				apply(post, "SignPost")
				-- grass and flowers growing round the foot of the post
				for i, skin in { "Tuft", if side < 0 then "Flowers2" else "Flowers3" } do
					local design = Skins[skin].Design
					local out = sign.CFrame:VectorToWorldSpace(Vector3.new(side * (0.8 + i * 0.6), 0, -0.6 + i * 0.7))
					local at = hit.Position + out
					local tuft = hiddenPart(
						"PostFoliage",
						design,
						CFrame.new(at.X, hit.Position.Y + design.Y / 2 - 0.1, at.Z) * sign.CFrame.Rotation,
						sign
					)
					if not apply(tuft, skin) then
						tuft:Destroy()
					end
				end
			end
		end
	end
end

return { Skins = Skins, Dressing = Dressing, Decor = Decor, Extras = Extras }
