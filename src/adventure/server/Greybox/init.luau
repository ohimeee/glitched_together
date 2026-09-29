-- Grey-box worlds built from code, used until a real world exists in ServerStorage.Worlds.<Name>.
-- Every piece uses the same tags/attributes a Studio-built level would (implementation.md §4), so this
-- doubles as a working reference for level builders.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Worlds = require(ReplicatedStorage.Shared.Config.Worlds)

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
local WHITE = rgb(240, 240, 250)
local PINK = rgb(255, 80, 170)
local NAVY = rgb(40, 46, 96)
local ORANGE = rgb(255, 150, 40)
local YELLOW = rgb(255, 210, 60)
local BLUE = rgb(90, 170, 255)
local GREEN = rgb(60, 255, 120)

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

local function sign(parent: Instance, text: string, cf: CFrame, size: Vector3?, color: Color3?): Part
	local s =
		block(parent, size or Vector3.new(24, 6, 0.6), cf, { color = color or NAVY, name = "Sign", collide = false })
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.LightInfluence = 0
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 30
		gui.Parent = s
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = WHITE
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
		color = WHITE,
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
		color = PINK,
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
		platform(world, Vector3.new(10, 4, 10), 0, top, 14 + i * 14, { color = WHITE, name = `MenuButton{i}` })
	end

	-- "Options slider": needs double jump + dash
	platform(world, Vector3.new(20, 4, 20), 0, 11, 85, { color = NAVY, name = "OptionsSlider" })
	platform(
		world,
		Vector3.new(3, 1.2, 20),
		0,
		11.6,
		85,
		{ color = PINK, material = Enum.Material.Neon, collide = false }
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
			color = ORANGE,
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
	block(world, Vector3.new(2.5, 2.5, 2.5), CFrame.new(0, 48, 139), {
		color = ORANGE,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		tags = { "SwingPoint" },
		name = "SwingPoint",
	})
	platform(world, Vector3.new(20, 4, 20), 0, 31, 160, { color = NAVY, name = "SaveSlots" })

	-- Grind rail down to E
	local railStart = Vector3.new(0, 31.5, 172)
	local railEnd = Vector3.new(0, 20.5, 232)
	local rail = block(
		world,
		Vector3.new(1, 1, (railEnd - railStart).Magnitude),
		CFrame.lookAt((railStart + railEnd) / 2, railEnd),
		{
			color = WHITE,
			material = Enum.Material.Metal,
			tags = { "GrindRail" },
			name = "GrindRail",
		}
	)
	rail.CFrame = CFrame.lookAt((railStart + railEnd) / 2, railEnd)
	sign(world, "F to grind", CFrame.new(6, 36, 168), Vector3.new(8, 2.5, 0.4))

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
		{ color = GREEN, material = Enum.Material.Neon, tags = { "BouncePad" }, name = "BouncePad" }
	)
	platform(world, Vector3.new(14, 4, 14), -8, 40, 282, { color = NAVY, name = "HighLedge" })
	platform(
		world,
		Vector3.new(6, 0.6, 6),
		-8,
		40.6,
		284,
		{ color = YELLOW, tags = { "PressurePlate" }, attrs = { Group = "G1" }, name = "PlateHigh" }
	)
	platform(
		world,
		Vector3.new(6, 0.6, 6),
		9,
		18.6,
		262,
		{ color = YELLOW, tags = { "PressurePlate" }, attrs = { Group = "G1" }, name = "PlateLow" }
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
		{ color = rgb(255, 60, 60), tags = { "VentButton" }, name = "VentButton" }
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
		{ color = rgb(255, 60, 60), tags = { "DuoPound" }, attrs = { Group = "G2" }, name = "DuoPound" }
	)
	gate(world, "G2", Vector3.new(30, 16, 2), CFrame.new(0, 38, 379))

	-- J: Heavy Lever → gate G3 → exit
	platform(world, Vector3.new(30, 4, 30), 0, 30, 396, { color = NAVY, name = "LeverRoom" })
	local lever = block(
		world,
		Vector3.new(1, 5, 1),
		CFrame.new(-8, 32.5, 396),
		{ color = YELLOW, tags = { "HeavyLever" }, attrs = { Group = "G3" }, name = "HeavyLever" }
	)
	lever.CFrame *= CFrame.Angles(math.rad(20), 0, 0)
	gate(world, "G3", Vector3.new(30, 16, 2), CFrame.new(0, 38, 410))

	platform(world, Vector3.new(30, 4, 30), 0, 30, 426, { color = NAVY, name = "NewGame" })
	block(world, Vector3.new(12, 12, 3), CFrame.new(0, 36, 436), {
		name = "WorldExit",
		color = PINK,
		material = Enum.Material.Neon,
		transparency = 0.4,
		collide = false,
		tags = { "WorldExit" },
	})
	sign(world, "NEW GAME (both step in)", CFrame.new(0, 46, 436), Vector3.new(20, 4, 0.4))
end

-- Pixel Plains: Pause Beam / Grapple Line playground.
local function buildPixelPlains(world: Model)
	local W = "PixelPlains"
	killFloor(world, -40)
	workspace:SetAttribute("KillY", -60)
	local GRASS = rgb(88, 200, 72)
	local DIRT = rgb(150, 100, 60)

	platform(world, Vector3.new(40, 6, 40), 0, 0, 0, { color = GRASS, name = "StarterMeadow" })
	spawnAt(world, 0, 0, -8)
	checkpoint(world, 1, 0, 0, 0, W, {
		"Kai: freeze the moving platform (left click) when it's close.",
		"Miko: grapple rings glow orange. Left click near one.",
	})

	-- 1. Freeze a moving platform over a pit
	local mover = block(world, Vector3.new(10, 2, 10), CFrame.new(0, -1, 30), {
		name = "MovingPlatform",
		color = BLUE,
		tags = { "Mover", "Freezable" },
		attrs = { Period = 5 },
	})
	waypoints(mover, { CFrame.new(0, -1, 26), CFrame.new(0, -1, 74) })
	platform(world, Vector3.new(30, 6, 40), 0, 0, 100, { color = GRASS, name = "CrusherLane" })
	checkpoint(
		world,
		2,
		0,
		0,
		86,
		W,
		{ "Freeze the crusher when it's at the top.", "Kai freezes, then BOTH run under." }
	)

	-- 2. Crusher (hazard) between walls
	for _, x in { -6, 6 } do
		platform(world, Vector3.new(2, 14, 14), x, 14, 104, { color = DIRT })
	end
	local crusher = block(world, Vector3.new(9, 8, 12), CFrame.new(0, 14, 104), {
		name = "PixelCrusher",
		color = rgb(120, 120, 130),
		material = Enum.Material.Metal,
		tags = { "Mover", "Freezable", "Hazard" },
		attrs = { Period = 2.5, Damage = 1 },
	})
	waypoints(crusher, { CFrame.new(0, 17, 104), CFrame.new(0, 4, 104) })

	-- 3. Grapple ring + a slow ferry for Kai
	block(world, Vector3.new(1, 6, 6), CFrame.new(0, 22, 135), {
		name = "GrappleRing",
		color = ORANGE,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Cylinder,
		tags = { "GrappleRing" },
	})
	local ferry = block(world, Vector3.new(8, 2, 8), CFrame.new(10, -1, 130), {
		name = "Ferry",
		color = BLUE,
		tags = { "Mover", "Freezable" },
		attrs = { Period = 8 },
	})
	waypoints(ferry, { CFrame.new(10, -1, 124), CFrame.new(10, -1, 146) })
	platform(world, Vector3.new(34, 6, 36), 0, 0, 168, { color = GRASS, name = "CoinFactory" })
	checkpoint(world, 3, 0, 0, 156, W, {
		"Miko: right click pulls yellow things.",
		"Pull the crate onto the plate, the door stays open while it's there.",
	})

	-- 4. Pull a crate onto a plate → door stays open while it's held
	block(world, Vector3.new(4, 4, 4), CFrame.new(-10, 2, 172), {
		name = "Crate",
		color = YELLOW,
		material = Enum.Material.WoodPlanks,
		anchored = false,
		tags = { "Pullable" },
		attrs = { Mass = 20 },
	})
	platform(
		world,
		Vector3.new(6, 0.6, 6),
		10,
		0.6,
		176,
		{ color = YELLOW, tags = { "PressurePlate" }, attrs = { Group = "W1A" }, name = "Plate" }
	)
	gate(world, "W1A", Vector3.new(34, 14, 2), CFrame.new(0, 7, 185), false)

	-- A glitch blob to stomp
	block(world, Vector3.new(4, 3, 4), CFrame.new(0, 1.5, 164), {
		name = "GlitchBlob",
		color = PINK,
		material = Enum.Material.Neon,
		tags = { "Enemy", "Freezable" },
		attrs = { Type = "GlitchBlob", PatrolDistance = 16, Speed = 5 },
	})

	platform(world, Vector3.new(30, 6, 30), 0, 0, 202, { color = GRASS, name = "Exit" })
	block(world, Vector3.new(12, 12, 3), CFrame.new(0, 6, 212), {
		name = "WorldExit",
		color = PINK,
		material = Enum.Material.Neon,
		transparency = 0.4,
		collide = false,
		tags = { "WorldExit" },
	})
	sign(world, "BOSS: THE CRUSHER KING (M6)", CFrame.new(0, 16, 212), Vector3.new(24, 4, 0.4))
end

-- Glitched Core: a tiny Code Layer + Copy/Paste demo.
local function buildGlitchedCore(world: Model)
	local W = "GlitchedCore"
	killFloor(world, -40)
	workspace:SetAttribute("KillY", -60)
	local DARK = rgb(40, 40, 46)
	platform(world, Vector3.new(40, 4, 40), 0, 0, 0, { color = DARK, name = "MissingTextures" })
	spawnAt(world, 0, 0, -8)
	checkpoint(world, 1, 0, 0, 0, W, {
		"Miko: left click to see the Code Layer.",
		"Miko pulls the hidden bridge out (right click). Kai copies and pastes it.",
	})

	-- Hidden bridge piece only Miko sees until pulled out.
	block(world, Vector3.new(10, 1, 14), CFrame.new(0, -0.5, 28), {
		name = "HiddenBridge",
		color = GREEN,
		tags = { "CodeLayer" },
	})
	block(
		world,
		Vector3.new(4, 4, 4),
		CFrame.new(12, 2, 8),
		{ name = "CopyCrate", color = WHITE, tags = { "Copyable" } }
	)
	platform(world, Vector3.new(30, 4, 30), 0, 0, 60, { color = DARK, name = "WireMaze" })
	block(world, Vector3.new(12, 12, 3), CFrame.new(0, 6, 70), {
		name = "WorldExit",
		color = PINK,
		material = Enum.Material.Neon,
		transparency = 0.4,
		collide = false,
		tags = { "WorldExit" },
	})
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
		color = PINK,
		material = Enum.Material.Neon,
		transparency = 0.4,
		collide = false,
		tags = { "WorldExit" },
	})
end

function Greybox.Build(worldName: string): Model
	local world = Instance.new("Model")
	world.Name = "World"
	if worldName == "Prologue" then
		buildPrologue(world)
	elseif worldName == "PixelPlains" then
		buildPixelPlains(world)
	elseif worldName == "GlitchedCore" then
		buildGlitchedCore(world)
	else
		buildPlaceholder(world, worldName)
	end
	return world
end

return Greybox
