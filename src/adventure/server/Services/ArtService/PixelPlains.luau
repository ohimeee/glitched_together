-- Pixel Plains art (blender_assets/PixelPlains.*, briefs/PixelPlains.md). 1-stud voxels with small bevels, exact
-- art-direction.md palette; gameplay pieces wear their OWNER's color (Kai orange frames on freezables, Miko teal
-- ring and crate handles). Offsets/sizes are generated from Blender (studs, front = -Z) at each Design size.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)

local PP = Palette.PixelPlains
local SMOOTH = Enum.Material.SmoothPlastic
local NEON = Enum.Material.Neon
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
				Color = PP.Grass,
			},
			PP_Kit_GrassBlock_Dirt = {
				Id = "rbxassetid://82021329167270",
				Offset = v(0, -0.475, 0),
				Size = v(19.7, 5.05, 19.7),
				Material = SMOOTH,
				Color = PP.Dirt,
			},
			PP_Kit_GrassBlock_Spots = {
				Id = "rbxassetid://100055342018700",
				Offset = v(0, -1.65, 0),
				Size = v(19.9, 1.5, 19.9),
				Material = SMOOTH,
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
				Color = PP.Gold,
			},
			PP_Prop_CoinBlock_Frame = {
				Id = "rbxassetid://139212127358567",
				Offset = v(0, 0, 0),
				Size = v(4, 4, 4),
				Material = SMOOTH,
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
			Color = PP.Grass,
		},
		PP_Kit_Cliff_Dirt = {
			Id = "rbxassetid://132715282506690",
			Offset = v(0, -0.8, 0),
			Size = v(20, 18.4, 20),
			Material = SMOOTH,
			Color = PP.Dirt,
		},
		PP_Kit_Cliff_Strata = {
			Id = "rbxassetid://95695557584433",
			Offset = v(0, -1.4, 0),
			Size = v(20.24, 6.2, 20.24),
			Material = SMOOTH,
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
			Color = Color3.fromHex("#8A5A2E"),
		},
		PP_Kit_DirtWall_Top = {
			Id = "rbxassetid://73396039066734",
			Offset = v(0, 9.1, 0),
			Size = v(2.3, 1.8, 20.2),
			Material = SMOOTH,
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
			Material = SMOOTH,
			Color = Color3.fromHex("#2E2E36"),
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

local Dressing: { [string]: string } = {
	MoveBlock = "MoveBlock",
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
	}
do
	Dressing[name] = "GrassBlock"
end

-- Pure decoration placed with the world: { skin, CFrame, scale }. Clouds sit high and to the sides so they frame
-- the route without blocking the camera (art-direction.md §10); coin blocks are scale moments along the way.
local function cloud(x: number, y: number, z: number, yaw: number, scale: number): { any }
	return { "Cloud", CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0), scale }
end
local function coin(x: number, y: number, z: number, yaw: number, scale: number): { any }
	return { "CoinBlock", CFrame.new(x, y, z) * CFrame.Angles(0, math.rad(yaw), 0), scale }
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
	{ "Flowers", CFrame.new(-24, 1.95, -14) * CFrame.Angles(0, math.rad(178), 0), 1.3 },
	{ "Flowers", CFrame.new(22, 1.8, -12) * CFrame.Angles(0, math.rad(142), 0), 1.2 },
	{ "Bush", CFrame.new(-26, 3.2, 8) * CFrame.Angles(0, math.rad(186), 0), 1.6 },
	{ "Bush", CFrame.new(26, 2.8, 6) * CFrame.Angles(0, math.rad(188), 0), 1.4 },
	{ "Flowers", CFrame.new(-86, 1.8, -10) * CFrame.Angles(0, math.rad(108), 0), 1.2 },
	{ "Bush", CFrame.new(-86, 3, 94) * CFrame.Angles(0, math.rad(212), 0), 1.5 },
	{ "Flowers", CFrame.new(86, 1.8, 10) * CFrame.Angles(0, math.rad(252), 0), 1.2 },
	{ "Bush", CFrame.new(86, 3, 82) * CFrame.Angles(0, math.rad(324), 0), 1.5 },
	{ "Flowers", CFrame.new(-16, 1.95, 196) * CFrame.Angles(0, math.rad(84), 0), 1.3 },
	{ "Flowers", CFrame.new(16, 1.8, 158) * CFrame.Angles(0, math.rad(270), 0), 1.2 },
	{ "Bush", CFrame.new(16, 3.2, 206) * CFrame.Angles(0, math.rad(318), 0), 1.6 },
	{ "Bush", CFrame.new(-12, 2.8, 226) * CFrame.Angles(0, math.rad(142), 0), 1.4 },
	{ "Flowers", CFrame.new(10, 21.8, 250) * CFrame.Angles(0, math.rad(320), 0), 1.2 },
	{ "Bush", CFrame.new(-10, 23, 342) * CFrame.Angles(0, math.rad(272), 0), 1.5 },
	{ "Flowers", CFrame.new(12, 63.8, 414) * CFrame.Angles(0, math.rad(138), 0), 1.2 },
	{ "Bush", CFrame.new(-12, 23.2, 1016) * CFrame.Angles(0, math.rad(212), 0), 1.6 },
	{ "Flowers", CFrame.new(20, 22.1, 1060) * CFrame.Angles(0, math.rad(120), 0), 1.4 },
	{ "Flowers", CFrame.new(-22, 22.1, 1090) * CFrame.Angles(0, math.rad(216), 0), 1.4 },
	{ "Tree", CFrame.new(-25, 6.4, -15) * CFrame.Angles(0, math.rad(20), 0), 0.8 },
	{ "Tree", CFrame.new(25, 5.6, -16) * CFrame.Angles(0, math.rad(309), 0), 0.7 },
	{ "Tree", CFrame.new(-87, 6.4, 12) * CFrame.Angles(0, math.rad(321), 0), 0.8 },
	{ "Tree", CFrame.new(87, 6.4, -12) * CFrame.Angles(0, math.rad(39), 0), 0.8 },
	{ "Tree", CFrame.new(-16, 5.6, 205) * CFrame.Angles(0, math.rad(357), 0), 0.7 },
	{ "Tree", CFrame.new(-24, 28, 1050) * CFrame.Angles(0, math.rad(18), 0), 1.0 },
	{ "Tree", CFrame.new(24, 28.8, 1098) * CFrame.Angles(0, math.rad(330), 0), 1.1 },
}

return { Skins = Skins, Dressing = Dressing, Decor = Decor }
