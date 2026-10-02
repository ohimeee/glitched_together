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
			part.Transparency = 0.7
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
				"Tree",
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
				d.Color = d.Color:Lerp(HAZE, 0.35)
			end
		end
	end
end

-- After dressing: wooden posts under every sign, from the ground up to just above the board (posts stand at the
-- board's ends so they never cover the lettering).
local function Extras(world: Instance, apply: (BasePart, string) -> boolean)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { world }
	params.RespectCanCollide = true
	rootSprings(world, params)
	rigGantries(world, params, apply)
	dressPieces(world, apply)
	skyIslands(world, apply)
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
