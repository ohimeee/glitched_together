-- Pixel Plains art (blender_assets/PixelPlains.*, briefs/PixelPlains.md). 1-stud voxels with small bevels, exact
-- art-direction.md palette; gameplay pieces wear their OWNER's color (Kai orange frames on freezables, Miko teal
-- ring and crate handles). Offsets/sizes are generated from Blender (studs, front = -Z) at each Design size.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)

local PP = Palette.PixelPlains
local SMOOTH = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon
local PLASTIC = "PixelPlastic" -- ArtService/Materials: toy plastic with a soft pixel grid
local v = Vector3.new

local Skins: { [string]: MeshAssets.Skin } = {
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
Skins.Tree = gen("rbxassetid://110637086239850", "rbxassetid://81380511005138", v(12, 16, 12), v(11.97, 15.89, 12))
Skins.Flowers = gen("rbxassetid://97758112493229", "rbxassetid://84236852470382", v(3.3, 3, 2.2), v(3.28, 3, 2.21))
Skins.Bush = gen("rbxassetid://97383134312851", "rbxassetid://132624303942108", v(2.9, 4, 2.9), v(2.85, 4, 2.86))

-- Kit 3 (blender_assets/PixelPlainsKit3.*): signs, timed door, pull lever, dropper chute, "BY KAI + MIKO" letters.
-- Real surfaces from Roblox materials (wood grain, metal); owner glow only on the gameplay part of each target.
local WOOD = Color3.fromHex("#C8964B")
local WOOD_DARK = Color3.fromHex("#7A5230")
local IRON = Color3.fromHex("#4A4A55")
Skins.Sign = { -- the text stays on the grey-box part's SurfaceGuis; planks sit just behind both faces
	Design = v(14, 3, 0.4),
	Meshes = {
		PP_Prop_Sign_Planks = {
			Id = "rbxassetid://132889818651877",
			Offset = v(0.005, -0.047, 0),
			Size = v(13.553, 2.979, 0.28),
			Material = Enum.Material.WoodPlanks,
			Color = WOOD,
		},
		PP_Prop_Sign_Battens = {
			Id = "rbxassetid://123232037562820",
			Offset = v(0, 0, 0),
			Size = v(10.1, 3.1, 0.38),
			Material = Enum.Material.Wood,
			Color = WOOD_DARK,
		},
	},
}
Skins.SignPost = {
	Design = v(0.9, 6, 0.9),
	Meshes = {
		PP_Prop_SignPost = {
			Id = "rbxassetid://132664259938554",
			Offset = v(0, 0, 0),
			Size = v(0.9, 6, 0.9),
			Material = Enum.Material.Wood,
			Color = WOOD_DARK,
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
-- the crank wheel stands in the crank part's YZ plane (it spins about X)
Skins.CrankSkin = gen("rbxassetid://80830869119397", "rbxassetid://99315066484452", v(0.6, 4, 4), v(4, 4, 1), nil, 90)

local Dressing: { [string]: string } = {
	MoveBlock = "MoveBlock",
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
	{ "Bush", CFrame.new(-12, 23.2, 1016) * CFrame.Angles(0, math.rad(212), 0), 1.6, "GlitchChase" },
	{ "Flowers", CFrame.new(20, 22.1, 1060) * CFrame.Angles(0, math.rad(120), 0), 1.4, "GlitchChase" },
	{ "Flowers", CFrame.new(-22, 22.1, 1090) * CFrame.Angles(0, math.rad(216), 0), 1.4, "GlitchChase" },
	{ "Tree", CFrame.new(-25, 6.4, -15) * CFrame.Angles(0, math.rad(20), 0), 0.8, "StarterMeadow" },
	{ "Tree", CFrame.new(25, 5.6, -16) * CFrame.Angles(0, math.rad(309), 0), 0.7, "StarterMeadow" },
	{ "Tree", CFrame.new(-87, 6.4, 12) * CFrame.Angles(0, math.rad(321), 0), 0.8, "StarterMeadow" },
	{ "Tree", CFrame.new(87, 6.4, -12) * CFrame.Angles(0, math.rad(39), 0), 0.8, "StarterMeadow" },
	{ "Tree", CFrame.new(-16, 5.6, 205) * CFrame.Angles(0, math.rad(357), 0), 0.7, "StarterMeadow" },
	{ "Tree", CFrame.new(-24, 28, 1050) * CFrame.Angles(0, math.rad(18), 0), 1.0, "GlitchChase" },
	{ "Tree", CFrame.new(24, 28.8, 1098) * CFrame.Angles(0, math.rad(330), 0), 1.1, "GlitchChase" },
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
	{ "Bush", CFrame.new(-11, 45, 196) * CFrame.Angles(0, math.rad(260), 0), 1.4, "CloudTower" },
	-- Coin Press: the vault is stacked with coin blocks
	{ "CoinBlock", CFrame.new(-10, 8, 200) * CFrame.Angles(0, math.rad(10), 0), 1.5, "CoinPress" },
	{ "CoinBlock", CFrame.new(10, 8, 200) * CFrame.Angles(0, math.rad(-10), 0), 1.5, "CoinPress" },
	{ "CoinBlock", CFrame.new(0, 14, 202), 2, "CoinPress" },
	{ "Cloud", CFrame.new(40, 40, 110), 2, "CoinPress" },
}

-- After dressing: wooden posts under every sign, from the ground up to just above the board (posts stand at the
-- board's ends so they never cover the lettering).
local function Extras(world: Instance, apply: (BasePart, string) -> boolean)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { world }
	params.RespectCanCollide = true
	for _, sign in world:GetDescendants() do
		if sign.Name ~= "Sign" or not sign:IsA("BasePart") or sign:GetAttribute("Skinned") ~= "Sign" then
			continue
		end
		local top = sign.Position.Y + sign.Size.Y / 2
		for _, side in { -1, 1 } do
			local foot = sign.CFrame * Vector3.new(side * (sign.Size.X / 2 - 0.1), -sign.Size.Y / 2, 0)
			local hit = workspace:Raycast(foot, Vector3.new(0, -60, 0), params)
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
			end
		end
	end
end

return { Skins = Skins, Dressing = Dressing, Decor = Decor, Extras = Extras }
