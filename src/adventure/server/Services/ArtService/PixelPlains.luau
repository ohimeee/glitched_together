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

local Dressing: { [string]: string } = {
	MoveBlock = "MoveBlock",
	PixelCrusher = "Crusher",
	GrappleRing = "GrappleRing",
	Crate = "Crate",
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
}

return { Skins = Skins, Dressing = Dressing, Decor = Decor }
