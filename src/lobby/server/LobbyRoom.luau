-- The lobby room (blender_assets/briefs/Lobby.md): players are doll-sized in Kai and Miko's childhood bedroom at night,
-- on the shared desk where the two of them made the game. 1 stud ≈ 1.5 cm. The capsules stand on the desk (y 0); the
-- whole room is explorable while players wait or chat: book-stack stairs down to the floor, a fur rug, a bouncy bed
-- reached by wooden toy-block steps, a bookshelf with a ladder, the window with the moon outside.
-- Surfaces: Poly Haven CC0 textures as MaterialVariants (lobby.project.json, textures/polyhaven/lobby_*).
local CollectionService = game:GetService("CollectionService")

local LobbyRoom = {}

local FLOOR_Y = -50 -- the bedroom floor (the desk is 75 cm tall)
local CEIL_Y = 125
local X0, X1 = -160, 160 -- side walls
local Z0, Z1 = -230, 75 -- door wall .. window wall
local WIN = { X = 80, Y0 = 12, Y1 = 105 } -- window opening: half width, bottom, top
local rng = Random.new(2026)

local v = Vector3.new
local rgb = Color3.fromRGB

local folder: Folder

local function part(name: string, size: Vector3, cf: CFrame, props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, value in props or {} do
		(p :: any)[k] = value
	end
	p.Parent = folder
	return p
end

-- a box whose bottom-centre sits at `pos`
local function boxOn(name: string, size: Vector3, pos: Vector3, props: { [string]: any }?, yaw: number?): Part
	return part(name, size, CFrame.new(pos + v(0, size.Y / 2, 0)) * CFrame.Angles(0, yaw or 0, 0), props)
end

local function deco(p: Part): Part
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	return p
end

local WOOD_DESK = { Material = Enum.Material.Wood, MaterialVariant = "LobbyDesk", Color = rgb(214, 172, 128) }
local WOOD_SHELF = { Material = Enum.Material.Wood, Color = rgb(240, 232, 220) } -- white-painted wood
local PAINT_WHITE = { Material = Enum.Material.SmoothPlastic, Color = rgb(238, 234, 226) }

-- A book lying flat: cloth cover with cream page edges showing on three sides.
local BOOK_COLORS = {
	rgb(196, 70, 72), -- red
	rgb(70, 96, 170), -- blue
	rgb(80, 150, 100), -- green
	rgb(230, 186, 80), -- mustard
	rgb(240, 232, 214), -- cream
	rgb(160, 104, 176), -- plum
	rgb(110, 170, 200), -- sky
	rgb(214, 128, 86), -- rust
}
local function flatBook(pos: Vector3, w: number, d: number, t: number, yaw: number)
	local color = BOOK_COLORS[rng:NextInteger(1, #BOOK_COLORS)]
	local cover = boxOn("Book", v(w, t, d), pos, { Material = Enum.Material.Fabric, Color = color }, yaw)
	-- pages: inset on the open sides, so the cover shows as a rim
	deco(part("BookPages", v(w - 0.6, t - 0.5, d - 0.3), cover.CFrame * CFrame.new(0.35, 0, 0), {
		Material = Enum.Material.Fabric,
		Color = rgb(236, 228, 206),
	}))
	return cover
end

-- A stack of books whose top lands at `top` (random sizes, slightly twisted: a real messy pile).
local function bookStack(x: number, z: number, top: number, w: number, d: number)
	local y = FLOOR_Y
	local baseYaw = rng:NextNumber(-0.15, 0.15)
	local lastTop = y
	while y < top - 0.01 do
		local t = math.min(rng:NextNumber(2.2, 3.6), top - y)
		if t < 1 then
			break
		end
		local book = flatBook(
			v(x + rng:NextNumber(-0.8, 0.8), y, z + rng:NextNumber(-0.8, 0.8)),
			w * rng:NextNumber(0.92, 1.05),
			d * rng:NextNumber(0.9, 1.05),
			t,
			baseYaw + rng:NextNumber(-0.12, 0.12)
		)
		book.CanCollide = false -- one invisible collider per stack below keeps the steps clean to walk
		y += t
		lastTop = y
	end
	part("BookStackCollider", v(w * 0.9, lastTop - FLOOR_Y, d * 0.9), CFrame.new(x, (FLOOR_Y + lastTop) / 2, z), {
		Transparency = 1,
	})
end

local function walls()
	local H = CEIL_Y - FLOOR_Y
	local WALL = { Material = Enum.Material.Plaster, MaterialVariant = "LobbyWall", Color = rgb(168, 170, 214) }
	local t = 4
	part("Floor", v(X1 - X0, 4, Z1 - Z0), CFrame.new((X0 + X1) / 2, FLOOR_Y - 2, (Z0 + Z1) / 2), {
		Material = Enum.Material.WoodPlanks,
		MaterialVariant = "LobbyFloor",
		Color = rgb(206, 160, 120),
	})
	part("Ceiling", v(X1 - X0, 4, Z1 - Z0), CFrame.new((X0 + X1) / 2, CEIL_Y + 2, (Z0 + Z1) / 2), {
		Material = Enum.Material.Plaster,
		MaterialVariant = "LobbyWall",
		Color = rgb(150, 152, 196),
	})
	local midY = (FLOOR_Y + CEIL_Y) / 2
	part("WallLeft", v(t, H, Z1 - Z0), CFrame.new(X0 - t / 2, midY, (Z0 + Z1) / 2), WALL)
	part("WallRight", v(t, H, Z1 - Z0), CFrame.new(X1 + t / 2, midY, (Z0 + Z1) / 2), WALL)
	part("WallDoor", v(X1 - X0, H, t), CFrame.new((X0 + X1) / 2, midY, Z0 - t / 2), WALL)
	-- window wall: four pieces around the opening
	local zw = Z1 + t / 2
	part("WallWinL", v(WIN.X + X1, H, t), CFrame.new((X0 - WIN.X) / 2, midY, zw), WALL)
	part("WallWinR", v(X1 - WIN.X, H, t), CFrame.new((X1 + WIN.X) / 2, midY, zw), WALL)
	part("WallWinB", v(WIN.X * 2, WIN.Y0 - FLOOR_Y, t), CFrame.new(0, (FLOOR_Y + WIN.Y0) / 2, zw), WALL)
	part("WallWinT", v(WIN.X * 2, CEIL_Y - WIN.Y1, t), CFrame.new(0, (WIN.Y1 + CEIL_Y) / 2, zw), WALL)
	-- skirting boards + crown moulding (white paint)
	for _, w in
		{
			{ v(t + 1, 7, Z1 - Z0), v(X0 + 0.5, FLOOR_Y + 3.5, (Z0 + Z1) / 2) },
			{ v(t + 1, 7, Z1 - Z0), v(X1 - 0.5, FLOOR_Y + 3.5, (Z0 + Z1) / 2) },
			{ v(X1 - X0, 7, t + 1), v(0, FLOOR_Y + 3.5, Z0 + 0.5) },
			{ v(X1 - X0, 7, t + 1), v(0, FLOOR_Y + 3.5, Z1 - 0.5) },
			{ v(t + 2, 5, Z1 - Z0), v(X0 + 1, CEIL_Y - 2.5, (Z0 + Z1) / 2) },
			{ v(t + 2, 5, Z1 - Z0), v(X1 - 1, CEIL_Y - 2.5, (Z0 + Z1) / 2) },
			{ v(X1 - X0, 5, t + 2), v(0, CEIL_Y - 2.5, Z0 + 1) },
			{ v(X1 - X0, 5, t + 2), v(0, CEIL_Y - 2.5, Z1 - 1) },
		}
	do
		deco(part("Trim", w[1], CFrame.new(w[2]), PAINT_WHITE))
	end
	-- door on the far wall, with warm hallway light leaking under it
	local doorX = 90
	boxOn(
		"Door",
		v(60, 140, 2),
		v(doorX, FLOOR_Y, Z0 + 1),
		{ Material = Enum.Material.Wood, MaterialVariant = "LobbyShelf", Color = rgb(244, 238, 228) }
	)
	for _, s in { -1, 1 } do
		deco(boxOn("DoorFrame", v(4, 146, 4), v(doorX + s * 32, FLOOR_Y, Z0 + 2), PAINT_WHITE))
	end
	deco(boxOn("DoorFrame", v(68, 4, 4), v(doorX, FLOOR_Y + 142, Z0 + 2), PAINT_WHITE))
	local knob = deco(part("DoorKnob", v(3, 3, 3), CFrame.new(doorX - 22, FLOOR_Y + 62, Z0 + 3.5), {
		Shape = Enum.PartType.Ball,
		Material = Enum.Material.Metal,
		Color = rgb(206, 176, 110),
	}))
	local leak = deco(part("DoorGap", v(56, 0.6, 1), CFrame.new(doorX, FLOOR_Y + 0.4, Z0 + 2.2), {
		Material = Enum.Material.Neon,
		Color = rgb(255, 196, 130),
	}))
	local glow = Instance.new("SurfaceLight")
	glow.Face = Enum.NormalId.Back
	glow.Color = rgb(255, 190, 120)
	glow.Range = 16
	glow.Brightness = 1.2
	glow.Angle = 120
	glow.Parent = leak
	local _ = knob
end

local function windowSet()
	local z = Z1
	-- frame, mullions, sill (white painted wood)
	local cx, cy = 0, (WIN.Y0 + WIN.Y1) / 2
	local w, h = WIN.X * 2, WIN.Y1 - WIN.Y0
	for _, f in
		{
			{ v(w + 6, 4, 6), v(cx, WIN.Y1 + 1, z) },
			{ v(4, h, 6), v(-WIN.X - 1, cy, z) },
			{ v(4, h, 6), v(WIN.X + 1, cy, z) },
			{ v(3, h, 4), v(cx, cy, z + 1) },
			{ v(w, 3, 4), v(cx, cy + 6, z + 1) },
		}
	do
		part("WindowFrame", f[1], CFrame.new(f[2]), PAINT_WHITE)
	end
	part("WindowSill", v(w + 16, 3, 14), CFrame.new(cx, WIN.Y0 - 1.5, z - 4), PAINT_WHITE)
	deco(part("WindowGlass", v(w, h, 0.4), CFrame.new(cx, cy, z + 2), {
		Material = Enum.Material.Glass,
		Transparency = 0.85,
		Color = rgb(190, 205, 255),
	}))
	-- curtains: gathered panels of soft fabric on a brass rod, a few staggered folds each
	deco(
		part(
			"CurtainRod",
			v(w + 70, 1.6, 1.6),
			CFrame.new(cx, WIN.Y1 + 10, z - 8) * CFrame.Angles(0, 0, math.rad(90)),
			{
				Shape = Enum.PartType.Cylinder,
				Material = Enum.Material.Metal,
				Color = rgb(196, 166, 104),
			}
		)
	)
	part(
		"CurtainRod",
		v(w + 70, 1.6, 1.6),
		CFrame.new(cx, WIN.Y1 + 10, z - 8),
		{ Transparency = 1, CanCollide = false }
	)
	for _, side in { -1, 1 } do
		for k = 0, 5 do
			local x = side * (WIN.X + 6 + k * 4.2)
			local depth = if k % 2 == 0 then 3.4 else 2
			deco(
				part(
					"Curtain",
					v(4.6, WIN.Y1 + 10 - (FLOOR_Y + 2), depth),
					CFrame.new(x, (WIN.Y1 + 10 + FLOOR_Y + 2) / 2, z - 8 + (k % 2) * 1.2),
					{
						Material = Enum.Material.Fabric,
						Color = rgb(214, 156, 176), -- dusty rose
					}
				)
			)
		end
	end
	-- a little potted plant + a jar of fireflies on the sill
	local pot = boxOn(
		"PlantPot",
		v(10, 9, 10),
		v(-50, WIN.Y0, z - 6),
		{ Material = Enum.Material.Slate, Color = rgb(196, 112, 80) }
	)
	pot.Shape = Enum.PartType.Cylinder
	pot.CFrame = CFrame.new(-50, WIN.Y0 + 4.5, z - 6) * CFrame.Angles(0, 0, math.rad(90))
	pot.Size = v(9, 10, 10)
	for k = 1, 7 do
		local a = k / 7 * math.pi * 2
		deco(
			part(
				"PlantLeaf",
				v(1, 12, 5),
				CFrame.new(-50 + math.cos(a) * 2, WIN.Y0 + 14, z - 6 + math.sin(a) * 2)
					* CFrame.Angles(0, -a, 0)
					* CFrame.Angles(0, 0, math.rad(25)),
				{
					Material = Enum.Material.Grass,
					Color = rgb(74, 130, 70),
				}
			)
		)
	end
end

local function desk()
	-- top: 200 x 130, its surface at y 0
	part("DeskTop", v(200, 4, 130), CFrame.new(0, -2, 0), WOOD_DESK)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			boxOn("DeskLeg", v(6, 46, 6), v(sx * 94, FLOOR_Y, sz * 59), WOOD_DESK)
		end
	end
	-- drawer unit under the right side
	boxOn("DeskDrawers", v(48, 42, 120), v(70, FLOOR_Y + 2, 0), WOOD_DESK)
	for k = 0, 2 do
		local y = FLOOR_Y + 8 + k * 13
		deco(
			boxOn(
				"DrawerFront",
				v(44, 11, 1),
				v(70, y, -60.5),
				{ Material = Enum.Material.Wood, MaterialVariant = "LobbyDesk", Color = rgb(226, 186, 140) }
			)
		)
		deco(
			part(
				"DrawerKnob",
				v(2.2, 2.2, 2.2),
				CFrame.new(70, y + 5.5, -61.6),
				{ Shape = Enum.PartType.Ball, Material = Enum.Material.Metal, Color = rgb(206, 176, 110) }
			)
		)
	end
	-- the chair, pulled out a little
	local cz = -86
	boxOn("ChairSeat", v(46, 4, 44), v(-36, FLOOR_Y + 30, cz), WOOD_DESK, 0.12)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			boxOn("ChairLeg", v(3.5, 30, 3.5), v(-36 + sx * 20, FLOOR_Y, cz + sz * 19), WOOD_DESK, 0.12)
		end
	end
	boxOn("ChairBack", v(46, 44, 3), v(-36 - math.sin(0.12) * 21, FLOOR_Y + 34, cz - 21), WOOD_DESK, 0.12)
end

-- Paths: book-stack stairs from the desk's front-left corner down to the floor; toy-block steps up to the bed.
local function stairs()
	for k = 1, 9 do
		bookStack(-78, -76 - (k - 1) * 13, -5.4 * k, 20, 16)
	end
end

local LETTERS = { "K", "A", "I", "M", "I", "K", "O", "★" }
local function toyBlock(pos: Vector3, s: number, i: number)
	local colors = { rgb(214, 70, 64), rgb(60, 110, 190), rgb(240, 196, 70), rgb(70, 150, 90), rgb(236, 230, 214) }
	local b = boxOn(
		"ToyBlock",
		v(s, s, s),
		pos,
		{ Material = Enum.Material.Wood, Color = colors[(i % #colors) + 1] },
		rng:NextNumber(-0.1, 0.1)
	)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 20
		gui.LightInfluence = 1
		gui.Parent = b
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = rgb(255, 255, 255)
		t.TextStrokeTransparency = 0.6
		t.Text = LETTERS[(i % #LETTERS) + 1]
		t.Parent = gui
	end
	return b
end

local function bed()
	local x0, x1, z0, z1 = -158, -94, -228, -96
	local cx, cz = (x0 + x1) / 2, (z0 + z1) / 2
	local top = FLOOR_Y + 33
	boxOn("BedFrame", v(x1 - x0, 14, z1 - z0), v(cx, FLOOR_Y + 4, cz), WOOD_SHELF)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			boxOn("BedLeg", v(5, 6, 5), v(cx + sx * 28, FLOOR_Y, cz + sz * 62), WOOD_SHELF)
		end
	end
	boxOn("Headboard", v(x1 - x0, 60, 5), v(cx, FLOOR_Y, z0 + 2.5), WOOD_SHELF)
	local mattress = boxOn("Mattress", v(x1 - x0 - 2, top - (FLOOR_Y + 18), z1 - z0 - 6), v(cx, FLOOR_Y + 18, cz + 1), {
		Material = Enum.Material.Fabric,
		Color = rgb(244, 242, 236),
	})
	-- the quilt hangs over the open side and the foot
	local quilt = { Material = Enum.Material.Fabric, MaterialVariant = "LobbyQuilt", Color = rgb(214, 222, 240) }
	local q = boxOn("Quilt", v(x1 - x0 + 2, 2, z1 - z0 - 40), v(cx, top, cz + 18), quilt)
	deco(part("QuiltSide", v(1.5, 16, z1 - z0 - 40), CFrame.new(x1 + 1.6, top - 6, cz + 18), quilt))
	deco(part("QuiltFoot", v(x1 - x0 + 2, 16, 1.5), CFrame.new(cx, top - 6, z1 + 0.5), quilt))
	-- pillows (soft fleece balls squashed flat)
	for k, x in { cx - 15, cx + 15 } do
		local p =
			part("Pillow", v(26, 9, 18), CFrame.new(x, top + 3.5, z0 + 16) * CFrame.Angles(0, (k - 1.5) * 0.15, 0), {
				Shape = Enum.PartType.Ball,
				Material = Enum.Material.Fabric,
				Color = rgb(250, 246, 240),
			})
		p.Size = v(26, 9, 18)
	end
	-- the bed bounces: players hop around on it (BedBounce, client)
	CollectionService:AddTag(q, "Bouncy")
	CollectionService:AddTag(mattress, "Bouncy")
	-- wooden letter blocks as steps up from the floor (6 high each: a plain jump)
	local steps = {
		{ v(-84, FLOOR_Y, -150), 7 },
		{ v(-84, FLOOR_Y, -160), 13 },
		{ v(-86, FLOOR_Y, -171), 19 },
		{ v(-88, FLOOR_Y, -182), 25 },
		{ v(-91, FLOOR_Y, -192), 31 },
	}
	for i, s in steps do
		-- each step is a little tower of blocks
		local h = s[2]
		local size = 7
		local y = FLOOR_Y
		local n = 0
		while y + size <= FLOOR_Y + h + 0.01 do
			toyBlock(v(s[1].X, y, s[1].Z), size, i + n)
			y += size
			n += 1
		end
		local rest = FLOOR_Y + h - y
		if rest > 1 then
			toyBlock(v(s[1].X, y, s[1].Z), rest, i + n + 3).Size = v(size, rest, size)
		end
	end
	-- a mushroom nightlight on the floor by the bed head: the room's soft warm corner
	local stem = boxOn(
		"NightlightStem",
		v(4, 7, 4),
		v(-86, FLOOR_Y, -214),
		{ Material = Enum.Material.SmoothPlastic, Color = rgb(244, 236, 220) }
	)
	local cap =
		part("NightlightCap", v(5, 12, 12), CFrame.new(-86, FLOOR_Y + 8.5, -214) * CFrame.Angles(0, 0, math.rad(90)), {
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Neon,
			Color = rgb(220, 150, 110),
		})
	local glow = Instance.new("PointLight")
	glow.Color = rgb(255, 180, 120)
	glow.Range = 34
	glow.Brightness = 1.2
	glow.Parent = cap
	local _ = { mattress, stem }
end

local function bookshelf()
	local x0, x1 = 120, 158
	local z0, z1 = -200, -120
	local cz = (z0 + z1) / 2
	local H = 124
	boxOn("ShelfBack", v(2, H, z1 - z0), v(x1 - 1, FLOOR_Y, cz), WOOD_SHELF)
	for _, z in { z0, z1 } do
		boxOn("ShelfSide", v(x1 - x0, H, 3), v((x0 + x1) / 2, FLOOR_Y, z), WOOD_SHELF)
	end
	local levels = { FLOOR_Y + 2, FLOOR_Y + 26, FLOOR_Y + 50, FLOOR_Y + 74, FLOOR_Y + 98, FLOOR_Y + H - 2 }
	for i, y in levels do
		boxOn("Shelf", v(x1 - x0, 2.5, z1 - z0 - 3), v((x0 + x1) / 2, y - 1.25, cz), WOOD_SHELF)
		if i < #levels then
			-- upright books along the back, a gap or two, sometimes one leaning
			local z = z0 + 3
			while z < z1 - 8 do
				local bw = rng:NextNumber(1.8, 3.6)
				local bh = rng:NextNumber(13, 20)
				local bd = rng:NextNumber(10, 14)
				if rng:NextNumber() < 0.08 then
					z += rng:NextNumber(4, 9)
				else
					local color = BOOK_COLORS[rng:NextInteger(1, #BOOK_COLORS)]
					local b = deco(
						boxOn(
							"ShelfBook",
							v(bd, bh, bw),
							v(x1 - 2 - bd / 2, y + 0.1, z + bw / 2),
							{ Material = Enum.Material.Fabric, Color = color }
						)
					)
					-- a pale band on the spine
					deco(
						part(
							"SpineBand",
							v(0.2, 1.4, bw * 0.9),
							b.CFrame * CFrame.new(-bd / 2 - 0.05, bh * 0.25, 0),
							{ Material = Enum.Material.SmoothPlastic, Color = rgb(232, 214, 160) }
						)
					)
					z += bw + 0.2
				end
			end
		end
		-- walkable shelf front lip (the shelves are platforms)
	end
	-- a wooden ladder leaning on the shelf: rungs for the look, an invisible truss to climb
	local lx, lz = x0 - 9, cz
	for _, sz in { -6, 6 } do
		deco(
			part(
				"LadderRail",
				v(2, H + 6, 2),
				CFrame.new(lx + 4, FLOOR_Y + (H + 6) / 2, lz + sz) * CFrame.Angles(0, 0, math.rad(-6)),
				WOOD_DESK
			)
		)
	end
	for k = 0, math.floor(H / 8) do
		local y = FLOOR_Y + 4 + k * 8
		deco(
			part(
				"LadderRung",
				v(1.4, 1.4, 12),
				CFrame.new(lx + 4 + (y - FLOOR_Y) * math.tan(math.rad(6)) * -1 + 0.5, y, lz),
				WOOD_DESK
			)
		)
	end
	local truss = Instance.new("TrussPart")
	truss.Name = "LadderClimb"
	truss.Anchored = true
	truss.Size = v(2, H, 2)
	truss.CFrame = CFrame.new(lx + 2.5, FLOOR_Y + H / 2, lz)
	truss.Transparency = 1
	truss.Parent = folder
end

local function rug()
	local r = part("Rug", v(1.2, 120, 120), CFrame.new(-10, FLOOR_Y + 0.6, -150) * CFrame.Angles(0, 0, math.rad(90)), {
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Fabric,
		MaterialVariant = "LobbyRug",
		Color = rgb(226, 214, 236),
	})
	r.CanCollide = false
	-- a few toy blocks and a crayon scattered on the rug
	for i = 1, 6 do
		toyBlock(v(rng:NextNumber(-50, 30), FLOOR_Y + 1.2, rng:NextNumber(-190, -110)), 7, i + 2)
	end
end

-- Fairy lights: warm bulbs on a thin wire, draped in sags along the window wall and over the bed.
local function fairyLights()
	local function string_(a: Vector3, b: Vector3, sag: number, bulbs: number)
		local prev: Vector3? = nil
		for k = 0, bulbs do
			local t = k / bulbs
			local p = a:Lerp(b, t) - v(0, math.sin(t * math.pi) * sag, 0)
			if prev then
				local mid = (prev + p) / 2
				deco(
					part(
						"FairyWire",
						v(0.25, 0.25, (p - prev).Magnitude),
						CFrame.lookAt(mid, p),
						{ Color = rgb(60, 70, 50) }
					)
				)
			end
			local bulb = deco(part("FairyBulb", v(1.3, 1.3, 1.3), CFrame.new(p - v(0, 0.9, 0)), {
				Shape = Enum.PartType.Ball,
				Material = Enum.Material.Neon,
				Color = rgb(210, 130, 60), -- reads warm amber once Neon blooms
			}))
			if k % 4 == 0 then
				local l = Instance.new("PointLight")
				l.Color = rgb(255, 196, 130)
				l.Range = 12
				l.Brightness = 0.6
				l.Shadows = false
				l.Parent = bulb
			end
			prev = p
		end
	end
	local y = CEIL_Y - 12
	string_(v(X0 + 6, y, Z1 - 6), v(-WIN.X - 30, y - 4, Z1 - 6), 10, 16)
	string_(v(-WIN.X - 30, y - 4, Z1 - 6), v(WIN.X + 30, y - 4, Z1 - 6), 14, 26)
	string_(v(WIN.X + 30, y - 4, Z1 - 6), v(X1 - 6, y, Z1 - 6), 10, 16)
	string_(v(X0 + 6, y - 20, -228), v(X0 + 6, y - 20, -96), 12, 18)
end

-- glow-in-the-dark stars on the ceiling (a kid's sticker set)
local function ceilingStars()
	for _ = 1, 70 do
		local x = rng:NextNumber(X0 + 10, X1 - 10)
		local z = rng:NextNumber(Z0 + 10, Z1 - 10)
		local s = rng:NextNumber(2, 3.6)
		deco(part("GlowStar", v(0.2, s, s), CFrame.new(x, CEIL_Y - 0.15, z) * CFrame.Angles(0, 0, math.rad(90)), {
			Material = Enum.Material.Neon,
			Color = rgb(120, 170, 110), -- dim glow-in-the-dark green (Neon blooms bright colours to white)
			Transparency = 0.45,
			Shape = Enum.PartType.Cylinder,
		}))
	end
end

-- The kids' crayon drawings (textures/make_lobby_drawings.py), taped to the walls with masking tape.
local DRAWINGS = {
	{ "rbxassetid://103524685353613", v(-132, 46, Z1 - 0.3), v(0, 0, -1), 6 }, -- Starfall Castle, left of the window
	{ "rbxassetid://107627263951326", v(132, 44, Z1 - 0.3), v(0, 0, -1), -4 }, -- Kai + Miko, right of the window
	{ "rbxassetid://86717212437820", v(X0 + 0.3, 30, -128), v(1, 0, 0), -3 }, -- Pixel Plains, above the bed
	{ "rbxassetid://107484763047386", v(X0 + 0.3, 36, -196), v(1, 0, 0), 5 }, -- the level-3 plan
	{ "rbxassetid://103524685353613", v(X1 - 0.3, 46, -40), v(-1, 0, 0), -2 }, -- a second castle sketch by the drawers
}
local function drawings()
	for _, d in DRAWINGS do
		local pos, normal, tilt = d[2], d[3], d[4]
		local sheet = deco(
			part("Drawing", v(30, 40, 0.1), CFrame.lookAt(pos, pos + normal) * CFrame.Angles(0, 0, math.rad(tilt)), {
				Color = rgb(246, 240, 226),
			})
		)
		local decal = Instance.new("Decal")
		decal.Texture = d[1]
		decal.Face = Enum.NormalId.Front
		decal.Parent = sheet
		for _, corner in { v(-13, 18, 0), v(13, 18, 0), v(-13, -18, 0), v(13, -18, 0) } do
			deco(
				part(
					"Tape",
					v(7, 2.4, 0.12),
					sheet.CFrame
						* CFrame.new(corner + v(0, 0, -0.08))
						* CFrame.Angles(0, 0, math.rad(rng:NextNumber(-40, 40))),
					{
						Material = Enum.Material.Fabric,
						Color = rgb(226, 214, 170),
						Transparency = 0.15,
					}
				)
			)
		end
	end
end

function LobbyRoom.Build(parent: Instance)
	folder = Instance.new("Folder")
	folder.Name = "Room"
	walls()
	windowSet()
	desk()
	stairs()
	bed()
	bookshelf()
	rug()
	fairyLights()
	ceilingStars()
	drawings()
	folder.Parent = parent
	return folder
end

LobbyRoom.FloorY = FLOOR_Y
return LobbyRoom
