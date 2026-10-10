-- Epilogue art: the finished kingdom reuses every world's skins (Greybox parts carry their own `Skin`: voxel
-- GrassBlock ground, Pixel Plains trees, castle braziers and banner, the Core's floppy save point). This only gives
-- the castle corner its real brick and flagstones (StarfallCastle's surface variants).
local Surfaces = {
	[Enum.Material.Cobblestone] = { "CastleFloor", Color3.fromRGB(205, 196, 214) },
	[Enum.Material.Slate] = { "CastleWall", Color3.fromRGB(178, 160, 210) },
}

local function Extras(world: Instance)
	for _, d in world:GetDescendants() do
		local look = d:IsA("BasePart") and Surfaces[d.Material]
		if look then
			(d :: BasePart).MaterialVariant = look[1];
			(d :: BasePart).Color = look[2]
		end
	end
end

return { Skins = {}, Dressing = {}, Decor = {}, Extras = Extras }
