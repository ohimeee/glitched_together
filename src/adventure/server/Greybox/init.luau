-- Grey-box worlds built from code, used until a real world exists in ServerStorage.Worlds.<Name>.
-- Every piece uses the same tags/attributes a Studio-built level would (implementation.md §4), so this
-- doubles as a working reference for level builders.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Worlds = require(ReplicatedStorage.Shared.Config.Worlds)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local UiTheme = require(ReplicatedStorage.Shared.Config.UiTheme)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)

local Greybox = {}

type Opts = {
	color: Color3?,
	material: Enum.Material?,
	tags: { string }?,
	attrs: { [string]: any }?,
	anchored: boolean?,
	collide: boolean?,
	transparency: number?,
	shape: Enum.PartType?,
	name: string?,
}

local rgb = Color3.fromRGB
local GREY = rgb(163, 162, 165)
local WHITE = Palette.Prologue.White
local NAVY = rgb(40, 46, 96) -- lighter than Palette.Prologue.Navy so grey-box panels read against the night sky
local STONE = rgb(232, 228, 216) -- neutral moving blocks
local WOOD = rgb(200, 150, 75)
-- Reserved gameplay colors (art-direction.md §6): owner of the target, never decoration.
local KAI = Palette.Kai -- Kai's targets: Freezable, Copyable, Burnable
local MIKO = Palette.Miko -- Miko's targets: GrappleRing, Pullable, CodeLayer
local DUO = Palette.Duo -- needs both: DuoGate, DuoPound, HeavyLever, BouncePad, WorldExit
local NEUTRAL = Palette.Neutral -- anyone: plates, swing points, checkpoints, buttons
local GLITCH = Palette.Glitch

local function block(parent: Instance, size: Vector3, cf: CFrame, opts: Opts?): Part
	local o: Opts = opts or {}
	local p = Instance.new("Part")
	p.Name = o.name or "Block"
	p.Size = size
	p.CFrame = cf
	p.Anchored = if o.anchored == nil then true else o.anchored
	p.CanCollide = if o.collide == nil then true else o.collide
	p.Color = o.color or GREY
	p.Material = o.material or Enum.Material.SmoothPlastic
	if p.Material == Enum.Material.Neon then
		p.Color = Palette.ForNeon(p.Color) -- reserved colors stay readable on Neon
	end
	p.Transparency = o.transparency or 0
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if o.shape then
		p.Shape = o.shape
	end
	for _, tag in o.tags or {} do
		CollectionService:AddTag(p, tag)
	end
	for k, v in o.attrs or {} do
		p:SetAttribute(k, v)
	end
	p.Parent = parent
	return p
end

-- A platform whose TOP surface sits at `top`.
local function platform(parent: Instance, size: Vector3, x: number, top: number, z: number, opts: Opts?): Part
	return block(parent, size, CFrame.new(x, top - size.Y / 2, z), opts)
end

-- Signs follow the world's look (UiTheme Sign*): menu panels in the Prologue, hand-painted marker on wood in
-- Pixel Plains, gold storybook lettering in the castle, monospace in the Core. Set per Build.
local signTheme: UiTheme.Theme = UiTheme.Default

local function sign(parent: Instance, text: string, cf: CFrame, size: Vector3?, color: Color3?): Part
	local s = block(parent, size or Vector3.new(24, 6, 0.6), cf, {
		color = color or signTheme.SignBoard,
		material = signTheme.SignMaterial,
		name = "Sign",
		collide = false,
	})
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.LightInfluence = 0.3
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 30
		gui.Parent = s
		local label = Instance.new("TextLabel")
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(0.5, 0.5)
		label.Size = UDim2.fromScale(0.92, 0.84)
		label.Rotation = signTheme.SignTilt
		label.BackgroundTransparency = 1
		label.Font = signTheme.SignFont
		label.TextScaled = true
		label.TextColor3 = signTheme.SignInk
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.TextStrokeTransparency = 0.75
		label.Text = text
		label.Parent = gui
	end
	return s
end

local function checkpoint(
	parent: Instance,
	order: number,
	x: number,
	top: number,
	z: number,
	world: string,
	hints: { string }?
)
	local attrs: { [string]: any } = { Order = order, World = world }
	if hints then
		attrs.Hint1 = hints[1]
		attrs.Hint2 = hints[2]
	end
	local cp = platform(parent, Vector3.new(10, 0.6, 10), x, top + 0.6, z, {
		name = `Checkpoint{order}`,
		color = NEUTRAL,
		material = Enum.Material.Neon,
		tags = { "Checkpoint" },
		attrs = attrs,
		transparency = 0.4,
	})
	cp.CanCollide = true
	return cp
end

local function killFloor(parent: Instance, y: number)
	block(parent, Vector3.new(2048, 2, 2048), CFrame.new(0, y, 0), {
		name = "KillZone",
		tags = { "KillZone" },
		transparency = 1,
		collide = false,
	})
end

local function spawnAt(parent: Instance, x: number, top: number, z: number)
	local s = Instance.new("SpawnLocation")
	s.Name = "Spawn"
	s.Anchored = true
	s.Neutral = true
	s.Duration = 0
	s.Size = Vector3.new(6, 1, 6)
	s.CFrame = CFrame.new(x, top + 0.5, z)
	s.Transparency = 1
	s.CanCollide = false
	s.Parent = parent
end

local function gate(parent: Instance, group: string, size: Vector3, cf: CFrame, latch: boolean?)
	block(parent, size, cf, {
		name = `Gate_{group}`,
		color = DUO,
		material = Enum.Material.Neon,
		tags = { "DuoGate" },
		attrs = { Group = group, Latch = if latch == nil then true else latch },
		transparency = 0.2,
	})
end

local function waypoints(target: Instance, cfs: { CFrame })
	local folder = Instance.new("Folder")
	folder.Name = "Waypoints"
	for i, cf in cfs do
		local wp = Instance.new("Part")
		wp.Name = tostring(i)
		wp.Size = Vector3.one
		wp.CFrame = cf
		wp.Anchored = true
		wp.CanCollide = false
		wp.Transparency = 1
		wp.Parent = folder
	end
	folder.Parent = target
end

-- Prologue: the broken Title Screen. Teaches the moveset and every two-player piece.
local function buildPrologue(world: Model)
	local W = "Prologue"
	killFloor(world, -40)
	workspace:SetAttribute("KillY", -60)

	-- A: start (a giant title card)
	platform(world, Vector3.new(44, 4, 44), 0, 0, 0, { color = NAVY, name = "Start" })
	spawnAt(world, 0, 0, -8)
	checkpoint(
		world,
		1,
		0,
		0,
		0,
		W,
		{ "Space to jump, Space again in the air to double jump!", "Shift dashes. Ctrl in the air is a ground pound." }
	)
	sign(world, "STARFALL KINGDOM\n▶ CONTINUE?", CFrame.new(0, 14, 20), Vector3.new(30, 10, 1), NAVY).Name =
		"TitleCard"
	platform(
		world,
		Vector3.new(8, 1, 8),
		14,
		1,
		-12,
		{ name = "CrackedDemo", color = rgb(150, 110, 80), tags = { "CrackedFloor" } }
	)
	sign(world, "POUND ME (Ctrl in air)", CFrame.new(14, 5, -16), Vector3.new(10, 2.5, 0.4))

	-- Giant menu buttons: stepping stones
	for i, top in { 3, 7, 11 } do
		platform(world, Vector3.new(10, 4, 10), 0, top, 13 + i * 11, { color = WHITE, name = `MenuButton{i}` })
	end

	-- "Options slider": a 24-stud gap from the last button, past double jump (≤ 22), so it needs the air dash
	platform(world, Vector3.new(20, 4, 20), 0, 11, 85, { color = NAVY, name = "OptionsSlider" })
	platform(
		world,
		Vector3.new(3, 1.2, 20),
		0,
		11.6,
		85,
		{ color = Palette.Prologue.Pink, material = Enum.Material.Neon, collide = false }
	)
	sign(world, "OPTIONS", CFrame.new(0, 17, 94), Vector3.new(14, 3, 0.4))
	checkpoint(
		world,
		2,
		0,
		11,
		85,
		W,
		{ "Wall jump: jump into the orange walls, then jump again.", "Bounce between both walls to climb." }
	)

	-- Chimney of Clingable walls → C
	platform(world, Vector3.new(12, 4, 12), 0, 11, 101, { color = NAVY, name = "ChimneyBase" })
	for _, x in { -5.5, 5.5 } do
		block(world, Vector3.new(1, 28, 10), CFrame.new(x, 25, 102), {
			color = rgb(140, 100, 70), -- rough, not a reserved color
			material = Enum.Material.Slate,
			tags = { "Clingable" },
			name = "ClingWall",
		})
	end
	platform(world, Vector3.new(24, 4, 20), 0, 31, 118, { color = NAVY, name = "LoadGame" })
	checkpoint(
		world,
		3,
		0,
		31,
		118,
		W,
		{ "F near the glowing ball to swing. Jump to let go.", "Swing, then jump at the far end of the arc." }
	)

	-- Swing point over a pit → D
	-- SaveSlots sits 18 above LoadGame (reach ~16), so only the swing gets you there
	block(world, Vector3.new(2.5, 2.5, 2.5), CFrame.new(0, 56, 139), {
		color = NEUTRAL,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		tags = { "SwingPoint" },
		name = "SwingPoint",
	})
	platform(world, Vector3.new(20, 4, 20), 0, 49, 160, { color = NAVY, name = "SaveSlots" })

	-- Grind rail down to E
	local railStart = Vector3.new(0, 49.5, 172)
	local railEnd = Vector3.new(0, 20.5, 232)
	local rail = block(
		world,
		Vector3.new(1, 1, (railEnd - railStart).Magnitude),
		CFrame.lookAt((railStart + railEnd) / 2, railEnd),
		{
			color = rgb(170, 175, 190),
			material = Enum.Material.Metal,
			tags = { "GrindRail" },
			name = "GrindRail",
		}
	)
	rail.CFrame = CFrame.lookAt((railStart + railEnd) / 2, railEnd)
	sign(world, "F to grind", CFrame.new(6, 54, 168), Vector3.new(8, 2.5, 0.4))

	platform(world, Vector3.new(30, 4, 34), 0, 18, 253, { color = NAVY, name = "Credits" })
	checkpoint(world, 4, 0, 18, 244, W, {
		"One of you stands on the pad, the other ground-pounds it.",
		"The high plate and the low plate must be held at the same time.",
	})

	-- Bounce pad + high ledge plate + low plate → Duo Gate G1
	platform(
		world,
		Vector3.new(8, 1, 8),
		-8,
		18.6,
		256,
		{ color = DUO, material = Enum.Material.Neon, tags = { "BouncePad" }, name = "BouncePad" }
	)
	platform(world, Vector3.new(14, 4, 14), -8, 40, 282, { color = NAVY, name = "HighLedge" })
	platform(
		world,
		Vector3.new(6, 0.6, 6),
		-8,
		40.6,
		284,
		{ color = NEUTRAL, tags = { "PressurePlate" }, attrs = { Group = "G1" }, name = "PlateHigh" }
	)
	platform(
		world,
		Vector3.new(6, 0.6, 6),
		9,
		18.6,
		262,
		{ color = NEUTRAL, tags = { "PressurePlate" }, attrs = { Group = "G1" }, name = "PlateLow" }
	)
	gate(world, "G1", Vector3.new(30, 16, 2), CFrame.new(0, 26, 271))

	-- G: jump vent (blows DOWN until the partner pounds its button) → H
	platform(world, Vector3.new(30, 4, 40), 0, 18, 292, { color = NAVY, name = "Extras" })
	local vent = block(world, Vector3.new(8, 42, 8), CFrame.new(8, 39, 300), {
		name = "JumpVent",
		color = rgb(170, 220, 255),
		transparency = 0.8,
		collide = false,
		tags = { "JumpVent" },
		attrs = { Direction = -1 },
	})
	vent.CanQuery = false
	local button = platform(
		world,
		Vector3.new(5, 0.8, 5),
		-8,
		18.8,
		300,
		{ color = NEUTRAL, tags = { "VentButton" }, name = "VentButton" }
	)
	local link = Instance.new("ObjectValue")
	link.Name = "Vent"
	link.Value = vent
	link.Parent = button
	sign(world, "POUND TO FLIP THE FAN", CFrame.new(-8, 24, 304), Vector3.new(12, 3, 0.4))
	platform(world, Vector3.new(16, 4, 16), 8, 55, 320, { color = NAVY, name = "FanTop" })
	block(world, Vector3.new(8, 1, 8), CFrame.new(-8, 55, 320), { color = WHITE, name = "FanTopStep" })

	-- I: Duo Pound → gate G2
	platform(world, Vector3.new(30, 4, 40), 0, 30, 360, { color = NAVY, name = "DuoPoundRoom" })
	checkpoint(
		world,
		5,
		0,
		30,
		346,
		W,
		{ "That big button needs BOTH of you.", "Ground-pound it at the same time: count 3, 2, 1!" }
	)
	platform(
		world,
		Vector3.new(12, 1, 8),
		0,
		31,
		362,
		{ color = DUO, tags = { "DuoPound" }, attrs = { Group = "G2" }, name = "DuoPound" }
	)
	gate(world, "G2", Vector3.new(30, 16, 2), CFrame.new(0, 38, 379))

	-- J: Heavy Lever → gate G3 → exit
	platform(world, Vector3.new(30, 4, 30), 0, 30, 396, { color = NAVY, name = "LeverRoom" })
	local lever = block(
		world,
		Vector3.new(1, 5, 1),
		CFrame.new(-8, 32.5, 396),
		{ color = DUO, tags = { "HeavyLever" }, attrs = { Group = "G3" }, name = "HeavyLever" }
	)
	lever.CFrame *= CFrame.Angles(math.rad(20), 0, 0)
	gate(world, "G3", Vector3.new(30, 16, 2), CFrame.new(0, 38, 410))

	platform(world, Vector3.new(30, 4, 30), 0, 30, 426, { color = NAVY, name = "NewGame" })
	block(world, Vector3.new(12, 12, 3), CFrame.new(0, 36, 436), {
		name = "WorldExit",
		color = DUO,
		material = Enum.Material.Neon,
		transparency = 0.65,
		collide = false,
		tags = { "WorldExit" },
	})
	sign(world, "NEW GAME (both step in)", CFrame.new(0, 46, 436), Vector3.new(20, 4, 0.4))
end

-- Pixel Plains (World 1), Story Line sections 1-1 Starter Meadow, 1-2 Cloud Climb, 1-3 Coin Factory, then the
-- Glitch Chase set piece and the boss arena. Built to the reach table in CLAUDE.md (measured in Studio): plain
-- jump ≤ 10 studs, double jump 12–18, dash gaps 24–27, anything that needs a tool or the partner is ≥ 55 across
-- or ≥ 18 up, so dash + double jump can't skip a puzzle. Not one straight line: the meadow splits the duo into two
-- trials (Pillar 1: each needs the other's plate), the climb goes vertical and side-on, the factory stacks twists.
local function buildPixelPlains(world: Model)
	local W = "PixelPlains"
	killFloor(world, -40)
	workspace:SetAttribute("KillY", -60)
	local GRASS = Palette.PixelPlains.Grass
	local DIRT = Palette.PixelPlains.Dirt
	local METAL = rgb(120, 120, 130)
	local BELT = rgb(70, 70, 80)
	local NEON = Enum.Material.Neon

	-- Sections are built in their own coordinates, each with an entry and an exit point, then chained end to end
	-- (the next entry snaps to the previous exit), so new sections slot in without moving any numbers.
	-- Checkpoint orders count up in build order (= path order).
	local P: Instance = world
	local chunks: { { model: Model, entry: Vector3, exit: Vector3 } } = {}
	local function section(name: string, entry: Vector3, exit: Vector3)
		local m = Instance.new("Model")
		m.Name = name
		m.Parent = world
		P = m
		table.insert(chunks, { model = m, entry = entry, exit = exit })
	end
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end

	local function grass(size: Vector3, x: number, top: number, z: number, name: string?): Part
		return platform(P, size, x, top, z, { color = GRASS, name = name or "Grass" })
	end
	local function dirtWall(size: Vector3, x: number, top: number, z: number)
		platform(P, size, x, top, z, { color = DIRT, name = "DirtWall" })
	end
	-- a Freezable moving block (Kai's target) between two poses
	local function mover(name: string, size: Vector3, a: CFrame, b: CFrame, attrs: { [string]: any }): Part
		local m = block(P, size, a, { name = name, color = STONE, tags = { "Mover", "Freezable" }, attrs = attrs })
		waypoints(m, { a, b })
		return m
	end
	local function crusher(x: number, z: number, floorTop: number, attrs: { [string]: any })
		attrs.Damage = 1
		local up, down = CFrame.new(x, floorTop + 17, z), CFrame.new(x, floorTop + 4, z)
		local c = block(P, Vector3.new(12, 8, 10), up, {
			name = "PixelCrusher",
			color = METAL,
			material = Enum.Material.Metal,
			tags = { "Mover", "Freezable", "Hazard" },
			attrs = attrs,
		})
		waypoints(c, { up, down })
	end
	local function ring(x: number, y: number, z: number)
		block(P, Vector3.new(1, 3, 3), CFrame.new(x, y, z), { -- 2–3 studs (art-direction.md §17)
			name = "GrappleRing",
			color = MIKO,
			material = NEON,
			shape = Enum.PartType.Cylinder,
			tags = { "GrappleRing" },
		})
	end
	-- a hanging teal lever only Miko's Pull reaches
	local function pullLever(group: string, x: number, y: number, z: number)
		block(P, Vector3.new(1, 5, 1), CFrame.new(x, y, z) * CFrame.Angles(math.rad(20), 0, 0), {
			name = "PullLever",
			color = MIKO,
			material = NEON,
			tags = { "Pullable", "LeverPull" },
			attrs = { Group = group, Mass = 1 },
		})
	end
	local function plate(group: string, x: number, top: number, z: number, name: string?)
		platform(P, Vector3.new(6, 0.6, 6), x, top + 0.6, z, {
			color = NEUTRAL,
			tags = { "PressurePlate" },
			attrs = { Group = group },
			name = name or "Plate",
		})
	end
	-- a yellow lift / bridge that moves into place (and stays solid) when its group is active
	local function lift(group: string, size: Vector3, x: number, top: number, z: number, rise: number, name: string)
		platform(P, size, x, top, z, {
			name = name,
			color = NEUTRAL,
			tags = { "DuoGate" },
			-- no latch: pulling the lever again lowers it (InteractableService.Toggle)
			attrs = { Group = group, OpenOffset = Vector3.new(0, rise, 0), Solid = true, OpenTime = 2.5, Latch = false },
		})
	end
	-- a crank Station (StationService): hold E, forward / back drives the linked Driven movers; it glows in the color
	-- of the only player who can use it (art-direction.md §6)
	local function crank(owner: string, x: number, top: number, z: number, drives: { Instance })
		platform(P, Vector3.new(1.2, 3, 1.2), x, top + 3, z, { -- the post glows in its owner's color
			name = "CrankPost",
			color = if owner == "Kai" then KAI else MIKO,
			material = NEON,
		})
		local wheel = block(P, Vector3.new(0.6, 4, 4), CFrame.new(x, top + 4.5, z), {
			name = "Crank",
			color = if owner == "Kai" then KAI else MIKO,
			material = NEON,
			shape = Enum.PartType.Cylinder,
			collide = false,
			tags = { "Station" },
			attrs = { Owner = owner },
		})
		for _, d in drives do
			local link = Instance.new("ObjectValue")
			link.Name = "Drives"
			link.Value = d
			link.Parent = wheel
		end
	end
	local function conveyor(size: Vector3, x: number, top: number, z: number, speed: number)
		-- LookVector -Z: carries players back toward where they came from
		block(P, size, CFrame.new(x, top - size.Y / 2, z), {
			name = "Conveyor",
			color = BELT,
			material = Enum.Material.DiamondPlate,
			tags = { "Conveyor", "Freezable" },
			attrs = { Speed = speed },
		})
	end
	local function blob(x: number, top: number, z: number, patrol: number)
		block(P, Vector3.new(4, 3, 4), CFrame.new(x, top + 1.5, z), {
			name = "GlitchBlob",
			color = GLITCH,
			material = NEON,
			tags = { "Enemy", "Freezable" },
			attrs = { Type = "GlitchBlob", PatrolDistance = patrol, Speed = 5 },
		})
	end
	local function rail(a: Vector3, b: Vector3)
		block(P, Vector3.new(1, 1, (b - a).Magnitude), CFrame.lookAt((a + b) / 2, b), {
			color = rgb(170, 175, 190),
			material = Enum.Material.Metal,
			tags = { "GrindRail" },
			name = "GrindRail",
		})
	end
	local function exitPortal(x: number, top: number, z: number)
		block(P, Vector3.new(12, 12, 3), CFrame.new(x, top + 6, z), {
			name = "WorldExit",
			color = DUO,
			material = NEON,
			transparency = 0.65,
			collide = false,
			tags = { "WorldExit" },
		})
	end

	-- 1-1 STARTER MEADOW ----------------------------------------------------------------------------
	section("StarterMeadow", Vector3.zero, Vector3.new(0, 0, 210))
	grass(Vector3.new(60, 6, 40), 0, 0, 0, "StarterMeadow")
	spawnAt(P, 0, 0, -8)
	checkpoint(P, nextOrder(), 0, 0, -6, W, {
		"Split up! Kai takes the left trial, Miko the right. Each of you ends on a plate.",
		"Kai: freeze a rising pillar (left click) and hop on. Miko: grapple the teal rings (left click).",
	})
	sign(P, "▲ KAI TRIAL", CFrame.new(-20, 6, 16), Vector3.new(14, 3, 0.4)) -- no arrows: signs read from both sides
	sign(P, "MIKO TRIAL ●", CFrame.new(20, 6, 16), Vector3.new(14, 3, 0.4))

	-- Kai's trial (west): freeze pillars one at a time, then a corridor of fast crushers.
	grass(Vector3.new(30, 6, 12), -45, 0, 0, "KaiPath")
	grass(Vector3.new(30, 6, 30), -75, 0, 0, "KaiStart")
	for i, z in { 27, 43, 59 } do
		-- up (top flush with the ledges) ↔ 16 studs down; only one can be frozen at a time, so hop fast
		mover("MoveBlock", Vector3.new(8, 2, 8), CFrame.new(-75, -1, z), CFrame.new(-75, -17, z), {
			Period = 2.4,
			Offset = i * 0.8,
		})
	end
	grass(Vector3.new(30, 6, 30), -75, 0, 86, "KaiMid")
	grass(Vector3.new(14, 6, 40), -75, 0, 121, "CrusherLane")
	for _, x in { -83, -67 } do
		dirtWall(Vector3.new(2, 22, 40), x, 22, 121) -- too tall to climb around (reach ~16)
	end
	for i, z in { 104, 121, 138 } do -- 7-stud gaps between heads: room to stand between hits
		crusher(-75, z, 0, { Period = 1.4, Offset = (i - 1) * 0.45 })
	end
	block(P, Vector3.new(16, 2, 40), CFrame.new(-75, 22.5, 121), { -- no walking the crusher tops
		name = "FactoryRoof",
		color = METAL,
		material = Enum.Material.Metal,
	})
	grass(Vector3.new(30, 6, 30), -75, 0, 156, "KaiEnd")
	plate("S1", -75, 0, 162, "PlateKai")
	grass(Vector3.new(40, 6, 10), -40, 0, 160, "KaiReturn")
	gate(P, "S1", Vector3.new(2, 20, 10), CFrame.new(-24, 10, 160))

	-- Miko's trial (east): a 60-stud grapple chasm, a crate to climb an 18-stud cliff, a lever for a bridge.
	grass(Vector3.new(30, 6, 12), 45, 0, 0, "MikoPath")
	grass(Vector3.new(30, 6, 30), 75, 0, 0, "MikoStart")
	ring(75, 20, 32)
	ring(75, 20, 58)
	grass(Vector3.new(30, 6, 30), 75, 0, 90, "MikoMid")
	grass(Vector3.new(30, 24, 30), 75, 18, 120, "Cliff") -- the cliff: 18 up, only with the crate as a step
	platform(P, Vector3.new(6, 2, 6), 100, -6, 90, { color = DIRT, name = "CrateIsland" })
	block(P, Vector3.new(4, 4, 4), CFrame.new(100, -4, 90), {
		name = "Crate",
		color = WOOD,
		material = Enum.Material.WoodPlanks,
		anchored = false,
		tags = { "Pullable", "Respawn" },
		attrs = { Mass = 20 },
	})
	pullLever("M3", 75, 27, 163)
	lift("M3", Vector3.new(8, 1, 56), 75, -2, 163, 20, "Bridge") -- 56-stud pit: past long jump + double + dash (~51)
	grass(Vector3.new(30, 24, 20), 75, 18, 201, "Cliff")
	plate("S1", 75, 18, 201, "PlateMiko")
	local slope = math.atan2(18, 40)
	block(P, Vector3.new(44, 2, 10), CFrame.new(40, 9, 201) * CFrame.Angles(0, 0, slope) * CFrame.new(0, -1, 0), {
		color = GRASS,
		name = "Ramp",
	})
	gate(P, "S1", Vector3.new(2, 20, 10), CFrame.new(24, 10, 201))

	-- The plaza where the two trials meet.
	grass(Vector3.new(40, 6, 60), 0, 0, 180, "Plaza")
	checkpoint(P, nextOrder(), 0, 0, 168, W, {
		"Miko: grapple the ring up the cliff, then pull the teal lever for Kai.",
		"The yellow lift rises when Miko pulls the lever up top.",
	})
	-- 1-1 continued: WINDMILL HILL. The first combos, gently (mechanics.md §4 signature combos): Kai freezes a
	-- falling block in mid-air and Miko swings on it; Miko raises Kai's bridge; then a spinning windmill arm that
	-- Kai stops in line while Miko swings over it, and both plates to finish (split execution, finish with timing).
	section("WindmillHill", Vector3.zero, Vector3.new(0, 0, 215))
	grass(Vector3.new(14, 6, 30), 0, 0, 15, "MillPath")
	checkpoint(P, nextOrder(), 0, 0, 10, W, {
		"Kai: freeze a falling block in mid-air (left click). Miko: grapple it and swing across!",
		"Miko: pull the teal lever on the far side to raise Kai's bridge.",
	})
	sign(P, "WINDMILL HILL", CFrame.new(0, 9, 28), Vector3.new(16, 3, 0.4))
	-- a 65-stud chasm (z 30..95): nothing jumps it
	local millDropper = block(P, Vector3.new(6, 1, 6), CFrame.new(4, 34, 62), {
		name = "Dropper",
		transparency = 1,
		collide = false,
		tags = { "Dropper" },
		attrs = { Every = 2.4 },
	})
	millDropper.CanQuery = false
	grass(Vector3.new(30, 6, 30), 0, 0, 110, "MillFar")
	pullLever("T1", 8, 12, 118)
	lift("T1", Vector3.new(8, 1, 65), -10, -20, 62.5, 20, "Bridge")
	-- the windmill: a 46-stud arm spinning over a 50-stud pit; Kai freezes it pointing across, both run it
	local armCf = CFrame.new(0, -1, 150) * CFrame.Angles(0, math.rad(90), 0)
	local arm = block(P, Vector3.new(6, 2, 46), armCf, {
		name = "WindmillArm",
		color = STONE,
		tags = { "Mover", "Freezable" },
		attrs = { Spin = 36 },
	})
	waypoints(arm, { armCf })
	ring(0, 16, 150) -- Miko can swing over instead
	grass(Vector3.new(30, 6, 30), 0, 0, 190, "MillTop")
	checkpoint(P, nextOrder(), 0, 0, 184, W, {
		"Kai: freeze the windmill arm when it points across, then run!",
		"Both on the plates to open the gate.",
	})
	plate("T1b", -9, 0, 198)
	plate("T1b", 9, 0, 198)
	gate(P, "T1b", Vector3.new(30, 20, 2), CFrame.new(0, 10, 206))
	grass(Vector3.new(14, 6, 10), 0, 0, 212, "MillExit")

	-- 1-1 continued: SPRING YARD (obstacles.md 2.2). Two new jobs for the tools. Spring Snap: Release is a launcher.
	-- Kai freezes a pumping spring while it's squashed, Miko steps on, Kai releases and she's flung up a 26-stud
	-- cliff (a Release never launches the player releasing, so it can't be done alone); up top she pulls the lever
	-- for Kai's lift. Crank Ferry (operator and runner): a ferry crosses a chasm under a crusher only while someone
	-- holds a crank. Miko cranks Kai across while he freezes the crusher; then Kai cranks her over from his side.
	section("SpringYard", Vector3.zero, Vector3.new(0, 26, 200))
	grass(Vector3.new(14, 6, 20), 0, 0, 10, "YardPath")
	checkpoint(P, nextOrder(), 0, 0, 8, W, {
		"Kai: freeze the spring while it's squashed. Miko: stand on it. Kai: release (right click)!",
		"The spring launches whoever stands on it when Kai lets it go. Then Miko pulls the lever up top.",
	})
	sign(P, "SPRING YARD", CFrame.new(0, 9, 19), Vector3.new(16, 3, 0.4))
	grass(Vector3.new(40, 6, 30), 0, 0, 35, "Yard") -- z 20..50
	grass(Vector3.new(40, 6, 16), 0, -6, 58, "SpringPit") -- 6 deep: falling in is safe, the spring is the only way up
	-- the spring pumps between flush with the yard and 4 down; frozen low + released = a launch up the cliff
	local springUp, springDown = CFrame.new(0, -0.5, 56), CFrame.new(0, -4.5, 56)
	mover("SpringPad", Vector3.new(8, 1, 8), springUp, springDown, {
		Period = 1.1,
		LaunchVelocity = Vector3.new(0, Tuning.JumpVelocity(34), 20), -- lands ~6 onto the cliff top
	})
	platform(P, Vector3.new(40, 32, 30), 0, 26, 81, { color = GRASS, name = "Cliff" }) -- z 66..96, 26 up
	lift("SP1", Vector3.new(8, 1, 8), 16, 0.5, 54, 25.5, "Lift") -- Kai's ride once Miko pulls the lever
	pullLever("SP1", -14, 31, 72)
	checkpoint(P, nextOrder(), 0, 26, 86, W, {
		"Miko: hold E at the teal crank and press W to send the ferry. Kai: freeze the crusher as you go!",
		"Kai, call out when to stop. Then Kai cranks Miko over from the orange crank.",
	})

	-- the crank ferry: home against this cliff, out against the far one; it drifts home when nobody cranks
	local ferryHome, ferryOut = CFrame.new(0, 25.5, 102), CFrame.new(0, 25.5, 150)
	local ferry = block(P, Vector3.new(10, 1, 10), ferryHome, {
		name = "Ferry",
		color = NEUTRAL,
		tags = { "Mover" },
		attrs = { Driven = true, Period = 7, Ease = "Linear", ReturnRate = 0.5 }, -- 3.5 s across at full crank
	})
	waypoints(ferry, { ferryHome, ferryOut })
	crusher(0, 126, 26.5, { Period = 1.6 }) -- slams down to just over the ferry (no rigid-on-rigid fight)
	block(P, Vector3.new(16, 2, 14), CFrame.new(0, 26 + 22.5, 126), { -- the girder it hangs from
		name = "FactoryRoof",
		color = METAL,
		material = Enum.Material.Metal,
	})
	crank("Miko", -14, 26, 92, { ferry })
	grass(Vector3.new(40, 6, 30), 0, 26, 171, "FarCliff") -- z 156..186: a 60-stud chasm, nothing jumps it
	crank("Kai", -14, 26, 160, { ferry })
	checkpoint(P, nextOrder(), 0, 26, 176, W)
	plate("SP2", -9, 26, 182)
	plate("SP2", 9, 26, 182)
	gate(P, "SP2", Vector3.new(40, 20, 2), CFrame.new(0, 36, 187))
	grass(Vector3.new(14, 6, 12), 0, 26, 194, "YardExit")

	-- 1-2 CLOUD CLIMB -------------------------------------------------------------------------------
	section("CloudClimb", Vector3.new(0, 0, 210), Vector3.new(0, 62, 437))
	sign(P, "1-2 CLOUD CLIMB", CFrame.new(0, 10, 212), Vector3.new(18, 3, 0.4))
	grass(Vector3.new(30, 6, 30), 0, 0, 215, "CloudBase")
	grass(Vector3.new(30, 26, 30), 0, 20, 245, "Cliff") -- 20-stud cliff
	ring(0, 30, 224)
	lift("L1", Vector3.new(8, 1, 8), -10, 0.5, 225, 20, "Lift")
	pullLever("L1", -10, 23, 240)

	-- a fast cloud crossing a 60-stud chasm: Kai freezes it in line, both hop (24-stud jumps each side)
	mover("MoveBlock", Vector3.new(12, 2, 12), CFrame.new(-40, 19, 290), CFrame.new(40, 19, 290), {
		Period = 3.5,
		Ease = "Linear",
	})
	grass(Vector3.new(30, 26, 30), 0, 20, 335, "Cliff")
	checkpoint(P, nextOrder(), 0, 20, 328, W, {
		"Miko: ground-pound the white pad while Kai stands on it.",
		"Kai: freeze the bat up top so Miko can grapple it. Then pound the button to flip the fan.",
	})

	-- side-on climb: bounce pad (Miko launches Kai) + frozen bat (Kai gives Miko an anchor), then a fan
	local zone = block(P, Vector3.new(80, 90, 100), CFrame.new(0, 55, 388), {
		name = "SideOnZone",
		transparency = 1,
		collide = false,
		tags = { "CameraZone" },
		attrs = { Mode = "SideOn", Axis = Vector3.new(1, 0, 0) },
	})
	zone.CanQuery = false
	zone.CanTouch = false
	platform(P, Vector3.new(8, 1, 8), 0, 20.6, 344, {
		color = DUO,
		material = NEON,
		tags = { "BouncePad" },
		name = "BouncePad",
	})
	grass(Vector3.new(20, 4, 30), 0, 42, 369) -- ledge A: 22 up
	block(P, Vector3.new(3, 2, 3), CFrame.new(0, 50, 350) * CFrame.Angles(0, math.rad(90), 0), {
		name = "StaticBat",
		color = rgb(80, 70, 110),
		tags = { "Enemy", "Freezable" },
		attrs = { Type = "StaticBat", PatrolDistance = 12, Speed = 5 },
	})
	local vent = block(P, Vector3.new(8, 24, 8), CFrame.new(0, 54, 379), {
		name = "JumpVent",
		color = rgb(170, 220, 255),
		transparency = 0.8,
		collide = false,
		tags = { "JumpVent" },
		attrs = { Direction = -1 },
	})
	vent.CanQuery = false
	local button = platform(P, Vector3.new(5, 0.8, 5), 6, 42.8, 360, {
		color = NEUTRAL,
		tags = { "VentButton" },
		name = "VentButton",
	})
	local link = Instance.new("ObjectValue")
	link.Name = "Vent"
	link.Value = vent
	link.Parent = button
	grass(Vector3.new(20, 4, 16), 0, 62, 398) -- ledge B: 20 up, only on the fan
	grass(Vector3.new(30, 4, 30), 0, 62, 421, "SkyGate")
	platform(P, Vector3.new(12, 1, 8), 0, 63, 424, {
		color = DUO,
		tags = { "DuoPound" },
		attrs = { Group = "S2" },
		name = "DuoPound",
	})
	gate(P, "S2", Vector3.new(30, 20, 2), CFrame.new(0, 72, 436))
	checkpoint(P, nextOrder(), 0, 62, 412, W, {
		"Kai: freeze a belt so you can both walk up it. One at a time!",
		"Freeze the first belt, run, then freeze the second.",
	})

	-- 1-2 continued: CLOUD TOWER. Straight up: Kai freezes a fast elevator cloud at the top; Miko swings up a
	-- 22-stud wall and pulls the lever that lifts Kai ("Miko grapples up and drops ropes for Kai"); then a chasm
	-- where Miko swings ring to ring while Kai hops frozen clouds; a Heavy Lever for both at the top.
	section("CloudTower", Vector3.zero, Vector3.new(0, 42, 230))
	grass(Vector3.new(30, 4, 20), 0, 0, 10, "TowerPath")
	checkpoint(P, nextOrder(), 0, 0, 8, W, {
		"Kai: freeze the elevator cloud when it's up, then hop to the ledge.",
		"Ride it up, freeze it at the top.",
	})
	sign(P, "CLOUD TOWER", CFrame.new(0, 9, 19), Vector3.new(16, 3, 0.4))
	grass(Vector3.new(30, 4, 30), 0, 0, 35, "TowerBase")
	mover("MoveBlock", Vector3.new(10, 2, 10), CFrame.new(0, -1, 56), CFrame.new(0, 19, 56), { Period = 1.4 })
	grass(Vector3.new(30, 4, 20), 0, 20, 72, "Ledge") -- 20 up: only the frozen cloud reaches it
	ring(0, 52, 86) -- Miko swings up the next 22
	lift("C1", Vector3.new(8, 1, 8), 10, 20.5, 76, 22, "Lift") -- Kai's ride once Miko pulls the lever
	grass(Vector3.new(30, 4, 20), 0, 42, 100, "Ledge")
	pullLever("C1", -8, 52, 106)
	checkpoint(P, nextOrder(), 0, 42, 96, W, {
		"Miko: swing ring to ring. Kai: freeze a cloud in line, hop, freeze the next.",
		"Only one freeze at a time, Kai: hop fast!",
	})
	-- an 80-stud chasm (z 110..190)
	for _, z in { 126, 150, 174 } do
		ring(0, 56, z)
	end
	mover("MoveBlock", Vector3.new(12, 2, 12), CFrame.new(-26, 41, 132), CFrame.new(26, 41, 132), { Period = 3.2 })
	mover(
		"MoveBlock",
		Vector3.new(12, 2, 12),
		CFrame.new(26, 41, 168),
		CFrame.new(-26, 41, 168),
		{ Period = 3.2, Offset = 1.1 }
	)
	grass(Vector3.new(30, 4, 30), 0, 42, 205, "TowerTop")
	checkpoint(P, nextOrder(), 0, 42, 196, W, {
		"Pull the big lever together (hold E, both at once).",
		"Both of you hold the lever at the same time.",
	})
	local heavy = block(P, Vector3.new(1, 5, 1), CFrame.new(-8, 44.5, 212), {
		color = DUO,
		tags = { "HeavyLever" },
		attrs = { Group = "C2" },
		name = "HeavyLever",
	})
	heavy.CFrame *= CFrame.Angles(math.rad(20), 0, 0)
	gate(P, "C2", Vector3.new(30, 20, 2), CFrame.new(0, 52, 220))
	grass(Vector3.new(14, 4, 10), 0, 42, 225, "TowerExit")

	-- 1-2 continued: SWING WORKS (obstacles.md 2.2). Release as a launcher, twice more. Swing Cradle: a cradle swings
	-- out over a 56-stud chasm and back; Kai freezes it at the ledge, Miko steps in, Kai releases and she's thrown
	-- across, then pulls a crate onto the plate that raises Kai's drawbridge. Spin Cannon: a cannon turns on the far
	-- ledge; Kai freezes it pointing at the island (where it points is where she flies), Miko climbs on, Kai releases.
	section("SwingWorks", Vector3.zero, Vector3.new(0, 0, 250))
	grass(Vector3.new(14, 6, 20), 0, 0, 10, "WorksPath")
	checkpoint(P, nextOrder(), 0, 0, 8, W, {
		"Kai: freeze the cradle when it swings back to the ledge. Miko: step in. Kai: release it to throw her across!",
		"On the far side, Miko pulls the crate onto the plate to raise Kai's bridge.",
	})
	sign(P, "SWING WORKS", CFrame.new(0, 9, 19), Vector3.new(16, 3, 0.4))
	grass(Vector3.new(30, 6, 30), 0, 0, 35, "WorksLedge") -- z 20..50; the chasm runs z 50..106
	local cradleBack, cradleFront = CFrame.new(0, -0.5, 55), CFrame.new(0, -0.5, 85)
	mover("SwingCradle", Vector3.new(8, 1, 8), cradleBack, cradleFront, {
		Period = 3,
		LaunchVelocity = Vector3.new(0, Tuning.JumpVelocity(24), 62), -- ~61 studs: lands ~10 onto the far ledge
	})
	grass(Vector3.new(30, 6, 30), 0, 0, 121, "WorksFar") -- z 106..136
	block(P, Vector3.new(4, 4, 4), CFrame.new(9, 2, 128), {
		name = "Crate",
		color = WOOD,
		material = Enum.Material.WoodPlanks,
		anchored = false,
		tags = { "Pullable", "Respawn" },
		attrs = { Mass = 20 },
	})
	plate("SW1", -8, 0, 114)
	lift("SW1", Vector3.new(8, 1, 56), -10, -20, 78, 20, "Bridge") -- Kai's drawbridge, up while the crate holds it
	checkpoint(P, nextOrder(), 0, 0, 122, W, {
		"Kai: freeze the cannon when it points at the island. Miko: climb on. Kai: release!",
		"Where the cannon points when it's frozen is where Miko flies. Then she pulls the lever for Kai's bridge.",
	})
	-- the spin cannon: a turntable with a barrel, turning once every 6 s
	local cannon = Instance.new("Model")
	cannon.Name = "SpinCannon"
	local base = block(cannon, Vector3.new(8, 2, 8), CFrame.new(0, 1, 131), {
		name = "CannonBase",
		color = WOOD,
		material = Enum.Material.Wood,
	})
	local barrel = block(cannon, Vector3.new(2.4, 2.4, 6), CFrame.new(0, 3.2, 128), {
		name = "CannonBarrel",
		color = METAL,
		material = Enum.Material.Metal,
		collide = false,
	})
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = base
	weld.Part1 = barrel
	weld.Parent = barrel
	cannon.PrimaryPart = base
	for k, v in { Spin = 60, LaunchSpeed = 70, LaunchHeight = 30 } :: { [string]: number } do
		cannon:SetAttribute(k, v)
	end
	waypoints(cannon, { base.CFrame })
	CollectionService:AddTag(cannon, "Mover")
	CollectionService:AddTag(cannon, "Freezable")
	cannon.Parent = P
	-- the island: ~77 studs out along the cannon's aim, 59 past the ledge (no jump or dash reaches it)
	grass(Vector3.new(30, 6, 30), 0, 0, 210, "CannonIsland") -- z 195..225
	pullLever("SW2", 8, 8, 214)
	lift("SW2", Vector3.new(8, 1, 59), -10, -20, 165.5, 20, "Bridge")
	plate("SW3", -9, 0, 220)
	plate("SW3", 9, 0, 220)
	gate(P, "SW3", Vector3.new(30, 20, 2), CFrame.new(0, 10, 226))
	grass(Vector3.new(14, 6, 24), 0, 0, 238, "WorksExit") -- z 226..250

	-- 1-2 continued: SWITCH TOWERS (obstacles.md 2.2 Switch Blocks: split information + operator and runner). A
	-- 70-stud wall splits two climbs of retro ON/OFF blocks. ON blocks are solid only while their switch is on, OFF
	-- blocks only while it's off. Every safe pillar is 18 up from the last (past any jump), so each step needs the
	-- right flip. Kai's tower is flipped by Miko's teal lever on her side of the wall: she can't see his blocks, so
	-- he calls the flips. Up top the roles swap: Kai stands on / steps off a plate that flips Miko's tower, and he
	-- can't see hers. The last hop of each tower needs a flip while the climber is in the air.
	section("SwitchTowers", Vector3.zero, Vector3.new(0, 63, 146))
	grass(Vector3.new(14, 6, 20), 0, 0, 10, "TowerWalk")
	checkpoint(P, nextOrder(), 0, 0, 8, W, {
		"Kai climbs the left tower, Miko the right. ON blocks are solid only while their switch is on.",
		"Miko: pull the teal lever whenever Kai calls. Kai: up top, the plate flips Miko's blocks.",
	})
	sign(P, "SWITCH TOWERS", CFrame.new(0, 9, 19), Vector3.new(16, 3, 0.4))
	grass(Vector3.new(50, 6, 20), 0, 0, 30, "TowerYard") -- z 20..40
	dirtWall(Vector3.new(2, 76, 86), 0, 70, 63) -- z 20..106: neither climber sees the other tower
	sign(P, "▲ KAI", CFrame.new(-13, 6, 22), Vector3.new(8, 3, 0.4))
	sign(P, "MIKO ●", CFrame.new(13, 6, 22), Vector3.new(8, 3, 0.4))
	local function switchTower(group: string, x: number, axis: Vector3)
		local function switchBlock(phase: boolean, top: number, z: number)
			local b = platform(P, Vector3.new(6, 2, 6), x, top, z, {
				name = "SwitchBlock",
				color = if phase then Palette.PixelPlains.Gold else Palette.PixelPlains.Sky, -- both read against the dirt wall
				tags = { "SwitchBlock" },
				attrs = { Group = group, Phase = phase },
			})
			for _, face in { Enum.NormalId.Top, Enum.NormalId.Left, Enum.NormalId.Right } do -- the side-on camera looks along X
				local gui = Instance.new("SurfaceGui")
				gui.Face = face
				gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
				gui.PixelsPerStud = 30
				gui.LightInfluence = 0.3
				gui.Parent = b
				local label = Instance.new("TextLabel")
				label.Size = UDim2.fromScale(1, 1)
				label.BackgroundTransparency = 1
				label.Font = Enum.Font.Arcade
				label.TextScaled = true
				label.TextColor3 = Color3.new(1, 1, 1)
				label.TextStrokeTransparency = 0.4
				label.Text = if phase then "ON" else "OFF"
				label.Parent = gui
			end
		end
		switchBlock(true, 9, 46)
		grass(Vector3.new(8, 6, 8), x, 18, 56, "SwitchPillar")
		switchBlock(false, 27, 66)
		grass(Vector3.new(8, 6, 8), x, 36, 76, "SwitchPillar")
		switchBlock(true, 45, 86)
		switchBlock(false, 54, 96) -- the last hop: flip while the climber is in the air
		local zone = block(P, Vector3.new(24, 90, 70), CFrame.new(x, 35, 70), { -- side-on, from the open side
			name = "SideOnZone",
			transparency = 1,
			collide = false,
			tags = { "CameraZone" },
			attrs = { Mode = "SideOn", Axis = axis },
		})
		zone.CanQuery = false
		zone.CanTouch = false
	end
	switchTower("SB1", -13, Vector3.new(-1, 0, 0))
	switchTower("SB2", 13, Vector3.new(1, 0, 0))
	pullLever("SB1", 13, 2.5, 34) -- stands on Miko's side; the wall blocks her view and her Pull from Kai's side
	sign(P, "PULL = ON / OFF", CFrame.new(19, 6, 36), Vector3.new(10, 2.5, 0.4))
	grass(Vector3.new(50, 6, 30), 0, 63, 117, "TowerTop") -- z 102..132
	plate("SB2", -19, 63, 110, "PlateSwitch")
	sign(P, "STAND HERE = ON", CFrame.new(-19, 69, 114), Vector3.new(12, 2.5, 0.4))
	plate("SB3", -9, 63, 124)
	plate("SB3", 9, 63, 124)
	gate(P, "SB3", Vector3.new(50, 20, 2), CFrame.new(0, 73, 132))
	grass(Vector3.new(14, 6, 14), 0, 63, 139, "TowerExit") -- z 132..146
	checkpoint(P, nextOrder(), 0, 63, 140, W)

	-- 1-3 COIN FACTORY ------------------------------------------------------------------------------
	section("CoinFactory", Vector3.new(0, 62, 437), Vector3.new(0, 62, 747))
	local function factoryWalls(z0: number, z1: number)
		for _, x in { -8, 8 } do
			dirtWall(Vector3.new(2, 22, z1 - z0), x, 84, (z0 + z1) / 2)
		end
	end
	-- belts faster than sprint: freeze one, walk it, freeze the next
	-- 45 studs/s: faster than sprint + ground-dash spam; the low roof stops jump + air-dash hopping over them
	-- (playtest Oct 1: space + shift skipped the belts). Only Kai's freeze gets you through.
	conveyor(Vector3.new(14, 2, 30), 0, 62, 452, 45)
	conveyor(Vector3.new(14, 2, 30), 0, 62, 482, 45)
	factoryWalls(437, 497)
	block(P, Vector3.new(14, 2, 60), CFrame.new(0, 62 + 7.5 + 1, 467), {
		name = "FactoryRoof",
		color = METAL,
		material = Enum.Material.Metal,
	})
	grass(Vector3.new(30, 4, 24), 0, 62, 509, "BeltEnd")
	blob(0, 62, 512, 16)
	checkpoint(P, nextOrder(), 0, 62, 503, W, {
		"Kai: freeze a falling block over the pit. Miko: grapple it and swing across!",
		"Miko: pull the teal lever on the far side to raise the bridge for Kai.",
	})

	-- dropper pit: Kai freezes a falling block mid-air, Miko grapples it across, then pulls the bridge lever
	local dropper = block(P, Vector3.new(6, 1, 6), CFrame.new(0, 100, 551), {
		name = "Dropper",
		transparency = 1,
		collide = false,
		tags = { "Dropper" },
	})
	dropper.CanQuery = false
	lift("F2", Vector3.new(8, 1, 60), -10, 42, 551, 20, "Bridge")
	grass(Vector3.new(30, 4, 30), 0, 62, 596, "DropperFar")
	pullLever("F2", 8, 66, 588)
	checkpoint(P, nextOrder(), 0, 62, 600, W, {
		"Miko: pull the crate onto the plate. Kai: freeze the sliding door while it's open.",
		"The crate holds the inner gate; the door needs Kai's freeze.",
	})

	-- crate + plate + timed door
	grass(Vector3.new(30, 4, 45), 0, 62, 633.5, "DoorRoom")
	-- turned 90° so the part's X is the wall's thickness, like every other DirtWall (the art skin assumes it)
	local across = CFrame.Angles(0, math.rad(90), 0)
	for _, x in { -9.5, 9.5 } do
		block(P, Vector3.new(2, 20, 11), CFrame.new(x, 72, 651) * across, { color = DIRT, name = "DoorWall" })
	end
	block(P, Vector3.new(2, 8, 8), CFrame.new(0, 78, 651) * across, { color = DIRT, name = "DoorWall" })
	mover("TimedDoor", Vector3.new(8, 12, 1.5), CFrame.new(0, 68, 653), CFrame.new(-9, 68, 653), { Period = 3 })
	platform(P, Vector3.new(6, 1, 6), 12, 74, 620, { color = DIRT, name = "CrateShelf" })
	block(P, Vector3.new(4, 4, 4), CFrame.new(12, 76.5, 620), {
		name = "Crate",
		color = WOOD,
		material = Enum.Material.WoodPlanks,
		anchored = false,
		tags = { "Pullable", "Respawn" },
		attrs = { Mass = 20 },
	})
	plate("F3", -10, 62, 640)
	gate(P, "F3", Vector3.new(8, 12, 1), CFrame.new(0, 68, 655.5), false)

	-- twist: crushers over a backward belt, and Kai only has one freeze
	conveyor(Vector3.new(14, 2, 60), 0, 62, 686, 20)
	factoryWalls(656, 716)
	crusher(0, 674, 62, { Period = 1.6 })
	crusher(0, 698, 62, { Period = 1.6, Offset = 0.8 })
	block(P, Vector3.new(16, 2, 60), CFrame.new(0, 62 + 22.5, 686), { -- no walking the crusher tops
		name = "FactoryRoof",
		color = METAL,
		material = Enum.Material.Metal,
	})

	grass(Vector3.new(30, 4, 30), 0, 62, 731, "FactoryExit")
	blob(0, 62, 728, 14)
	plate("S3", -9, 62, 738)
	plate("S3", 9, 62, 738)
	gate(P, "S3", Vector3.new(30, 20, 2), CFrame.new(0, 72, 746))

	-- 1-3 continued: COIN PRESS. The twist: Glitch blobs pace a yard (Kai freezes one to slip past, frozen ones
	-- can't hurt), then the coin press: four crushers over a lane. Miko pulls the crate through in hops while Kai
	-- freezes the crusher above it; the crate on the plate opens the vault.
	section("CoinPress", Vector3.zero, Vector3.new(0, 0, 220))
	grass(Vector3.new(14, 4, 15), 0, 0, 7.5, "PressPath")
	checkpoint(P, nextOrder(), 0, 0, 6, W, {
		"Kai: freeze a Glitch blob to slip past it. Frozen blobs can't hurt you.",
		"Don't touch the magenta blobs!",
	})
	sign(P, "COIN PRESS", CFrame.new(0, 9, 14), Vector3.new(14, 3, 0.4))
	grass(Vector3.new(24, 4, 60), 0, 0, 45, "BlobYard") -- z 15..75
	for _, x in { -13, 13 } do
		dirtWall(Vector3.new(2, 22, 60), x, 22, 45)
	end
	blob(0, 0, 30, 18)
	blob(0, 0, 47, 18)
	blob(0, 0, 64, 18)
	grass(Vector3.new(14, 4, 100), 0, 0, 125, "PressLane") -- z 75..175
	for _, x in { -8, 8 } do
		dirtWall(Vector3.new(2, 22, 100), x, 22, 125)
	end
	-- roof just above the crushers' top position: no riding a head up and walking the tops (playtest Oct 1)
	block(P, Vector3.new(16, 2, 100), CFrame.new(0, 22.5, 125), {
		name = "FactoryRoof",
		color = METAL,
		material = Enum.Material.Metal,
	})
	checkpoint(P, nextOrder(), 0, 0, 80, W, {
		"Miko: pull the crate along the lane. Kai: freeze the crusher above it!",
		"The crate has to reach the plate at the end.",
	})
	-- 22 apart (12-stud gaps between the 10-deep heads): room for the crate plus one pull between two hits
	-- (playtest Oct 1: 4-stud gaps were too tight)
	for i, z in { 95, 117, 139, 161 } do
		crusher(0, z, 0, { Period = 1.3, Offset = (i - 1) * 0.33 })
	end
	block(P, Vector3.new(4, 4, 4), CFrame.new(0, 2, 82), {
		name = "Crate",
		color = WOOD,
		material = Enum.Material.WoodPlanks,
		anchored = false,
		tags = { "Pullable", "Respawn" },
		attrs = { Mass = 20 },
	})
	plate("D1", 0, 0, 170)
	gate(P, "D1", Vector3.new(14, 20, 2), CFrame.new(0, 10, 176))
	grass(Vector3.new(30, 4, 30), 0, 0, 192, "CoinVault") -- z 177..207
	checkpoint(P, nextOrder(), 0, 0, 188, W)
	sign(P, "COIN VAULT", CFrame.new(0, 10, 206), Vector3.new(14, 3, 0.4))
	grass(Vector3.new(14, 4, 13), 0, 0, 213.5, "VaultExit")

	-- GLITCH CHASE (set piece) ----------------------------------------------------------------------
	section("GlitchChase", Vector3.new(0, 62, 747), Vector3.new(0, 20, 1100))
	grass(Vector3.new(30, 4, 20), 0, 62, 756, "ChaseStart")
	checkpoint(P, nextOrder(), 0, 62, 752, W, {
		"RUN! Grab the rail (F) and jump the gaps!",
		"Keep moving. The Glitch eats everything behind you.",
	})
	rail(Vector3.new(0, 62.5, 770), Vector3.new(0, 50.5, 850))
	rail(Vector3.new(0, 46.5, 866), Vector3.new(-24, 36.5, 930))
	rail(Vector3.new(-24, 32.5, 946), Vector3.new(0, 22.5, 1004))
	local trigger = block(P, Vector3.new(30, 20, 20), CFrame.new(0, 70, 756), { -- the whole start platform
		name = "ChaseTrigger",
		transparency = 1,
		collide = false,
	})
	trigger.CanQuery = false
	trigger.CanTouch = false
	local wallStart = Vector3.new(0, 60, 722) -- 34 studs behind the start: ~1 s after the warm-up
	local glitchWall = block(P, Vector3.new(80, 80, 4), CFrame.lookAt(wallStart, wallStart + Vector3.zAxis), {
		name = "GlitchWall",
		color = GLITCH,
		material = NEON,
		transparency = 0.35,
		collide = false,
		tags = { "GlitchWall" },
		attrs = { Speed = 30, Distance = 282 },
	})
	glitchWall.CanQuery = false
	glitchWall.CanTouch = false
	local triggerLink = Instance.new("ObjectValue")
	triggerLink.Name = "Trigger"
	triggerLink.Value = trigger
	triggerLink.Parent = glitchWall

	-- BOSS ARENA (the Crusher King arrives with M6) ---------------------------------------------------
	grass(Vector3.new(30, 4, 30), 0, 20, 1023, "ChaseEnd")
	checkpoint(P, nextOrder(), 0, 20, 1016, W)
	grass(Vector3.new(60, 6, 60), 0, 20, 1075, "BossArena")
	exitPortal(0, 20, 1100)
	sign(P, "BOSS: THE CRUSHER KING (M6)", CFrame.new(0, 36, 1100), Vector3.new(24, 4, 0.4))

	-- chain: each section's entry snaps onto the previous section's exit
	local cursor = chunks[1].entry
	for _, c in chunks do
		local shift = cursor - c.entry
		c.model:SetAttribute("Shift", shift) -- ArtService moves the section's decor by the same amount
		if shift.Magnitude > 0 then
			c.model.WorldPivot = CFrame.new(c.entry)
			c.model:PivotTo(CFrame.new(cursor))
		end
		cursor = c.exit + shift
	end
end

-- Glitched Core (Story Line World 3; obstacles.md 2.4): the planning world. Kai builds (Copy/Paste), Miko sees the
-- Code Layer (Layer Shift) and has to say what's there. Built in chained sections like Pixel Plains. Every
-- checkpoint clears Kai's clipboard and pastes (CopyPaste), so each puzzle brings its own copy source.
--   3-1 MISSING TEXTURES: split trials (Kai leapfrogs two pastes over a void, Miko walks code stones only she can
--       stand on), then the Wire Circuit (sockets only Miko sees; only Kai's pastes power them).
--   3-2 THE WIRE MAZE: Ghost Bridge (Miko pulls a code plank out, Kai crosses and copies it, then pastes the copy
--       over the next void, which neither can cross alone), then Phantom Steps (steps solid on a 4-frame beat,
--       drawn only in the Code Layer: Miko calls the beat and the way, Kai jumps blind).
local function buildGlitchedCore(world: Model)
	local W = "GlitchedCore"
	killFloor(world, -40)
	workspace:SetAttribute("KillY", -60)
	local GREY = Palette.Core.Grey -- default-looking grey on purpose (art-direction.md §8); the void stays dark
	local DARK = Palette.Core.Dark
	local NEON = Enum.Material.Neon

	local P: Instance = world
	local chunks: { { model: Model, entry: Vector3, exit: Vector3 } } = {}
	local function section(name: string, entry: Vector3, exit: Vector3)
		local m = Instance.new("Model")
		m.Name = name
		m.Parent = world
		P = m
		table.insert(chunks, { model = m, entry = entry, exit = exit })
	end
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	local function floor(size: Vector3, x: number, top: number, z: number, name: string?): Part
		return platform(P, size, x, top, z, { color = GREY, name = name or "CoreBlock" })
	end
	local function wall(size: Vector3, x: number, top: number, z: number)
		platform(P, size, x, top, z, { color = DARK, name = "CoreWall" })
	end
	-- a Code Layer piece: only shifted Miko sees it and stands on it, until she pulls it out (LayerShift)
	local function code(size: Vector3, x: number, top: number, z: number, name: string): Part
		return platform(P, size, x, top, z, { color = MIKO, name = name, tags = { "CodeLayer" } })
	end
	-- real (solid for everyone) but drawn only in the Code Layer: wires, sockets, phantom steps, signs
	local function codeVisual(
		size: Vector3,
		cf: CFrame,
		name: string,
		tags: { string }?,
		attrs: { [string]: any }?
	): Part
		local list = { "CodeVisual" }
		for _, tag in tags or {} do
			table.insert(list, tag)
		end
		return block(P, size, cf, { color = MIKO, material = NEON, name = name, tags = list, attrs = attrs })
	end
	local function plate(group: string, x: number, top: number, z: number)
		platform(P, Vector3.new(6, 0.6, 6), x, top + 0.6, z, {
			color = NEUTRAL,
			tags = { "PressurePlate" },
			attrs = { Group = group },
			name = "Plate",
		})
	end
	-- a bridge that rises into place when its group is active (both trial plates)
	local function lift(group: string, size: Vector3, x: number, top: number, z: number, rise: number)
		platform(P, size, x, top, z, {
			name = "Bridge",
			color = NEUTRAL,
			tags = { "DuoGate" },
			attrs = { Group = group, OpenOffset = Vector3.new(0, rise, 0), Solid = true, OpenTime = 2.5 },
		})
	end
	local function copySource(size: Vector3, x: number, top: number, z: number, name: string)
		platform(P, size, x, top, z, { color = KAI, name = name, tags = { "Copyable" } })
	end

	-- 3-1 MISSING TEXTURES -------------------------------------------------------------------------
	section("MissingTextures", Vector3.zero, Vector3.new(0, 0, 262))
	floor(Vector3.new(40, 4, 30), 0, 0, 0, "MissingTextures")
	spawnAt(P, 0, 0, -8)
	checkpoint(P, nextOrder(), 0, 0, -6, W, {
		"Split up! Kai takes the left trial, Miko the right. Each of you ends on a plate.",
		"Kai: copy the orange block (left click), paste it ahead (hold right click). Miko: shift (left click) and walk the teal stones.",
	})
	sign(P, "3-1 MISSING TEXTURES", CFrame.new(0, 9, 14), Vector3.new(20, 3, 0.4))
	sign(P, "▲ KAI", CFrame.new(-20, 6, 16), Vector3.new(10, 3, 0.4))
	sign(P, "MIKO ●", CFrame.new(20, 6, 16), Vector3.new(10, 3, 0.4))

	-- Kai's trial: a 60-stud void and one long plank to copy. Only two pastes live at once: paste, hop, paste again
	-- (the oldest vanishes behind you). Two blocks of Glitch static hang in the way (playtest Oct 1: a straight
	-- line of pastes took 4 seconds), so he zigzags round them, turning the plank with R to fit the diagonals.
	floor(Vector3.new(20, 4, 25), -30, 0, 27.5, "KaiLedge") -- z 15..40
	copySource(Vector3.new(4, 1, 14), -36, 1, 30, "PlankBlock")
	for _, spot in { Vector3.new(-26, 0, 58), Vector3.new(-35, 0, 82) } do
		block(P, Vector3.new(14, 16, 6), CFrame.new(spot.X, 2, spot.Z), {
			name = "GlitchStatic",
			color = GLITCH,
			material = NEON,
			transparency = 0.25,
			tags = { "Hazard" },
			attrs = { Damage = 1 },
		})
	end
	floor(Vector3.new(20, 4, 20), -30, 0, 110, "KaiEnd") -- z 100..120
	plate("C1", -30, 0, 112)
	-- Miko's trial: code stones over the same void, only solid for her while she's shifted
	floor(Vector3.new(20, 4, 25), 30, 0, 27.5, "MikoLedge")
	for i, step in { { 28, 48 }, { 33, 59 }, { 28, 70 }, { 32, 81 }, { 28, 92 } } do
		code(Vector3.new(6, 1, 6), step[1], i * 0.8, step[2], "CodeStone")
	end
	floor(Vector3.new(20, 4, 20), 30, 0, 110, "MikoEnd")
	plate("C1", 30, 0, 112)
	-- both plates: two bridges rise over a 56-stud gap to the plaza (no jump, dash or paste-free way across)
	lift("C1", Vector3.new(8, 1, 56), -30, -20, 148, 20)
	lift("C1", Vector3.new(8, 1, 56), 30, -20, 148, 20)
	floor(Vector3.new(80, 4, 30), 0, 0, 191, "Plaza") -- z 176..206
	checkpoint(P, nextOrder(), 0, 0, 184, W, {
		"Miko: shift and look at the floor. Tell Kai where the two sockets are.",
		"Kai: copy the orange conductor and paste it onto each socket Miko finds. Only pastes power them.",
	})

	-- The Wire Circuit: a door wired to two sockets in the floor that only Miko can see; only pastes power them
	-- (players and crates don't), and Kai has exactly two pastes.
	floor(Vector3.new(40, 4, 40), 0, 0, 226, "CircuitRoom") -- z 206..246
	copySource(Vector3.new(4, 4, 4), 15, 4, 212, "Conductor")
	for _, at in { Vector3.new(-12, 0, 230), Vector3.new(9, 0, 239) } do
		codeVisual(Vector3.new(5, 0.3, 5), CFrame.new(at.X, 0.15, at.Z), "Socket", { "PressurePlate" }, {
			Group = "C2",
			PastedOnly = true,
		})
		-- the wire from the socket to the door, drawn flat on the floor
		local door = Vector3.new(0, 0.12, 246)
		local from = Vector3.new(at.X, 0.12, at.Z)
		local wire =
			codeVisual(Vector3.new(0.5, 0.1, (door - from).Magnitude), CFrame.lookAt((from + door) / 2, door), "Wire")
		wire.CanCollide = false
	end
	wall(Vector3.new(2, 20, 40), -21, 20, 226)
	wall(Vector3.new(2, 20, 40), 21, 20, 226)
	wall(Vector3.new(24, 20, 2), -18, 20, 247) -- the back wall runs 10 past the floor so nobody jumps round it
	wall(Vector3.new(24, 20, 2), 18, 20, 247)
	wall(Vector3.new(12, 6, 2), 0, 20, 247)
	gate(P, "C2", Vector3.new(12, 14, 2), CFrame.new(0, 7, 247))
	floor(Vector3.new(12, 4, 14), 0, 0, 255, "CircuitExit") -- z 248..262

	-- 3-1 twist: PASTE PAST THE DOOR (obstacles.md 2.4, P8 marker shortcut). A door opens while someone stands on
	-- its plate, and that plate only counts players: whoever holds it can't go through. Through the open door, only
	-- shifted Miko sees a second plate in the Code Layer. She pulls it out, Kai pastes his crate copy on it, and the
	-- pasted plate holds the door (AnyOf) so Miko can step off and follow. NoPaste volumes cover everything but the
	-- far room, so Kai can't paste stairs over the walls alone.
	section("PastePast", Vector3.zero, Vector3.new(0, 0, 97))
	floor(Vector3.new(24, 4, 41), 0, 0, 20.5, "DoorRoom") -- z 0..41
	checkpoint(P, nextOrder(), 0, 0, 5, W, {
		"Miko: stand on the plate to open the door, then shift and look through. Kai: copy the orange crate first!",
		"Miko: pull the hidden plate out (right click). Kai: paste the crate on it so the door stays open for her.",
	})
	sign(P, "DOOR.EXE (NOT RESPONDING)", CFrame.new(0, 18, 40), Vector3.new(20, 3, 0.4))
	copySource(Vector3.new(4, 4, 4), -8, 4, 14, "Crate")
	platform(P, Vector3.new(6, 0.6, 6), 3, 0.6, 30, {
		color = NEUTRAL,
		tags = { "PressurePlate" },
		attrs = { Group = "P1", PlayersOnly = true },
		name = "Plate",
	})
	wall(Vector3.new(2, 34, 84), -13, 30, 41) -- side walls z -1..83
	wall(Vector3.new(2, 34, 84), 13, 30, 41)
	wall(Vector3.new(9, 34, 2), -7.5, 30, 42) -- the door wall, door at x -3..3
	wall(Vector3.new(9, 34, 2), 7.5, 30, 42)
	wall(Vector3.new(6, 16, 2), 0, 30, 42)
	gate(P, "P1", Vector3.new(6, 14, 2), CFrame.new(0, 7, 42), false)
	local door = P:FindFirstChild("Gate_P1")
	if door then
		door:SetAttribute("AnyOf", "P1,P2") -- held by Miko on her plate, or by a paste on the code plate
	end
	floor(Vector3.new(24, 4, 40), 0, 0, 63, "FarRoom") -- z 43..83
	platform(P, Vector3.new(6, 0.6, 6), -4, 0.6, 58, { -- seen through the door from Miko's plate, 29 away
		color = MIKO,
		name = "CodePlate",
		tags = { "CodeLayer", "PressurePlate" },
		attrs = { Group = "P2", PastedOnly = true },
	})
	plate("P3", -6, 0, 76)
	plate("P3", 6, 0, 76)
	gate(P, "P3", Vector3.new(24, 20, 2), CFrame.new(0, 10, 84))
	floor(Vector3.new(12, 4, 14), 0, 0, 90, "PasteExit") -- z 83..97
	for _, zone in
		{
			{ Vector3.new(140, 120, 53), Vector3.new(0, 20, 15.5) }, -- the door room and all round it
			{ Vector3.new(57, 120, 42), Vector3.new(-41.5, 20, 63) }, -- either side of the far room
			{ Vector3.new(57, 120, 42), Vector3.new(41.5, 20, 63) },
			{ Vector3.new(26, 68, 42), Vector3.new(0, 50, 63) }, -- above it
		}
	do
		local z = block(P, zone[1], CFrame.new(zone[2]), { name = "NoPaste", transparency = 1, collide = false })
		z.CanQuery = false
		z.CanTouch = false
		CollectionService:AddTag(z, "NoPaste")
	end

	-- 3-2 THE WIRE MAZE ----------------------------------------------------------------------------
	section("WireMaze", Vector3.zero, Vector3.new(0, 0, 330))
	floor(Vector3.new(30, 4, 30), 0, 0, 15, "MazeStart") -- z 0..30
	checkpoint(P, nextOrder(), 0, 0, 12, W, {
		"Miko: shift, find the hidden plank and pull it out (right click) so Kai can cross.",
		"Kai: copy the plank while it's out, then paste it over the next gap. Neither of you crosses that one alone.",
	})
	sign(P, "3-2 THE WIRE MAZE", CFrame.new(0, 9, 4), Vector3.new(20, 3, 0.4))
	-- Ghost Bridge: a code plank over gap 1; gap 2 has none at all
	code(Vector3.new(10, 1, 56), 0, 0, 58, "GhostPlank") -- z 30..86
	floor(Vector3.new(24, 4, 24), 0, 0, 98, "Island") -- z 86..110
	floor(Vector3.new(30, 4, 30), 0, 0, 181, "MazeFar") -- z 166..196: gap 2 is 56 wide
	checkpoint(P, nextOrder(), 0, 0, 186, W, {
		"Miko: shift and watch the steps light up on the beat. Call it out: Kai can't see them!",
		"Each step stays solid for two beats. Hop with the beat, left and right as Miko says.",
	})
	-- Phantom Steps: six steps over a 70-stud void, each solid for two of four frames (consecutive steps overlap
	-- by one, so you hop every beat). Drawn only in the Code Layer, with a frame counter only Miko can read.
	for k = 1, 6 do
		local frames = `{(k - 1) % 4 + 1},{k % 4 + 1}`
		local x = if k % 2 == 1 then -5 else 5
		codeVisual(Vector3.new(7, 1, 7), CFrame.new(x, -0.5, 196 + k * 10), "PhantomStep", { "Blinker" }, {
			Frames = frames,
		})
	end
	local frameSign = codeVisual(Vector3.new(14, 4, 0.4), CFrame.new(0, 12, 199), "FrameSign", { "FrameSign" })
	frameSign.CanCollide = false
	local frameGui = Instance.new("SurfaceGui") -- the frame counter, written by ContraptionService
	frameGui.Face = Enum.NormalId.Front -- faces the players coming up the maze
	frameGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	frameGui.PixelsPerStud = 30
	local frameLabel = Instance.new("TextLabel")
	frameLabel.Size = UDim2.fromScale(1, 1)
	frameLabel.BackgroundTransparency = 1
	frameLabel.Font = signTheme.SignFont
	frameLabel.TextScaled = true
	frameLabel.TextColor3 = Palette.Core.Void
	frameLabel.Text = "FRAME 1"
	frameLabel.Parent = frameGui
	frameGui.Parent = frameSign
	floor(Vector3.new(30, 4, 30), 0, 0, 281, "MazeEnd") -- z 266..296
	checkpoint(P, nextOrder(), 0, 0, 275, W, {
		"Ground-pound the white button together!",
		"Both pound at the same time.",
	})
	platform(P, Vector3.new(12, 1, 8), 0, 1, 288, {
		color = DUO,
		tags = { "DuoPound" },
		attrs = { Group = "C3" },
		name = "DuoPound",
	})
	gate(P, "C3", Vector3.new(30, 20, 2), CFrame.new(0, 10, 297))
	floor(Vector3.new(40, 4, 30), 0, 0, 313, "CoreExit") -- z 298..328
	block(P, Vector3.new(12, 12, 3), CFrame.new(0, 6, 326), {
		name = "WorldExit",
		color = DUO,
		material = NEON,
		transparency = 0.65,
		collide = false,
		tags = { "WorldExit" },
	})
	sign(P, "3-3 MEMORY LANE + THE UNFINISHED (M6)", CFrame.new(0, 16, 326), Vector3.new(26, 3, 0.4))

	-- chain: each section's entry snaps onto the previous section's exit
	local cursor = chunks[1].entry
	for _, c in chunks do
		local shift = cursor - c.entry
		c.model:SetAttribute("Shift", shift)
		if shift.Magnitude > 0 then
			c.model.WorldPivot = CFrame.new(c.entry)
			c.model:PivotTo(CFrame.new(cursor))
		end
		cursor = c.exit + shift
	end
end

-- Starfall Castle, section 2-1 "Castle Gates" (Story Line, mechanics.md §4 World 2): top-down combat. Floors carry
-- the design (a rug path shows the way), walls are 6 studs so they never hide players (art-direction.md §8, §17).
local function enemy(parent: Instance, kind: string, x: number, z: number)
	local looks: { [string]: { Vector3 | Color3 } } = {
		Skeleton = { Vector3.new(3, 5, 2), rgb(230, 225, 210) },
		SplitSlime = { Vector3.new(4, 3, 4), rgb(120, 200, 90) },
		StaticArcher = { Vector3.new(3, 5, 2), rgb(170, 165, 200) },
		ShieldGuard = { Vector3.new(4, 6, 3), rgb(140, 145, 160) },
		StaticMage = { Vector3.new(3, 6, 3), Palette.Castle.Royal },
		IronGolem = { Vector3.new(6, 7, 5), rgb(85, 88, 100) },
	}
	local look = looks[kind]
	local size = look[1] :: Vector3
	local body = block(parent, size, CFrame.new(x, size.Y / 2, z), {
		name = kind,
		color = look[2] :: Color3,
		tags = { "Enemy" },
		attrs = { Type = kind },
	})
	if kind == "ShieldGuard" then
		local shield =
			block(body, Vector3.new(size.X + 1, size.Y - 1, 0.6), body.CFrame * CFrame.new(0, 0, -size.Z / 2 - 0.4), {
				name = "Shield",
				color = Palette.Castle.Gold,
				material = Enum.Material.Metal,
				anchored = false,
				collide = false,
			})
		shield.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = body
		weld.Part1 = shield
		weld.Parent = shield
	end
	return body
end

local function buildStarfallCastle(world: Model)
	local W = "StarfallCastle"
	killFloor(world, -40)
	workspace:SetAttribute("KillY", -60)
	local P = Palette.Castle
	local WALL_H = 6

	local function floor(x0: number, z0: number, x1: number, z1: number, name: string)
		platform(world, Vector3.new(x1 - x0, 2, z1 - z0), (x0 + x1) / 2, 0, (z0 + z1) / 2, {
			color = P.Stone,
			material = Enum.Material.Cobblestone,
			name = name,
		})
	end
	local function wall(x0: number, z0: number, x1: number, z1: number)
		local sx, sz = math.max(math.abs(x1 - x0), 1), math.max(math.abs(z1 - z0), 1)
		platform(world, Vector3.new(sx, WALL_H, sz), (x0 + x1) / 2, WALL_H, (z0 + z1) / 2, {
			color = P.NightPurple,
			material = Enum.Material.Slate,
			name = "Wall",
		})
	end
	-- warm wall torch: every room gets pools of warm light to aim for (art-direction.md §2 pillar 6, §8)
	local function torch(x: number, z: number)
		local holder = block(world, Vector3.new(1, 2, 1), CFrame.new(x, WALL_H + 1, z), {
			name = "Torch",
			color = P.Gold,
			material = Enum.Material.Metal,
			collide = false,
		})
		local flame = block(holder, Vector3.new(0.9, 1.2, 0.9), CFrame.new(x, WALL_H + 2.6, z), {
			name = "Flame",
			color = P.Torch,
			material = Enum.Material.Neon,
			collide = false,
		})
		flame.CanQuery = false
		local light = Instance.new("PointLight")
		light.Color = P.Torch
		light.Range = 22
		light.Brightness = 1.4
		light.Shadows = true
		light.Parent = flame
	end
	local function flatSign(text: string, x: number, z: number, w: number)
		sign(world, text, CFrame.new(x, 0.35, z) * CFrame.Angles(math.rad(-90), 0, 0), Vector3.new(w, 4, 0.4), P.Royal)
	end

	-- floors + the rug path that leads the way
	floor(-20, -20, 20, 20, "Gatehouse")
	floor(-7, 20, 7, 40, "Corridor")
	floor(-25, 40, 25, 90, "Barracks")
	floor(-25, 90, 25, 150, "Hall")
	floor(-10, 150, 10, 176, "CastleExit")
	platform(world, Vector3.new(6, 0.2, 170), 0, 0.1, 76, {
		color = P.Banner,
		material = Enum.Material.Fabric,
		collide = false,
		name = "Rug",
	})

	-- A: Gatehouse (start). Two skeletons to learn on.
	spawnAt(world, 0, 0, -12)
	checkpoint(world, 1, 0, 0, -6, W, {
		"Kai: hold left click to throw fireballs. Miko: left click swings your sword.",
		"Miko: hold right click to raise your shield. Enemies go for a raised shield.",
	})
	flatSign("STARFALL CASTLE", 0, 4, 22)
	wall(-20, -20, 20, -20)
	wall(-20, -20, -20, 20)
	wall(20, -20, 20, 20)
	wall(-20, 20, -7, 20)
	wall(7, 20, 20, 20)
	enemy(world, "Skeleton", -6, 15) -- > Combat.Aggro from the spawn: they wait until you walk up
	enemy(world, "Skeleton", 6, 16)
	for _, spot in { { -20, -8 }, { 20, -8 }, { -20, 10 }, { 20, 10 } } do
		torch(spot[1], spot[2])
	end

	-- B: Corridor. Braziers to practice Ignite, then a wooden door only fire opens.
	wall(-7, 20, -7, 40)
	wall(7, 20, 7, 40)
	for _, x in { -5, 5 } do
		block(world, Vector3.new(2, 3, 2), CFrame.new(x, 1.5, 26), {
			name = "Brazier",
			color = P.Gold,
			material = Enum.Material.Metal,
			tags = { "Brazier" },
		})
	end
	checkpoint(world, 2, 0, 0, 24, W, {
		"Kai: press E near a brazier or the wooden door.",
		"Burn the wooden door with Kai's Ignite (E).",
	})
	block(world, Vector3.new(12, WALL_H, 1), CFrame.new(0, WALL_H / 2, 37), {
		name = "WoodenDoor",
		color = rgb(150, 100, 60),
		material = Enum.Material.WoodPlanks,
		tags = { "Burnable" },
	})

	-- C: Barracks. A mixed wave.
	wall(-25, 40, -7, 40)
	wall(7, 40, 25, 40)
	wall(-25, 40, -25, 90)
	wall(25, 40, 25, 90)
	enemy(world, "Skeleton", -10, 55)
	enemy(world, "Skeleton", 10, 58)
	enemy(world, "Skeleton", 0, 66)
	enemy(world, "SplitSlime", -14, 70)
	enemy(world, "ShieldGuard", 4, 74)
	enemy(world, "StaticArcher", -16, 84)
	enemy(world, "StaticArcher", 16, 84)
	for _, spot in { { -25, 50 }, { 25, 50 }, { -25, 66 }, { 25, 66 }, { -25, 82 }, { 25, 82 } } do
		torch(spot[1], spot[2])
	end

	-- D: the split. Left: a cracked wall Miko charges through. Right: iron bars only Kai can blink through,
	-- with plate A behind them (the gate further on needs plate A and plate B at once).
	wall(-25, 90, -20, 90)
	block(world, Vector3.new(10, WALL_H, 2), CFrame.new(-15, WALL_H / 2, 90), {
		name = "CrackedWall",
		color = rgb(120, 110, 130),
		material = Enum.Material.Slate,
		tags = { "CrackedWall" },
	})
	wall(-10, 90, 10, 90)
	local bars = Instance.new("Model")
	bars.Name = "IronBars"
	for i = 0, 8 do
		block(bars, Vector3.new(0.4, WALL_H, 0.4), CFrame.new(10.6 + i * 1.1, WALL_H / 2, 90), {
			name = "Bar",
			color = rgb(90, 90, 100),
			material = Enum.Material.Metal,
		})
	end
	bars.Parent = world
	CollectionService:AddTag(bars, "IronBars")
	wall(20, 90, 25, 90)
	-- the alcove behind the bars (closed on every other side)
	wall(10, 90, 10, 100)
	wall(10, 100, 25, 100)
	platform(world, Vector3.new(4, 0.6, 4), 17, 0.6, 95, {
		color = NEUTRAL,
		tags = { "PressurePlate" },
		attrs = { Group = "C1" },
		name = "PlateA",
	})
	flatSign("SHIFT = BLINK", 15, 86, 10)

	-- E: Hall. The Static Mage and friends; gate C1 needs plate A (alcove) + plate B (here) held together.
	checkpoint(world, 3, -15, 0, 104, W, {
		"Kai: Shift blinks through the iron bars. Stand on the plate behind them.",
		"Both plates at once: one behind the bars, one in front of the gate.",
	})
	wall(-25, 90, -25, 150)
	wall(25, 100, 25, 150)
	wall(-25, 150, -7, 150)
	wall(7, 150, 25, 150)
	enemy(world, "StaticMage", 0, 130)
	enemy(world, "Skeleton", -12, 120)
	enemy(world, "Skeleton", 12, 124)
	enemy(world, "SplitSlime", 0, 118)
	for _, spot in
		{ { -25, 110 }, { 25, 112 }, { -25, 128 }, { 25, 128 }, { -25, 144 }, { 25, 144 }, { -10, 164 }, { 10, 164 } }
	do
		torch(spot[1], spot[2])
	end
	platform(world, Vector3.new(4, 0.6, 4), -12, 0.6, 144, {
		color = NEUTRAL,
		tags = { "PressurePlate" },
		attrs = { Group = "C1" },
		name = "PlateB",
	})
	gate(world, "C1", Vector3.new(14, WALL_H, 1), CFrame.new(0, WALL_H / 2, 150))

	-- F: the way on (the old exit corridor now leads into 2-2)
	wall(-10, 150, -10, 186)
	wall(10, 150, 10, 186)
	floor(-10, 176, 10, 186, "LibraryHall")

	-- 2-2 DARK LIBRARY (obstacles.md 2.3): built around the shield bouncing Kai's fire.
	-- a fire crystal (FireSwitch): orange takes Kai's own fireball, teal only a shot reflected off Miko's shield
	local function crystal(group: string, needs: string, x: number, z: number, window: number?)
		block(world, Vector3.new(2, 4, 2), CFrame.new(x, 3, z) * CFrame.Angles(0, math.rad(45), 0), {
			name = "Crystal",
			color = if needs == "Reflected" then MIKO else KAI,
			material = Enum.Material.Neon,
			tags = { "FireSwitch" },
			attrs = { Group = group, Needs = needs, Window = window },
		})
	end
	-- a silver mirror on a stand: bounces any shot off its face (CombatService)
	local function mirror(x: number, z: number, yaw: number)
		block(world, Vector3.new(6, 5, 0.6), CFrame.new(x, 3.5, z) * CFrame.Angles(0, math.rad(yaw), 0), {
			name = "Mirror",
			color = rgb(215, 225, 240),
			material = Enum.Material.Glass,
			tags = { "Mirror" },
		})
	end

	-- G: Ricochet Relay. The gate's crystal is teal: only Kai's fire bounced off Miko's raised shield lights it.
	floor(-25, 186, 25, 226, "ReadingRoom")
	checkpoint(world, 4, 0, 0, 192, W, {
		"The teal crystal only takes teal fire. Miko: raise your shield and face the crystal. Kai: shoot her shield!",
		"Kai's fireball bounces off Miko's shield the way she faces.",
	})
	flatSign("2-2 DARK LIBRARY", 0, 200, 18)
	wall(-25, 186, -10, 186)
	wall(10, 186, 25, 186)
	wall(-25, 186, -25, 226)
	wall(25, 186, 25, 226)
	wall(-25, 226, -7, 226)
	wall(14, 226, 25, 226) -- x 6..14: the roller hall's side passage (gate C4) opens off this room
	crystal("C2", "Reflected", 19, 220)
	gate(world, "C2", Vector3.new(14, WALL_H, 1), CFrame.new(0, WALL_H / 2, 226))
	enemy(world, "StaticArcher", -18, 216)
	enemy(world, "Skeleton", 14, 208)
	for _, spot in { { -25, 196 }, { 25, 196 }, { -25, 216 }, { 25, 216 } } do
		torch(spot[1], spot[2])
	end

	-- H: Spike Roller Hall. A spiked roller sweeps a narrow hall and stalls on Miko's raised shield. While she holds
	-- it, Kai blinks through it and stands on the plate at the far end, which opens the side passage for Miko.
	floor(-6, 226, 6, 288, "RollerHall")
	wall(-6, 226, -6, 288)
	wall(6, 228, 6, 288)
	floor(6, 226, 14, 288, "SidePassage") -- Miko's way round, behind a gate only Kai's plate opens
	wall(14, 226, 14, 288)
	gate(world, "C4", Vector3.new(8, WALL_H, 1), CFrame.new(10, WALL_H / 2, 227))
	platform(world, Vector3.new(4, 0.6, 4), 0, 0.6, 285, {
		color = NEUTRAL,
		tags = { "PressurePlate" },
		attrs = { Group = "C4" },
		name = "RollerPlate",
	})
	local rollerA, rollerB = CFrame.new(0, 3, 234), CFrame.new(0, 3, 280)
	local roller = block(world, Vector3.new(10, 4, 3), rollerA, {
		name = "SpikeRoller",
		color = Palette.Danger,
		material = Enum.Material.Metal,
		tags = { "Mover", "Hazard", "ShieldStop", "BlinkThrough" },
		attrs = { Period = 2.6, Damage = 25 },
	})
	waypoints(roller, { rollerA, rollerB })
	checkpoint(world, 5, 0, 0, 230, W, {
		"Miko: raise your shield and face the roller to stop it. Kai: blink through it (Shift) and stand on the plate.",
		"Kai's plate opens Miko's side passage. Miko: keep blocking until Kai is on it!",
	})
	torch(-6, 250)
	torch(6, 268)

	-- I: Mirror Gate. Two crystals lit together (1.5 s each): Kai's orange one straight, and a teal one hidden in a
	-- nook that only a reflected shot reaches, off the mirror in the corner.
	floor(-25, 288, 25, 340, "MirrorRoom")
	checkpoint(world, 6, 0, 0, 294, W, {
		"Light both crystals at once: Kai shoots the orange one, Miko bounces his fire off the mirror into the teal nook.",
		"Kai: fire twice fast. Once at the orange crystal, once at Miko's shield. Miko: aim your shield at the mirror.",
	})
	wall(-25, 288, -6, 288)
	wall(14, 288, 25, 288) -- the hall (x -6..6) and the side passage (x 6..14) both open into this room
	wall(-25, 288, -25, 340)
	wall(25, 288, 25, 340)
	wall(-25, 340, -7, 340)
	wall(7, 340, 25, 340)
	crystal("C3", "Direct", -18, 334, 1.5)
	-- the teal nook in the east wall: open only to the north, where the mirror bounces shots coming from the west
	wall(15, 300, 15, 318)
	wall(15, 300, 25, 300)
	crystal("C3", "Reflected", 20, 304, 1.5)
	mirror(20, 330, 45)
	gate(world, "C3", Vector3.new(14, WALL_H, 1), CFrame.new(0, WALL_H / 2, 340))
	enemy(world, "ShieldGuard", -8, 318)
	enemy(world, "SplitSlime", 6, 322)
	for _, spot in { { -25, 300 }, { -25, 324 }, { 25, 326 }, { -7, 340 } } do
		torch(spot[1], spot[2])
	end

	-- J: Torch Run (2-2, obstacles.md 2.3). A dark reading hall whose floor is spike traps except one winding path.
	-- A trap's red mark only shows within firelight, and these braziers burn out after a few seconds
	-- (Tuning.TorchRun). Miko walks the floor; Kai walks a gallery behind iron bars (only his Blink gets in) and keeps
	-- lighting the braziers ahead of her with Ignite (E reaches across the wall). Both plates open the way on.
	floor(-25, 340, 25, 410, "TorchHall")
	checkpoint(world, 7, 0, 0, 343, W, {
		"Miko walks the dark floor. Kai: blink into the gallery and keep the braziers lit ahead of her (E)!",
		"Red marks are spike traps. They only show near a lit brazier, and braziers burn out fast.",
	})
	wall(-25, 340, -25, 410)
	wall(25, 340, 25, 410)
	wall(-8, 346, -8, 404) -- Miko's lane: x -8..12
	wall(-25, 346, -8, 346)
	wall(12, 346, 12, 404) -- the gallery wall: Kai lights over it
	local function ironBars(x0: number, x1: number, z: number)
		local model = Instance.new("Model")
		model.Name = "IronBars"
		for x = x0 + 0.6, x1 - 0.4, 1.1 do
			block(model, Vector3.new(0.4, WALL_H, 0.4), CFrame.new(x, WALL_H / 2, z), {
				name = "Bar",
				color = rgb(90, 90, 100),
				material = Enum.Material.Metal,
			})
		end
		model.Parent = world
		CollectionService:AddTag(model, "IronBars")
	end
	ironBars(12, 25, 346) -- Kai's gallery, x 12..25
	ironBars(12, 25, 404)
	flatSign("SHIFT = BLINK", 18, 343, 10)
	-- the floor: 5 columns x 14 rows of 4-stud tiles; every tile off the path is a trap
	local path = { 0, 0, 1, 1, 0, 0, 1, 3, 4, 4, 3, 3, 4, 4 } -- the safe column per row
	local braziers = { [1] = true, [4] = true, [7] = true, [10] = true, [13] = true } -- rows with a brazier (col 2)
	for row = 0, 13 do
		local z = 348 + row * 4
		local c, nextC = path[row + 1], path[row + 2] or path[row + 1]
		for col = 0, 4 do
			local x = -6 + col * 4
			local onPath = col >= math.min(c, nextC) and col <= math.max(c, nextC)
			if braziers[row] and col == 2 then
				block(world, Vector3.new(2, 3, 2), CFrame.new(x, 1.5, z), {
					name = "Brazier",
					color = P.Gold,
					material = Enum.Material.Metal,
					tags = { "Brazier" },
					attrs = { BurnOut = true },
				})
			elseif onPath then
				-- the same tile without a trap, so the tile seams don't give the path away
				platform(world, Vector3.new(3.9, 0.2, 3.9), x, 0.1, z, {
					name = "SafeTile",
					color = P.Stone,
					material = Enum.Material.Cobblestone,
				})
			else
				local trap = platform(world, Vector3.new(3.9, 0.2, 3.9), x, 0.1, z, {
					name = "TrapTile",
					color = P.Stone,
					material = Enum.Material.Cobblestone,
					tags = { "Hazard", "FireTrap" },
					attrs = { Damage = Tuning.TorchRun.TrapDamage },
				})
				local mark = Instance.new("SurfaceGui")
				mark.Name = "Mark"
				mark.Face = Enum.NormalId.Top
				mark.Enabled = false -- CombatService shows it in firelight
				mark.LightInfluence = 0 -- the firelight would wash a lit mark out
				mark.Brightness = 2
				mark.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
				mark.PixelsPerStud = 30
				mark.Parent = trap
				-- a dark plate under the X so it reads on the bright orange floor (playtest: "too light")
				local back = Instance.new("Frame")
				back.AnchorPoint = Vector2.new(0.5, 0.5)
				back.Position = UDim2.fromScale(0.5, 0.5)
				back.Size = UDim2.fromScale(0.86, 0.86)
				back.BackgroundColor3 = Color3.fromRGB(40, 6, 10)
				back.BackgroundTransparency = 0.25
				back.Parent = mark
				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0.18, 0)
				corner.Parent = back
				local edge = Instance.new("UIStroke")
				edge.Color = Palette.Danger
				edge.Thickness = 4
				edge.Parent = back
				local label = Instance.new("TextLabel")
				label.Size = UDim2.fromScale(1, 1)
				label.BackgroundTransparency = 1
				label.Font = Enum.Font.GothamBlack
				label.TextScaled = true
				label.TextColor3 = Palette.Danger
				label.TextStrokeColor3 = Color3.new(0, 0, 0)
				label.TextStrokeTransparency = 0
				label.Text = "X" -- FredokaOne has no "✕" glyph (it rendered nothing)
				label.Parent = back
			end
		end
	end
	platform(world, Vector3.new(4, 0.6, 4), 18, 0.6, 399, {
		color = NEUTRAL,
		tags = { "PressurePlate" },
		attrs = { Group = "C6" },
		name = "GalleryPlate",
	})
	platform(world, Vector3.new(4, 0.6, 4), -4, 0.6, 407, {
		color = NEUTRAL,
		tags = { "PressurePlate" },
		attrs = { Group = "C6" },
		name = "TorchPlate",
	})
	wall(-25, 410, -7, 410)
	wall(7, 410, 25, 410)
	gate(world, "C6", Vector3.new(14, WALL_H, 1), CFrame.new(0, WALL_H / 2, 410))

	-- J: Golem Hall (2-3 opener; obstacles.md 2.3 Golem Lure). An iron golem nothing can hurt. Kai burns the wooden
	-- pillar braces (Ignite, E); Miko raises her shield to draw its charge and dodges (Dash) at the last moment, so it
	-- smashes the burned pillar behind her. The third pillar brings the ceiling down on it and opens the gate.
	floor(-10, 410, 10, 420, "GolemCorridor")
	wall(-10, 410, -10, 420)
	wall(10, 410, 10, 420)
	floor(-30, 420, 30, 480, "GolemHall")
	checkpoint(world, 8, 0, 0, 426, W, {
		"The golem can't be hurt. Kai: burn the pillars (E). Miko: shield up in front of a burned pillar, dash aside!",
		"Its charge smashes burned pillars. Break all three and the ceiling falls on it.",
	})
	wall(-30, 420, -10, 420)
	wall(10, 420, 30, 420)
	wall(-30, 420, -30, 480)
	wall(30, 420, 30, 480)
	wall(-30, 480, -7, 480)
	wall(7, 480, 30, 480)
	for _, spot in { { -18, 440 }, { 18, 448 }, { -4, 466 } } do
		block(world, Vector3.new(4, WALL_H + 4, 4), CFrame.new(spot[1], (WALL_H + 4) / 2, spot[2]), {
			name = "GolemPillar",
			color = KAI, -- Kai's target: burn it first
			material = Enum.Material.WoodPlanks,
			tags = { "GolemPillar" },
			attrs = { Group = "C5" },
		})
	end
	enemy(world, "IronGolem", 6, 470)
	local trigger = block(world, Vector3.new(1, 1, 1), CFrame.new(0, -5, 475), { -- fired when the golem falls
		name = "GolemTrigger",
		transparency = 1,
		collide = false,
		tags = { "FireSwitch" },
		attrs = { Group = "C5", GolemTrigger = true },
	})
	trigger.CanQuery = false
	gate(world, "C5", Vector3.new(14, WALL_H, 1), CFrame.new(0, WALL_H / 2, 480))
	for _, spot in { { -30, 432 }, { 30, 432 }, { -30, 462 }, { 30, 462 } } do
		torch(spot[1], spot[2])
	end

	-- exit
	floor(-10, 480, 10, 506, "CastleExit")
	wall(-10, 480, -10, 506)
	wall(10, 480, 10, 506)
	block(world, Vector3.new(12, 10, 3), CFrame.new(0, 5, 500), {
		name = "WorldExit",
		color = DUO,
		material = Enum.Material.Neon,
		transparency = 0.65,
		collide = false,
		tags = { "WorldExit" },
	})
	flatSign("BOSS: THE HOLLOW DRAGON (M6)", 0, 490, 16)
end

-- Everything else: an arena with the world's title and an exit, so the run can be tested end to end.
local function buildPlaceholder(world: Model, name: string)
	local info = Worlds.ByName[name]
	killFloor(world, -40)
	workspace:SetAttribute("KillY", -60)
	platform(world, Vector3.new(80, 4, 80), 0, 0, 0, { color = if info then info.Palette[1] else GREY, name = "Arena" })
	spawnAt(world, 0, 0, -20)
	checkpoint(world, 1, 0, 0, -20, name)
	sign(
		world,
		`{if info then info.Title else name}\n(grey-box coming soon)`,
		CFrame.new(0, 12, 20),
		Vector3.new(30, 8, 1)
	)
	block(world, Vector3.new(12, 12, 3), CFrame.new(0, 6, 36), {
		name = "WorldExit",
		color = DUO,
		material = Enum.Material.Neon,
		transparency = 0.65,
		collide = false,
		tags = { "WorldExit" },
	})
end

function Greybox.Build(worldName: string): Model
	signTheme = UiTheme.For(worldName)
	local world = Instance.new("Model")
	world.Name = "World"
	if worldName == "Prologue" then
		buildPrologue(world)
	elseif worldName == "PixelPlains" then
		buildPixelPlains(world)
	elseif worldName == "StarfallCastle" then
		buildStarfallCastle(world)
	elseif worldName == "GlitchedCore" then
		buildGlitchedCore(world)
	else
		buildPlaceholder(world, worldName)
	end
	return world
end

return Greybox
