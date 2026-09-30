-- Starfall Castle enemies: Roblox Studio generate_mesh (textured, stylized-realistic; the approved graphics
-- baseline). Each skin fits its CombatService collider: scaled to the collider height, feet on its floor, and
-- turned by Yaw so the model faces the enemy's -Z (generations come out facing different ways).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)

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

local Dressing: { [string]: string } = {
	Skeleton = "Skeleton",
	SplitSlime = "SplitSlime",
	StaticArcher = "StaticArcher",
	ShieldGuard = "ShieldGuard",
	Shield = "GuardShield",
	StaticMage = "StaticMage",
}

return { Skins = Skins, Dressing = Dressing, Decor = {} }
