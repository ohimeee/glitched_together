-- Starfall Castle enemies: Roblox Studio generate_mesh (textured, stylized-realistic; the approved graphics
-- baseline). Each skin fits its CombatService collider: scaled to the collider height, feet on its floor, and
-- turned by Yaw so the model faces the enemy's -Z (generations come out facing different ways).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)

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

local Dressing: { [string]: string } = {
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
local function Extras(world: Instance, apply: (BasePart, string) -> boolean)
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
