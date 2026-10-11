-- The Hollow Dragon's hall, "Shattered Cathedral" (user pick, Oct 12, 2026: "the hollow dragon site must be special or
-- extravagant"). The fight floor, the dragon, the hole and every gameplay part stay exactly as tested; this only dresses
-- around, under and behind them:
--   * behind the dragon a gable wall with a 52-wide rose window of stained glass (blue / emerald / wine, never a reserved
--     gameplay colour), lancets and a pointed doorway onto the hidden room; its upper right is torn away where the
--     Glitch ate it: magenta static pours off the ragged edge and loose voxels drift away from it
--   * clustered gothic piers down both sides on stone ledges (the near ones snapped off, so they never block the
--     top-down view), pointed arcade arches over the far ones, long wine banners with a gold star
--   * a gold star-compass inlay on the floor (textures/make_dragon_mosaic.py), the royal runner laid over it
--   * broken floor slabs drifting down into the hole over a faint magenta glow, and coloured moonlight falling
--     through the glass
-- Kit: tools/dragon_hall/kit.py (Blender) → blender_assets/dragon_hall/*.glb → tools/mesh/upload_model.py. Every
-- piece is visual only (no collision, no queries). Positions are hall-local, measured from the BossTrigger, so a
-- section shift carries them.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)

local v = Vector3.new
local DragonHall = {}

-- mesh id, Size (studs, Roblox axes). The glTF import turns a piece 180 degrees: its front (Blender -Y) faces Roblox
-- -Z and Blender +X becomes Roblox -X (measured with EditableMesh, Oct 12).
local KIT: { [string]: { any } } = {
	RoseWall = { "rbxassetid://81886448887344", v(127, 141, 13.6) },
	GlassBlue = { "rbxassetid://119232402482666", v(82, 74.5, 0.5) },
	GlassGold = { "rbxassetid://108256194986152", v(75.6, 49.45, 1) },
	GlassWine = { "rbxassetid://124482411635998", v(26.12, 26.12, 0.5) },
	Pillar = { "rbxassetid://76563284529478", v(16.45, 63.97, 23.4) },
	PillarBroken = { "rbxassetid://137594874771440", v(10.99, 39.97, 9.5) },
	PillarStump = { "rbxassetid://116754729703520", v(10.99, 15.67, 9.5) },
	ArchRib = { "rbxassetid://96565320900498", v(26.39, 22.81, 3) },
	Banner = { "rbxassetid://111986456365543", v(6, 26, 0.8) },
	BannerTrim = { "rbxassetid://128969071083146", v(8.94, 11.29, 1.2) },
	Chunk1 = { "rbxassetid://73597580047451", v(7.3, 4.51, 5.57) },
	Chunk2 = { "rbxassetid://124356822274085", v(8.45, 4.47, 4.67) },
	Chunk3 = { "rbxassetid://104592990553202", v(6.31, 4.46, 6.82) },
}
-- glass / trim box centres from their parent's box centre (tools/dragon_hall/kit.py prints them)
local GLASS = {
	GlassBlue = v(0, -19.25, 3.2),
	GlassGold = v(0, -10.275, 3.2),
	GlassWine = v(0.938, -9.438, 3.2),
}
local TRIM_OFFSET = v(0, 8.353, -0.044)

local MOSAIC = "rbxassetid://99838830000219" -- textures/dragon_mosaic.png
local GODRAY = "rbxassetid://131326791885754" -- textures/godray.png

local STONE = Color3.fromRGB(150, 143, 150) -- neutral limestone: the moonlit castle light adds the purple
local LEDGE = Color3.fromRGB(128, 118, 140)
-- the glass glows (Neon), so the colours are darkened to read as stained glass, not lamps
local GLASS_COLOR = {
	GlassBlue = Color3.fromRGB(24, 38, 96),
	GlassGold = Color3.fromRGB(22, 72, 46), -- emerald: amber glass read as Kai's reserved orange in play
	GlassWine = Color3.fromRGB(72, 20, 48),
}

local WALL_Z = 1692 -- the rose wall's centre line (the hidden-room passage and WorldExit end at z 1682)

local function piece(name: string, folder: Instance, cf: CFrame, material: Enum.Material, color: Color3): MeshPart?
	local info = KIT[name]
	local ok, part = pcall(MeshAssets.Template, "DH_" .. name, {
		Id = info[1],
		Offset = Vector3.zero,
		Size = info[2],
		Material = material,
		Color = color,
	})
	if not ok then
		warn("[DragonHall] mesh failed:", name, part)
		return nil
	end
	local p = part :: MeshPart
	p.CFrame = cf
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = material ~= Enum.Material.Neon
	p.Parent = folder
	return p
end

local function block(folder: Instance, name: string, size: Vector3, cf: CFrame, props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Size = size
	p.CFrame = cf
	if props then
		for k, value in props do
			(p :: any)[k] = value
		end
	end
	p.Parent = folder
	return p
end

-- an invisible holder the client bobs / spins (PropMotionController); the mesh rides on it
local function drifting(folder: Instance, cf: CFrame, bob: number, rate: number, spin: number): Part
	local holder = block(folder, "DH_Drift", Vector3.one, cf, { Transparency = 1 })
	holder:SetAttribute("Bob", bob)
	holder:SetAttribute("BobRate", rate)
	holder:SetAttribute("Spin", spin)
	CollectionService:AddTag(holder, "PropMotion")
	return holder
end

function DragonHall.Build(world: Instance)
	if KIT.RoseWall[1] == "rbxassetid://0" then
		return -- kit not uploaded yet
	end
	local trigger: BasePart? = nil
	for _, p in CollectionService:GetTagged("BossTrigger") do
		if p:IsA("BasePart") and p:GetAttribute("Boss") == "HollowDragon" and p:IsDescendantOf(world) then
			trigger = p
		end
	end
	if not trigger then
		return
	end
	-- hall-local (x, y above the floor top, z as in the Greybox) → world
	local origin = trigger.Position - v(0, 15, 1565)
	local function at(x: number, y: number, z: number): Vector3
		return origin + v(x, y, z)
	end
	local folder = Instance.new("Folder")
	folder.Name = "DragonHall"
	folder.Parent = world

	-- 1. the rose wall, its front (-Z) to the hall; standing on a brick footing that drops into the dark
	local wallSize = KIT.RoseWall[2]
	local wallCF = CFrame.new(at(0, wallSize.Y / 2, WALL_Z))
	local wall = piece("RoseWall", folder, wallCF, Enum.Material.Limestone, STONE)
	if wall then
		for name, offset in GLASS do
			local glass = piece(name, folder, wallCF * CFrame.new(offset), Enum.Material.Neon, GLASS_COLOR[name])
			if glass then
				glass.Transparency = 0.15
			end
		end
	end
	block(folder, "DH_Footing", v(132, 90, 18), CFrame.new(at(0, -45, WALL_Z)), {
		Material = Enum.Material.Slate,
		MaterialVariant = "CastleWall",
		Color = LEDGE,
	})

	-- 2. piers on stone ledges down both sides; near ones snapped (top-down view), far ones carry arches + banners
	local PIER_X = 52
	local rows = {
		{ z = 1538, kind = "PillarStump" },
		{ z = 1562, kind = "PillarBroken" },
		{ z = 1586, kind = "Pillar" },
		{ z = 1610, kind = "Pillar" },
		{ z = 1634, kind = "Pillar" },
		{ z = 1658, kind = "Pillar" },
	}
	for _, side in { -1, 1 } do
		local x = side * PIER_X
		-- a continuous ledge outside the hall wall, down into the dark (the piers stand on it, nothing floats)
		block(folder, "DH_Ledge", v(10, 70, 136), CFrame.new(at(x, -35, 1598)), {
			Material = Enum.Material.Slate,
			MaterialVariant = "CastleWall",
			Color = LEDGE,
		})
		-- springers point local -X: the left row turns round to face in, the right one already does
		local yaw = if side < 0 then math.pi else 0
		for i, row in rows do
			local size = KIT[row.kind][2]
			-- the full pier's box is lopsided (its springers reach -X and +-Z): shift so the shaft sits on the line
			local shift = if row.kind == "Pillar" then -(size.X / 2 - 4.75) else 0
			local cf = CFrame.new(at(x, size.Y / 2, row.z)) * CFrame.Angles(0, yaw, 0) * CFrame.new(shift, 0, 0)
			piece(row.kind, folder, cf, Enum.Material.Limestone, STONE)
			if row.kind == "Pillar" then
				-- a banner on the hall side of the pier, hanging from just under the capital
				local bsize = KIT.Banner[2]
				local bcf = CFrame.new(at(x - side * 4.6, 50 - bsize.Y / 2, row.z))
					* CFrame.Angles(0, if side < 0 then -math.pi / 2 else math.pi / 2, 0)
				local cloth = piece("Banner", folder, bcf, Enum.Material.Fabric, Palette.Castle.Banner)
				if cloth then
					cloth.MaterialVariant = "CastleVelvet"
					piece("BannerTrim", folder, bcf * CFrame.new(TRIM_OFFSET), Enum.Material.Metal, Palette.Castle.Gold)
				end
				-- the arcade arch to the next full pier
				local nextRow = rows[i + 1]
				if nextRow and nextRow.kind == "Pillar" then
					local asize = KIT.ArchRib[2]
					local mid = (row.z + nextRow.z) / 2
					piece(
						"ArchRib",
						folder,
						CFrame.new(at(x, 57.5 + asize.Y / 2 - 3, mid)) * CFrame.Angles(0, math.pi / 2, 0),
						Enum.Material.Limestone,
						STONE
					)
				end
			end
		end
	end

	-- 3. the star-compass inlay, under the royal runner
	local inlay = block(folder, "DH_Inlay", v(54, 0.05, 54), CFrame.new(at(0, 0.03, 1566)), { Transparency = 1 })
	local decal = Instance.new("Decal")
	decal.Face = Enum.NormalId.Top
	decal.Texture = MOSAIC
	decal.Transparency = 0.12
	decal.Parent = inlay

	-- 4. the hole: floor slabs drifting down over a faint magenta glow (the Glitch underneath)
	local rng = Random.new(12)
	for i = 1, 11 do
		local name = "Chunk" .. ((i % 3) + 1)
		local pos = at(rng:NextNumber(-40, 40), -rng:NextNumber(8, 46), rng:NextNumber(1606, 1662))
		if math.abs(pos.X - origin.X) < 9 then -- leave the knit-bridge lane clear
			pos += v(if pos.X > origin.X then 12 else -12, 0, 0)
		end
		local cf = CFrame.new(pos)
			* CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 6.28), rng:NextNumber(-0.5, 0.5))
		local holder =
			drifting(folder, cf, rng:NextNumber(1, 2.5), rng:NextNumber(0.05, 0.12), rng:NextNumber(-0.08, 0.08))
		local chunk = piece(name, holder, cf, Enum.Material.Cobblestone, STONE)
		if chunk then
			chunk.MaterialVariant = "CastleFloor"
		end
	end
	local glow = block(folder, "DH_VoidGlow", v(92, 1, 62), CFrame.new(at(0, -34, 1632)), {
		Material = Enum.Material.Neon,
		Color = Palette.Glow.Glitch,
		Transparency = 0.7,
	})
	local light = Instance.new("PointLight")
	light.Color = Palette.Glitch
	light.Range = 45
	light.Brightness = 0.9
	light.Parent = glow
	local motes = Instance.new("ParticleEmitter") -- static flecks rising out of the dark
	motes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	motes.Color = ColorSequence.new(Palette.Glitch, Palette.GlitchCyan)
	motes.LightEmission = 0.6
	motes.Size = NumberSequence.new(0.5, 0)
	motes.Transparency = NumberSequence.new(0.3, 1)
	motes.Lifetime = NumberRange.new(5, 8)
	motes.Speed = NumberRange.new(6, 10)
	motes.EmissionDirection = Enum.NormalId.Top
	motes.SpreadAngle = Vector2.new(15, 15)
	motes.Rate = 12
	motes.Parent = glow

	-- 5. the Glitch's bite in the rose wall: static pouring off the torn edge, loose voxels drifting away
	if wall then
		local bite = wallCF * CFrame.new(-28, 14, 0) -- the torn edge (Blender's upper right = Roblox local -X)
		local edge = block(folder, "DH_BiteFx", v(30, 40, 2), bite, { Transparency = 1 })
		local static = Instance.new("ParticleEmitter")
		static.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		static.Color = ColorSequence.new(Palette.Glitch, Palette.GlitchCyan)
		static.LightEmission = 0.8
		static.Size = NumberSequence.new(0.9, 0.2)
		static.Transparency = NumberSequence.new(0.1, 1)
		static.Lifetime = NumberRange.new(1.5, 3)
		static.Speed = NumberRange.new(1, 4)
		static.SpreadAngle = Vector2.new(180, 180)
		static.Rate = 10
		static.Parent = edge
		for i = 1, 16 do
			local s = rng:NextNumber(0.5, 1.6)
			local cf = bite * CFrame.new(rng:NextNumber(-22, 16), rng:NextNumber(-10, 34), rng:NextNumber(-10, 4))
			local holder =
				drifting(folder, cf, rng:NextNumber(1.5, 4), rng:NextNumber(0.08, 0.2), rng:NextNumber(-0.6, 0.6))
			-- mostly black checker bits, a few lit ones (big neon blobs read as fairy lights)
			local color = if i % 4 == 0
				then Palette.Glitch
				elseif i % 8 == 1 then Palette.GlitchCyan
				else Palette.GlitchBlack
			block(holder, "DH_Voxel", v(s, s, s), cf, {
				Material = if color == Palette.GlitchBlack then Enum.Material.SmoothPlastic else Enum.Material.Neon,
				Color = if color == Palette.GlitchBlack then color else Palette.ForNeon(color),
			})
		end
	end

	-- 6. moonlight through the glass: three faint coloured shafts falling toward the inlay (subtle: user dislikes bright)
	for i, shaft in
		{
			{ v(-10, 66, WALL_Z - 6), v(-6, 0, 1572), Color3.fromRGB(120, 150, 255) },
			{ v(4, 58, WALL_Z - 6), v(4, 0, 1566), Color3.fromRGB(255, 214, 140) },
			{ v(14, 70, WALL_Z - 6), v(12, 0, 1578), Color3.fromRGB(220, 120, 170) },
		}
	do
		local a0 = Instance.new("Attachment")
		local a1 = Instance.new("Attachment")
		local host = block(folder, "DH_Shaft" .. i, Vector3.one, CFrame.new(at(0, 0, 1566)), { Transparency = 1 })
		a0.WorldPosition = at(shaft[1].X, shaft[1].Y, shaft[1].Z)
		a1.WorldPosition = at(shaft[2].X, shaft[2].Y, shaft[2].Z)
		a0.Parent = host
		a1.Parent = host
		local beam = Instance.new("Beam")
		beam.Attachment0 = a0
		beam.Attachment1 = a1
		beam.Texture = GODRAY
		beam.TextureMode = Enum.TextureMode.Stretch
		beam.Width0 = 14
		beam.Width1 = 22
		beam.Color = ColorSequence.new(shaft[3])
		beam.LightEmission = 0.6
		beam.LightInfluence = 0
		beam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.7),
			NumberSequenceKeypoint.new(0.6, 0.82),
			NumberSequenceKeypoint.new(1, 1),
		})
		beam.FaceCamera = true
		beam.Parent = host
	end
end

return DragonHall
