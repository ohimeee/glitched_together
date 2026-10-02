-- Glitched Core art (Oct 2, 9th session). The level they never finished, as a REAL unfinished scale model
-- (memory realistic-ittakestwo-art): grey primer over cast concrete with the builders' pencil grid still on the
-- floor (Poly Haven CC0 + textures/make_core.py, MaterialVariants CoreFloor / CoreWall), bent steel-wire
-- armatures where things "should" be, and real props from a kid's desk: a beige CRT terminal, a film-projector
-- scanner, a brass balance hung on chains, a battery conductor, a floppy disk as the save point.
-- Blender kit (blender_assets/GlitchedCoreKit.blend → GC_SavePoint / GC_WireCube / GC_ScalePan .fbx) needs the
-- user's Import click; until its ids are filled in those skins load nothing and the grey-box stays.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)
local StateInlay = require(script.Parent.StateInlay)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)

local SMOOTH = Enum.Material.SmoothPlastic
local METAL = Enum.Material.Metal
local v = Vector3.new

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

local Skins: { [string]: MeshAssets.Skin } = {
	-- generated (Studio generate_mesh), realism-first prompts
	CoreTerminal = gen( -- beige CRT + keyboard, screen toward -Z (Kai's side)
		"rbxassetid://105378846685500",
		"rbxassetid://75737060485367",
		v(2.2, 2.63, 3.2),
		v(2.2, 2.63, 3.2)
	),
	ScannerSkin = gen( -- a film projector with two reels; its lens looks along the scanner's -Z (the cone)
		"rbxassetid://96154031693222",
		"rbxassetid://77533367049430",
		v(2, 2, 3),
		v(3, 2.7, 2)
	),
	ConductorSkin = gen( -- a chunky steel battery cell (Kai copies it, pastes power the sockets)
		"rbxassetid://92623284207058",
		"rbxassetid://121438920672609",
		v(4, 4, 4),
		v(3.4, 4, 3.4)
	),
}

-- Blender kit: filled from the imported MeshIds (Offsets in Roblox axes from each piece's bbox center)
local PLASTIC_DARK, STEEL, PAPER = Color3.fromHex("#3A3D44"), Color3.fromHex("#B9BDC4"), Color3.fromHex("#EDE8DA")
local STAND, WIRE, BASEWOOD, BRASS =
	Color3.fromHex("#5B5F67"), Color3.fromHex("#A7ABB2"), Color3.fromHex("#B58B5C"), Color3.fromHex("#B8913F")
local function kit(
	id: string,
	offset: Vector3,
	size: Vector3,
	material: Enum.Material,
	color: Color3
): MeshAssets.MeshInfo
	return { Id = id, Offset = offset, Size = size, Material = material, Color = color }
end
local KIT = {
	SavePoint = { -- a 3.5" floppy disk standing in a metal clip stand; front (label, shutter) faces -Z
		Design = v(5.8, 5.5, 1.6),
		Meshes = {
			Body = kit("rbxassetid://75639189184243", v(0, 0.15, 0), v(5, 5.2, 0.35), SMOOTH, PLASTIC_DARK),
			Label = kit("rbxassetid://84149193219149", v(0.15, 1.2, -0.01), v(4.1, 2.5, 0.37), SMOOTH, PAPER),
			ShutterL = kit("rbxassetid://97012726657325", v(0.675, -1.5, 0), v(1.45, 1.9, 0.39), METAL, STEEL),
			ShutterR = kit("rbxassetid://135102777080430", v(-1.075, -1.5, 0), v(0.65, 1.9, 0.39), METAL, STEEL),
			ShutterB = kit("rbxassetid://130914185156909", v(-0.4, -2.275, 0), v(0.7, 0.35, 0.39), METAL, STEEL),
			ShutterT = kit("rbxassetid://120687466852858", v(-0.4, -0.725, 0), v(0.7, 0.35, 0.39), METAL, STEEL),
			Stand = kit("rbxassetid://115379732701343", v(0, -2.6, 0), v(5.8, 0.3, 1.6), METAL, STAND),
			ClipF = kit("rbxassetid://138322880564162", v(0, -2.2, -0.275), v(5.4, 0.6, 0.15), METAL, STAND),
			ClipB = kit("rbxassetid://89144337421441", v(0, -2.2, 0.275), v(5.4, 0.6, 0.15), METAL, STAND),
		} :: { [string]: MeshAssets.MeshInfo },
	},
	WireCube = { -- hand-bent steel wire cube with twisted corners on a wooden base block
		Design = v(4.8, 4.74, 4.8),
		Meshes = {
			Wire = kit("rbxassetid://78705981496181", v(-0.002, 0.158, 0.028), v(4.316, 4.245, 4.324), METAL, WIRE),
			Knots = kit("rbxassetid://77035605949694", v(0.017, 0.138, 0.057), v(4.487, 4.466, 4.453), METAL, WIRE),
			Base = kit("rbxassetid://133761210726199", v(0, -2.121, 0), v(4.8, 0.5, 4.8), Enum.Material.Wood, BASEWOOD),
		} :: { [string]: MeshAssets.MeshInfo },
	},
	ScalePan = { -- a brass dish; its inner floor sits at the pan part's top (players stand there), lugs on the rim
		Design = v(10, 1, 10),
		Meshes = {
			Dish = kit("rbxassetid://72330904195126", v(0, 0.82, -0.013), v(10.1, 1, 10.1), METAL, BRASS),
			Lugs = kit("rbxassetid://131464620008906", v(0, 1.57, 1.11), v(9.117, 0.723, 7.905), METAL, BRASS),
		} :: { [string]: MeshAssets.MeshInfo },
	},
}
for name, skin in KIT do
	if next(skin.Meshes) then
		Skins[name] = skin :: any
	end
end

local Dressing: { [string]: string } = {
	Scanner = "ScannerSkin",
	Conductor = "ConductorSkin",
	PanA = "ScalePan",
	PanB = "ScalePan",
}

local function holder(name: string, size: Vector3, cf: CFrame, parent: Instance): Part
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

local GREY, DARK = Palette.Core.Grey, Palette.Core.Dark
local CHAIN = "rbxassetid://134572614401644" -- textures/make_corefx.py

-- the brass pans hang from the beam on three steel chains each (Beams follow the moving pans)
local function hangPans(world: Instance)
	for _, beam in world:GetDescendants() do
		if beam.Name ~= "ScaleBeam" or not beam:IsA("BasePart") then
			continue
		end
		local scale = beam.Parent and beam.Parent:FindFirstChild("Scale")
		for _, pan in (scale and scale:GetChildren() or {}) do
			if not (pan:IsA("BasePart") and (pan.Name == "PanA" or pan.Name == "PanB")) then
				continue
			end
			local side = if beam.CFrame:PointToObjectSpace(pan.Position).X < 0 then -1 else 1
			local top = Instance.new("Attachment")
			top.Position = v(side * 9, -beam.Size.Y / 2, 0)
			top.Parent = beam
			local r = pan.Size.X / 2
			for k = 0, 2 do
				local a = math.rad(90 + 120 * k)
				local lug = Instance.new("Attachment")
				-- on the dish's rim lugs (ScalePan: 1.57 up; Blender's x is mirrored in Roblox)
				lug.Position = v(-r * math.cos(a), 1.6, r * math.sin(a))
				lug.Parent = pan
				local chain = Instance.new("Beam")
				chain.Attachment0 = top
				chain.Attachment1 = lug
				chain.Texture = CHAIN
				chain.TextureMode = Enum.TextureMode.Static
				chain.TextureLength = 1.6
				chain.Width0 = 0.4
				chain.Width1 = 0.4
				chain.FaceCamera = true
				chain.LightInfluence = 1
				chain.Color = ColorSequence.new(Color3.fromRGB(200, 204, 212))
				chain.Segments = 1
				chain.Parent = pan
			end
		end
	end
end

-- the terminal: the CRT sits on its desk; the Station part (prompt) stays where it is, hidden, and an orange
-- outline marks the CRT as Kai's (art-direction §6: owner color on the interactable)
local function dressTerminal(world: Instance, apply: (BasePart, string) -> boolean)
	for _, desk in world:GetDescendants() do
		if desk.Name ~= "TerminalDesk" or not desk:IsA("BasePart") then
			continue
		end
		local size = Skins.CoreTerminal.Design
		local model = Instance.new("Model")
		model.Name = "TerminalArt"
		model.Parent = desk.Parent
		local crt = holder(
			"CRT",
			size,
			CFrame.new(desk.Position.X, desk.Position.Y + desk.Size.Y / 2 + size.Y / 2, desk.Position.Z - 0.4),
			model
		)
		if apply(crt, "CoreTerminal") then
			local terminal = desk.Parent and desk.Parent:FindFirstChild("Terminal")
			if terminal and terminal:IsA("BasePart") then
				terminal.Transparency = 1
			end
			local mark = Instance.new("Highlight")
			mark.Adornee = model
			mark.FillTransparency = 1
			mark.OutlineColor = Palette.Kai
			mark.OutlineTransparency = 0.2
			mark.DepthMode = Enum.HighlightDepthMode.Occluded
			mark.Parent = model
		else
			model:Destroy()
		end
	end
end

-- checkpoints: a floppy disk on a stand ("SAVE" in marker on its label) beside a faint pad
local function savePoints(world: Instance, apply: (BasePart, string) -> boolean)
	if not Skins.SavePoint then
		return
	end
	for _, pad in world:GetDescendants() do
		if not (pad:IsA("BasePart") and CollectionService:HasTag(pad, "Checkpoint")) then
			continue
		end
		pad.Transparency = 0.75
		local design = KIT.SavePoint.Design * 1.25
		local disk = holder(
			"SavePoint",
			design,
			pad.CFrame * CFrame.new(0, pad.Size.Y / 2 + design.Y / 2, pad.Size.Z / 2 - 1.2),
			pad.Parent or world
		)
		if not apply(disk, "SavePoint") then
			disk:Destroy()
			continue
		end
		local label = disk:FindFirstChild("Label")
		if label and label:IsA("BasePart") then
			local gui = Instance.new("SurfaceGui")
			gui.Face = Enum.NormalId.Front
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 40
			gui.LightInfluence = 1
			gui.Parent = label
			local text = Instance.new("TextLabel")
			text.Size = UDim2.fromScale(1, 1)
			text.BackgroundTransparency = 1
			text.Font = Enum.Font.PermanentMarker
			text.TextScaled = true
			text.TextColor3 = Color3.fromRGB(40, 50, 120)
			text.Rotation = -4
			text.Text = "SAVE"
			text.Parent = gui
		end
	end
end

-- unfinished-model dressing: hand-bent wire cubes on wooden bases at the far corners of the big floors (where
-- the builders meant to put something), never on the route's middle
local function wireCubes(world: Instance, apply: (BasePart, string) -> boolean)
	if not Skins.WireCube then
		return
	end
	local rng = Random.new(31)
	for _, floor in world:GetDescendants() do
		if
			not floor:IsA("BasePart")
			or floor:GetAttribute("CoreSurface") ~= "Floor"
			or floor.Size.X * floor.Size.Z < 900
		then
			continue
		end
		local hx, hz = floor.Size.X / 2 - 3.5, floor.Size.Z / 2 - 3.5
		local corner = rng:NextInteger(0, 3)
		local sx, sz = if corner % 2 == 0 then -1 else 1, if corner < 2 then -1 else 1
		local scale = rng:NextNumber(0.8, 1.3)
		local design = KIT.WireCube.Design * scale
		local cube = holder(
			"WireCube",
			design,
			floor.CFrame
				* CFrame.new(sx * hx, floor.Size.Y / 2 + design.Y / 2, sz * hz)
				* CFrame.Angles(0, math.rad(rng:NextNumber(-25, 25)), 0),
			floor.Parent or world
		)
		if not apply(cube, "WireCube") then
			cube:Destroy()
		end
	end
end

-- 3-3 Memory Lane: broken copies of the earlier worlds wear those worlds' real kits, faded toward the Core's grey
-- (art-direction §8: Glitch level 2, "players recognize them and feel how far they've come")
local FADE = Color3.fromRGB(190, 190, 196)
local function fade(part: BasePart)
	for _, shell in part:GetChildren() do
		if shell:IsA("MeshPart") then
			shell.Color = if shell.TextureID ~= "" then FADE else shell.Color:Lerp(GREY, 0.45)
		end
	end
end

local ECHO_SKINS = { -- section → { part name → skin }
	TitleEcho = { TitleStart = "UIPanel", TitleEnd = "UIPanel", TitleExit = "UIPanel" },
	PlainsEcho = {
		PlainsStart = "GrassBlock",
		PlainsFar = "GrassBlock",
		PlainsExit = "GrassBlock",
		PixelCrusher = "Crusher",
		PullLever = "PullLever",
	},
	CastleEcho = { Skeleton = "Skeleton", SplitSlime = "SplitSlime" },
}

local function dressEchoes(world: Instance, apply: (BasePart, string) -> boolean)
	for section, map in ECHO_SKINS do
		local model = world:FindFirstChild(section)
		if not model then
			continue
		end
		for _, part in model:GetDescendants() do
			local skin = part:IsA("BasePart") and map[part.Name]
			if skin and not part:GetAttribute("Skinned") and apply(part :: BasePart, skin) then
				fade(part :: BasePart)
			end
		end
		-- falling blocks spawn later: dress and fade them as they come
		model.DescendantAdded:Connect(function(d)
			if d.Name == "FallBlock" and d:IsA("BasePart") then
				task.defer(function()
					if d.Parent and apply(d, "FallBlock") then
						fade(d)
					end
				end)
			end
		end)
	end
	local castle = world:FindFirstChild("CastleEcho")
	for _, part in (castle and castle:GetDescendants() or {}) do
		if not part:IsA("BasePart") or part:GetAttribute("Skinned") then
			continue
		end
		if part.Material == Enum.Material.Cobblestone then
			part.MaterialVariant = "CastleFloor" -- the real castle flagstones, still in their faded color
		elseif part.Material == Enum.Material.Slate then
			part.MaterialVariant = "CastleWall"
		elseif part.Name == "Crystal" and apply(part, "CrystalTeal") then
			local light = Instance.new("PointLight")
			light.Color = Palette.Miko
			light.Range = 12
			light.Brightness = 2
			light.Enabled = part:GetAttribute("Active") == true
			light.Parent = part
			part:GetAttributeChangedSignal("Active"):Connect(function()
				light.Enabled = part:GetAttribute("Active") == true
			end)
		end
	end
end

local function Extras(world: Instance, apply: (BasePart, string) -> boolean)
	dressEchoes(world, apply) -- first, so the Core's own surfaces below skip the skinned echo floors
	for _, part in world:GetDescendants() do
		if not part:IsA("BasePart") or part:IsA("MeshPart") or part:GetAttribute("Skinned") then
			continue
		end
		if CollectionService:HasTag(part, "CodeLayer") or CollectionService:HasTag(part, "CodeVisual") then
			continue -- Code Layer pieces keep their teal look (CodeLayerController)
		end
		if part.Name == "CoreWall" then
			part.Material = Enum.Material.Concrete
			part.MaterialVariant = "CoreWall"
			part.Color = Color3.fromRGB(225, 227, 232) -- primer grey (the old dark grey read pitch black)
			part:SetAttribute("CoreSurface", "Wall")
		elseif part.Color == GREY and part.Material == SMOOTH and part.Transparency < 1 then
			part.Material = Enum.Material.Concrete
			part.MaterialVariant = "CoreFloor"
			part.Color = Color3.fromRGB(232, 233, 236)
			part:SetAttribute("CoreSurface", "Floor")
		elseif part.Name == "ScalePost" or part.Name == "ScaleBeam" then
			part.Material = METAL
			part.Color = Color3.fromRGB(214, 172, 84) -- brass, like the pans
		elseif part.Name == "TerminalDesk" then
			part.Material = Enum.Material.DiamondPlate
			part.Color = Color3.fromRGB(160, 163, 170)
		elseif part.Name == "Bridge" then
			part.Material = Enum.Material.WoodPlanks
			part.MaterialVariant = "CastlePlanks"
			part.Color = Color3.fromRGB(255, 222, 140) -- yellow-stained planks, like Pixel Plains' lever bridges
		elseif
			part.Name:match("^Gate_")
			and part.Material == Enum.Material.Neon
			and not part:GetAttribute("HideClosed") -- those stay invisible until they rise
		then
			-- an unfinished door: a white foam-board slab with the builders' note on it (white = both players)
			part.Material = SMOOTH
			part.Transparency = 0
			part.Color = Color3.fromRGB(240, 240, 236)
			for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
				local gui = Instance.new("SurfaceGui")
				gui.Face = face
				gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
				gui.PixelsPerStud = 20
				gui.LightInfluence = 1
				gui.Parent = part
				local note = Instance.new("TextLabel")
				note.AnchorPoint = Vector2.new(0.5, 0.5)
				note.Position = UDim2.fromScale(0.5, 0.45)
				note.Size = UDim2.fromScale(0.8, 0.3)
				note.BackgroundTransparency = 1
				note.Font = Enum.Font.PermanentMarker
				note.TextScaled = true
				note.TextColor3 = Color3.fromRGB(45, 45, 52)
				note.Rotation = -3
				note.Text = "TODO: DOOR"
				note.Parent = gui
			end
		elseif CollectionService:HasTag(part, "PressurePlate") and apply(part, "ButtonPad") then
			-- the same toy push button as Pixel Plains; an inlay shows held (green) / free (yellow)
			StateInlay(part)
		elseif part.Name == "PlankBlock" then
			part.Material = Enum.Material.WoodPlanks
			part.MaterialVariant = "CastlePlanks"
			part.Color = Color3.fromRGB(255, 165, 95) -- an orange-painted plank: still Kai's copy target
		elseif part.Color == DARK and part.Material == SMOOTH and part.Size.Y >= 1 then
			part.Material = Enum.Material.Concrete
			part.MaterialVariant = "CoreWall"
			part.Color = Color3.fromRGB(150, 152, 158)
		end
	end
	hangPans(world)
	dressTerminal(world, apply)
	savePoints(world, apply)
	wireCubes(world, apply)
end

return { Skins = Skins, Dressing = Dressing, Decor = {}, Extras = Extras }
