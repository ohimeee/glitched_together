-- The bedroom's sculpted furniture (Oct 3, 2026; user: the box furniture "looks like Hide and Seek Extreme"):
-- Blender kit blender_assets/LobbyKit.blend, built by tools/lobby_kit/*.py. Every piece is modeled at its real place
-- in the room, so a mesh goes at its bounding-box centre, unrotated. LobbyRoom keeps its box parts as invisible
-- colliders (walking, climbing and bouncing stay exactly as before); the meshes are visual only.
-- Surfaces: MaterialVariants on MeshParts are box-projected in studs like on Parts (UVs ignored), so the Poly Haven
-- variants tile at real scale; many-coloured meshes (books) use the palette atlas (textures/make_lobby_palette.py).
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)

local LobbyKit = {}

local v = Vector3.new
local rgb = Color3.fromRGB

local PALETTE = "rbxassetid://85641984484582" -- textures/lobby_palette.png

type Surface = { Material: Enum.Material, Variant: string?, Color: Color3?, Texture: string? }
local SURFACES: { [string]: Surface } = {
	Oak = { Material = Enum.Material.Wood, Variant = "LobbyDesk", Color = rgb(214, 172, 128) },
	Paint = { Material = Enum.Material.Wood, Color = rgb(240, 234, 224) }, -- white-painted wood (the grain shows through)
	Brass = { Material = Enum.Material.Metal, Color = rgb(206, 176, 110) },
	Linen = { Material = Enum.Material.Fabric, Variant = "LobbyLinen", Color = rgb(250, 248, 244) }, -- ambientCG Fabric019
	Cotton = { Material = Enum.Material.Fabric, Variant = "LobbyCotton", Color = rgb(252, 250, 246) }, -- ambientCG Fabric060
	Quilt = { Material = Enum.Material.Fabric, Variant = "LobbyQuilt", Color = rgb(214, 222, 240) },
	Fabric = { Material = Enum.Material.Fabric, Variant = "LobbyCotton", Color = rgb(222, 150, 172) }, -- dusty rose cotton
	Fur = { Material = Enum.Material.Fabric, Variant = "LobbyRug", Color = rgb(226, 214, 236) },
	Pal = { Material = Enum.Material.Fabric, Texture = PALETTE }, -- cloth covers (SmoothPlastic read glossy)
	Cork = { Material = Enum.Material.Fabric, Variant = "LobbyCork", Color = rgb(226, 200, 170) }, -- ambientCG Cork001
	Slate = { Material = Enum.Material.Slate, Color = rgb(46, 58, 54) }, -- chalkboard
	Paper = { Material = Enum.Material.Neon, Color = rgb(120, 98, 74) }, -- rice-paper lantern, faintly lit from inside
}

-- name = LK_<Piece>_<Surface> in Blender; Center/Size are Roblox studs (tools/lobby_kit/kit.py report())
type Piece = { Id: string, Center: Vector3, Size: Vector3 }
local PIECES: { [string]: Piece } = {
	Desk_Oak = { Id = "rbxassetid://85664069443621", Center = v(0, -25, 0), Size = v(200, 50, 130) },
	Desk_Brass = { Id = "rbxassetid://98735164340818", Center = v(70, -23.125, -62.425), Size = v(7.3, 30.45, 2.05) },
	Chair_Oak = {
		Id = "rbxassetid://73746975548833",
		Center = v(-36, -9.267, -86.28),
		Size = v(50.553, 81.466, 49.367),
	},
	Bed_Paint = { Id = "rbxassetid://137495397578200", Center = v(-126, -18.2, -162), Size = v(64.8, 63.6, 132.8) },
	Bed_Linen = { Id = "rbxassetid://125626943389048", Center = v(-126, -25, -161), Size = v(60, 16, 124) },
	Bed_Quilt = {
		Id = "rbxassetid://94152411893207",
		Center = v(-120.453, -30.556, -135.08),
		Size = v(68.926, 40.14, 118.161),
	},
	Pillows_Cotton = {
		Id = "rbxassetid://103055335848850",
		Center = v(-125.855, -14.092, -212.722),
		Size = v(53.572, 8.217, 20.307),
	},
	Shelf_Paint = { Id = "rbxassetid://139440450327865", Center = v(138.2, 11.35, -160), Size = v(43.6, 125.3, 88) },
	Ladder_Oak = { Id = "rbxassetid://95741951919210", Center = v(115, 15, -160), Size = v(15.609, 129.351, 14.2) },
	ShelfBooks_Pal = {
		Id = "rbxassetid://101735837011195",
		Center = v(148.931, 9.566, -161.201),
		Size = v(15.101, 115.133, 71.599),
	},
	StairBooks_Pal = {
		Id = "rbxassetid://96428046349538",
		Center = v(-77.833, -27.895, -126.728),
		Size = v(23.936, 44.211, 122.174),
	},
	Window_Paint = { Id = "rbxassetid://129379256874528", Center = v(0, 58.35, 71.5), Size = v(176, 110.7, 15) },
	CurtainRod_Brass = {
		Id = "rbxassetid://140692382790126",
		Center = v(0, 117, 69.928),
		Size = v(239.2, 4.4, 10.145),
	},
	CurtainL_Fabric = {
		Id = "rbxassetid://73186625928975",
		Center = v(-99.64, 32.953, 68.5),
		Size = v(29.28, 165.118, 6.2),
	},
	CurtainR_Fabric = {
		Id = "rbxassetid://120726015088560",
		Center = v(99.64, 32.953, 68.5),
		Size = v(29.28, 165.118, 6.2),
	},
	Door_Paint = { Id = "rbxassetid://91398202036418", Center = v(90, 24.55, -228.4), Size = v(74, 149.1, 3.2) },
	Door_Brass = { Id = "rbxassetid://134096027666728", Center = v(93.125, 20, -225.35), Size = v(55.05, 108.4, 5.5) },
	Trim_Paint = { Id = "rbxassetid://114476631587191", Center = v(0, 37.5, -77.5), Size = v(320, 175, 305) },
	-- batch 3 (tools/lobby_kit/clutter.py): wall panelling, bunting, planet mobile, shelves + bins, desk + floor toys
	Wainscot_Paint = { Id = "rbxassetid://90460938817801", Center = v(0, -24.224, -77.5), Size = v(320, 39.551, 305) },
	Bunting_Pal = {
		Id = "rbxassetid://70766465425064",
		Center = v(-0.002, 104.37, -67.505),
		Size = v(312.231, 33.598, 265.267),
	},
	Mobile_Pal = { Id = "rbxassetid://104327392153579", Center = v(-8.85, 94, -147.301), Size = v(68.02, 62, 69.519) },
	Shelves_Paint = { Id = "rbxassetid://120498573131502", Center = v(0, 13, -115), Size = v(320, 126, 170) },
	Bins_Pal = { Id = "rbxassetid://120245429254055", Center = v(145.875, -26, -67), Size = v(20.25, 42, 67) },
	DeskClutter_Pal = {
		Id = "rbxassetid://111967015381636",
		Center = v(-4.906, 1.19, 4.881),
		Size = v(152.42, 2.62, 129.137),
	},
	FloorToys_Pal = {
		Id = "rbxassetid://115349599954419",
		Center = v(33.252, -43, -177.748),
		Size = v(160.503, 14, 94.503),
	},
	-- batch 4 (tools/lobby_kit/walls.py): corkboard, peg rail, photo string, paper lantern
	CorkFrame_Oak = { Id = "rbxassetid://98412143460946", Center = v(-40, 45, -228.8), Size = v(70, 50, 2.4) },
	Cork_Cork = { Id = "rbxassetid://86890298415414", Center = v(-40, 45, -229.4), Size = v(64, 44, 1.2) },
	CorkNotes_Pal = {
		Id = "rbxassetid://82200861545115",
		Center = v(-40.153, 43.87, -227.938),
		Size = v(53.689, 37.287, 1.575),
	},
	PegRail_Oak = { Id = "rbxassetid://82519861711920", Center = v(144, 45, -226.924), Size = v(26, 4, 6.152) },
	Photos_Pal = {
		Id = "rbxassetid://115511393054520",
		Center = v(158.875, 50.759, -69),
		Size = v(0.95, 18.771, 66.082),
	},
	Lantern_Paper = { Id = "rbxassetid://123274913094221", Center = v(46, 98, -112), Size = v(22.7, 22, 22.7) },
	LanternCord_Oak = { Id = "rbxassetid://114159294205996", Center = v(46, 116.75, -112), Size = v(6, 16.5, 6) },
	-- the A-frame chalkboard sign in the capsule ring (tools/lobby_kit/sign.py; lettering in LobbyBuilder)
	Sign_Oak = { Id = "rbxassetid://129756451760532", Center = v(0, 11.289, -14.736), Size = v(20, 22.842, 14.718) },
	SignBoard_Slate = {
		Id = "rbxassetid://108135782489235",
		Center = v(0, 11.361, -14),
		Size = v(16.4, 16.945, 10.753),
	},
	SignHinge_Brass = { Id = "rbxassetid://113948877706847", Center = v(0, 22.2, -14), Size = v(22, 1.4, 1.331) },
	SignBits_Pal = {
		Id = "rbxassetid://120692984009088",
		Center = v(1.4, 1.306, -23.922),
		Size = v(14.2, 2.813, 3.757),
	},
	Rug_Fur = { Id = "rbxassetid://72045910082061", Center = v(-10, -48.75, -150), Size = v(120, 2.5, 120) },
}

-- A 1-stud ABC block with a raised border on every face; LobbyRoom's ToyBlock parts get one each (scaled, recolored).
local TOY_BLOCK = "rbxassetid://112339444942735"

local function surfaceOf(name: string): Surface
	local key = string.match(name, "_(%w+)$") or "Paint"
	return SURFACES[key] or SURFACES.Paint
end

local function load(name: string, id: string, size: Vector3, surface: Surface): MeshPart?
	local ok, part = pcall(MeshAssets.Template, name, {
		Id = id,
		TextureId = surface.Texture,
		Offset = Vector3.zero,
		Size = size,
		Material = surface.Material,
		Variant = surface.Variant,
		Color = surface.Color,
	})
	if not ok then
		warn("[LobbyKit] couldn't load", name, part)
		return nil
	end
	return part
end

-- Builds the kit into `parent`; once every piece loaded, the box stand-ins in `room` (tag LobbyBox) turn into
-- invisible colliders (decorative ones are removed). Runs async: the room is playable meanwhile.
function LobbyKit.Build(parent: Instance, room: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Kit"
	folder.Parent = parent
	task.spawn(function()
		local pending, failed = 0, false
		for name, piece in PIECES do
			pending += 1
			task.spawn(function()
				local p = load(name, piece.Id, piece.Size, surfaceOf(name))
				if p then
					p.CFrame = CFrame.new(piece.Center)
					if name == "Lantern_Paper" then -- a small warm pool under the lantern (memory: subtle lights)
						local glow = Instance.new("PointLight")
						glow.Color = rgb(255, 196, 140)
						glow.Brightness = 0.5
						glow.Range = 26
						glow.Shadows = true
						glow.Parent = p
					end
					p.Parent = folder
				else
					failed = true
				end
				pending -= 1
			end)
		end
		-- toy blocks: one mesh per ToyBlock part, letters moved over
		local template: MeshPart? = nil
		pending += 1
		task.spawn(function()
			template = load("ToyBlock", TOY_BLOCK, v(1, 1, 1), { Material = Enum.Material.Wood })
			pending -= 1
		end)
		local started = os.clock()
		while pending > 0 and os.clock() - started < 60 do
			task.wait(0.1)
		end
		print(`[LobbyKit] loaded, pending {pending}, failed {failed}, template {template ~= nil}`)
		if failed or pending > 0 or not template then
			warn("[LobbyKit] kit incomplete; keeping the box furniture")
			folder:Destroy()
			return
		end
		-- (scan the room, not GetTagged: the lobby folder may not be in the DataModel yet, and GetTagged only sees
		-- instances that are; missing the swap leaves boxes z-fighting with the meshes)
		local all = room:GetDescendants()
		for _, block in all do
			if block:IsA("BasePart") and CollectionService:HasTag(block, "ToyBlock") then
				local m = template:Clone()
				m.Size = block.Size
				m.CFrame = block.CFrame
				m.Color = block.Color
				for _, gui in block:GetChildren() do
					if gui:IsA("SurfaceGui") then
						gui.Parent = m
					end
				end
				block.Transparency = 1
				m.Parent = folder
			end
		end
		for _, p in all do
			if p:IsA("BasePart") and CollectionService:HasTag(p, "LobbyBox") then
				if p.CanCollide then
					p.Transparency = 1
					for _, child in p:GetChildren() do
						if child:IsA("Decal") or child:IsA("SurfaceGui") then
							child:Destroy()
						end
					end
				else
					p:Destroy()
				end
			end
		end
	end)
	return folder
end

return LobbyKit
