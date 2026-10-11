-- Epilogue art (21st session, user: "realistic re-skin" so the walk matches the Blender night panorama; no voxel):
-- every ground part (Greybox attr `Ground`) becomes a rock body (EpRock) under a meadow cap (EpGrass), the path gets
-- a dirt trail (EpPath) (Poly Haven CC0, graded by textures/make_epilogue_ground.py). Trees, shrubs, boulders,
-- wildflowers, fences, lanterns and cliff rocks are Studio generate_mesh models (realistic photogrammetry prompts).
-- The castle corner keeps its real brick and flagstones (StarfallCastle's surface variants).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)

local SMOOTH = Enum.Material.SmoothPlastic
local v = Vector3.new

local function mesh(id: string, tex: string, size: Vector3): MeshAssets.Skin
	return {
		Design = size,
		Meshes = { Body = { Id = id, TextureId = tex, Offset = Vector3.zero, Size = size, Material = SMOOTH } },
	}
end

local Skins: { [string]: MeshAssets.Skin } = {
	EP_Oak = mesh("rbxassetid://118165198699872", "rbxassetid://74321373417956", v(14, 16.29, 13.94)),
	EP_Spruce = mesh("rbxassetid://107813368427557", "rbxassetid://82758336099154", v(8.84, 12.92, 9)),
	EP_Birch = mesh("rbxassetid://83769674129389", "rbxassetid://111135825322856", v(9, 12.13, 8.79)),
	EP_Bush = mesh("rbxassetid://91284029405412", "rbxassetid://105013001072282", v(3.77, 3.5, 3.79)),
	EP_Rocks = mesh("rbxassetid://115945532375784", "rbxassetid://109643544444842", v(3.21, 3, 2.36)),
	EP_Flowers = mesh("rbxassetid://108570217073539", "rbxassetid://91004377568198", v(2.64, 1.6, 2.6)),
	EP_Fence = mesh("rbxassetid://84201958927401", "rbxassetid://102454777643168", v(4.48, 2.84, 0.8)),
	EP_Lantern = mesh("rbxassetid://112755272091930", "rbxassetid://133305895822929", v(0.96, 3.02, 1.6)),
	-- the support notice board beside the BACK TO LOBBY exit (tools/support_board/kit.py; text + prompts: Greybox)
	EP_SupportBoard = {
		Design = v(6.9, 8.06, 2.09),
		Meshes = {
			Wood = {
				Id = "rbxassetid://108071343449392",
				Offset = v(0, 0, 0),
				Size = v(6.9, 8.06, 2.092),
				Material = Enum.Material.Wood,
				Color = Color3.fromRGB(120, 82, 52),
			},
			Planks = {
				Id = "rbxassetid://116655398009300",
				Offset = v(0, 0.27, 0.05),
				Size = v(4.86, 3.45, 0.16),
				Material = Enum.Material.WoodPlanks,
				Color = Color3.fromRGB(84, 56, 36),
			},
			Iron = {
				Id = "rbxassetid://77561140592102",
				Offset = v(0, -0.83, -0.015),
				Size = v(6.02, 6.4, 0.59),
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(50, 50, 55),
			},
		},
	},
	EP_Cliff = mesh("rbxassetid://73624780658541", "rbxassetid://123147321610898", v(6, 6.63, 6)),
}

-- a decor item standing on the ground: `top` = the ground's top, scaled from the mesh's own size
local function at(skin: string, scale: number, x: number, top: number, z: number, yaw: number?): { any }
	local h = Skins[skin].Design.Y * scale
	return { skin, CFrame.new(x, top + h / 2, z) * CFrame.Angles(0, math.rad(yaw or 0), 0), scale }
end
-- a cliff rock half sunk into an island edge, its top a rocky lip just over the grass
local function edge(x: number, top: number, z: number, yaw: number): { any }
	local h = Skins.EP_Cliff.Design.Y * 1.2
	return { "EP_Cliff", CFrame.new(x, top + 2 - h / 2, z) * CFrame.Angles(0, math.rad(yaw), 0), 1.2 }
end

local Decor: { { any } } = {
	-- start meadow (top 0), a split-rail fence along the front edge
	at("EP_Spruce", 1.3, -17, 0, -16),
	at("EP_Oak", 1, 16, 0, -13, 40),
	at("EP_Birch", 1.1, 18, 0, 12),
	at("EP_Bush", 1.2, -19, 0, 2),
	at("EP_Bush", 1, 12, 0, 18, 70),
	at("EP_Rocks", 1.5, -8, 0, -19, 20),
	at("EP_Flowers", 1.2, 6, 0, -16),
	at("EP_Flowers", 1, -10, 0, 6, 90),
	at("EP_Flowers", 1.1, 14, 0, 4, 200),
	at("EP_Flowers", 1, -4, 0, 17, 130),
	at("EP_Fence", 2, -16, 0, -21.3),
	at("EP_Fence", 2, -7, 0, -21.3, 180),
	at("EP_Fence", 2, 7, 0, -21.3),
	at("EP_Fence", 2, 16, 0, -21.3, 180),
	-- west meadow (top 0) and the grove (top 1, then 2)
	at("EP_Bush", 1.1, -14, 0, 28, 30),
	at("EP_Flowers", 1.2, -26, 0, 34),
	at("EP_Rocks", 1.2, -31, 0, 24, 140),
	at("EP_Oak", 1.1, -24, 1, 52, 110),
	at("EP_Birch", 1.2, -31, 1, 68, 20),
	at("EP_Birch", 1, -14, 1, 64, 200),
	at("EP_Spruce", 1.4, -18, 1, 84, 60),
	at("EP_Oak", 0.9, -28, 1, 94, 250),
	at("EP_Bush", 1.1, -12, 1, 46),
	at("EP_Bush", 1.3, -12, 1, 90, 120),
	at("EP_Flowers", 1.1, -20, 1, 60, 45),
	at("EP_Flowers", 1.2, -30, 1, 80),
	at("EP_Flowers", 1, -13, 1, 74, 300),
	at("EP_Rocks", 1.3, -33, 1, 44, 80),
	at("EP_Spruce", 1.5, -26, 2, 108, 10),
	at("EP_Spruce", 1.3, -18, 2, 124, 150),
	at("EP_Birch", 1.1, -30, 2, 136, 90),
	at("EP_Bush", 1.2, -12, 2, 112, 200),
	at("EP_Bush", 1, -13, 2, 138),
	at("EP_Flowers", 1.2, -22, 2, 116, 60),
	-- east meadow (top 0) up to the castle corner
	at("EP_Oak", 1.1, 24, 0, 38, 300),
	at("EP_Birch", 1.2, 30, 0, 58, 45),
	at("EP_Spruce", 1.3, 19, 0, 74, 100),
	at("EP_Bush", 1.1, 12, 0, 28, 10),
	at("EP_Bush", 1.2, 13, 0, 56, 160),
	at("EP_Bush", 1, 31, 0, 80, 250),
	at("EP_Flowers", 1.2, 20, 0, 48),
	at("EP_Flowers", 1, 28, 0, 30, 120),
	at("EP_Flowers", 1.1, 14, 0, 66, 240),
	at("EP_Rocks", 1.4, 32, 0, 44, 60),
	-- hilltop (top 6): trees in the corners, clear of the gold pieces and the portal arch
	at("EP_Spruce", 1.4, -20, 6, 186, 30),
	at("EP_Spruce", 1.2, 20, 6, 186, 200),
	at("EP_Birch", 1.1, -20, 6, 147, 70),
	at("EP_Bush", 1.1, 21, 6, 158, 90),
	at("EP_Flowers", 1.2, -21, 6, 168),
	at("EP_Flowers", 1, 4, 6, 150, 70),
	at("EP_Flowers", 1.1, -6, 6, 183, 160),
	at("EP_Flowers", 1, 21, 6, 176, 280),
	at("EP_Flowers", 1, -16.5, 6, 196, 40),
	at("EP_Flowers", 1, 16.5, 6, 196, 220),
	-- rocky lips round the island edges
	edge(-34, 0, 28, 0),
	edge(-34, 1, 58, 90),
	edge(-34, 1, 88, 200),
	edge(-34, 2, 124, 30),
	edge(34, 0, 34, 270),
	edge(34, 0, 66, 120),
	edge(-21, 0, -22, 180),
	edge(21, 0, -22, 60),
	edge(-24, 6, 158, 0),
	edge(24, 6, 176, 240),
	edge(-24, 6, 189, 150),
	edge(24, 6, 189, 330),
}

local CAP = 1 -- grass / trail cap thickness (its top sits just over the walkable ground part)
local function cap(ground: BasePart, name: string, width: number, lift: number, look: { any })
	local p = Instance.new("Part")
	p.Name = name
	p.Size = v(width, CAP, ground.Size.Z + 0.4)
	p.CFrame = ground.CFrame * CFrame.new(0, ground.Size.Y / 2 + lift - CAP / 2, 0)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Material = look[1]
	p.MaterialVariant = look[2]
	p.Color = look[3]
	p.Parent = ground
end

local GRASS = { Enum.Material.Grass, "EpGrass", Color3.fromRGB(96, 122, 82) }
local TRAIL = { Enum.Material.Ground, "EpPath", Color3.fromRGB(170, 160, 146) }

local Surfaces = {
	[Enum.Material.Cobblestone] = { "CastleFloor", Color3.fromRGB(205, 196, 214) },
	[Enum.Material.Slate] = { "CastleWall", Color3.fromRGB(178, 160, 210) },
}

local function Extras(world: Instance)
	for _, d in world:GetDescendants() do
		if not d:IsA("BasePart") then
			continue
		end
		local ground = d:GetAttribute("Ground")
		if ground then
			d.Material = Enum.Material.Rock
			d.MaterialVariant = "EpRock"
			d.Color = Color3.fromRGB(150, 142, 134)
			cap(d, "GrassCap", d.Size.X + 0.4, 0.05, GRASS)
			if ground == "Path" then
				cap(d, "Trail", 7, 0.1, TRAIL)
			end
			continue
		end
		local look = Surfaces[d.Material]
		if look then
			d.MaterialVariant = look[1]
			d.Color = look[2]
		end
	end
end

return { Skins = Skins, Dressing = {}, Decor = Decor, Extras = Extras }
