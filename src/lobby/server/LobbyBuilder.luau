-- Builds the lobby (platform + 6 capsule pairs) if the place doesn't already have one.
-- Capsules use the Blender meshes (CapsuleMeshes); if they can't load, it falls back to grey-box parts.
-- Once you build a real lobby in Studio (same names and the CapsulePair tag), this does nothing.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roles = require(ReplicatedStorage.Shared.Config.Roles)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)
local CapsuleMeshes = require(script.Parent.CapsuleMeshes)
local Worlds = require(ReplicatedStorage.Shared.Config.Worlds)
local LobbyRoom = require(script.Parent.LobbyRoom)
local LobbyProps = require(script.Parent.LobbyProps)
local LobbyKit = require(script.Parent.LobbyKit)

local PAIRS = 6
local RING_RADIUS = 40
local RING_CENTER = Vector3.new(0, 0, -14) -- the front of the desk; the back strip holds the monitor and the lamp

-- the A-frame chalkboard sign in the ring (tools/lobby_kit/sign.py: HINGE, SPREAD, W, H, BOARD_AT)
local CHALK = "rbxassetid://93825968961017" -- textures/lobby_chalk.png
local SIGN = { Hinge = Vector3.new(0, 22, -14), Spread = 6, W = 16, H = 17, BoardAt = 11 }

-- One board's centre; LookVector points out of the board (side -1 = the front, facing the spawn).
local function signPanel(side: number): CFrame
	local hinge = SIGN.Hinge
	local foot = Vector3.new(0, 0, hinge.Z + side * SIGN.Spread)
	local down = (foot - hinge).Unit
	local right = if side < 0 then Vector3.xAxis else -Vector3.xAxis
	return CFrame.fromMatrix(hinge + down * SIGN.BoardAt, right, -down)
end

local LobbyBuilder = {}

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

local function label(parent: Instance, face: Enum.NormalId, text: string, color: Color3, name: string?): TextLabel
	local gui = Instance.new("SurfaceGui")
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.LightInfluence = 0
	gui.Parent = parent
	local t = Instance.new("TextLabel")
	t.Name = name or "Label"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = color
	t.Text = text
	t.Parent = gui
	return t
end

local function capsule(name: string, cf: CFrame, color: Color3, roleLabel: string, shape: string): Model
	local m = Instance.new("Model")
	m.Name = name

	-- floor disc
	part({
		Name = "Base",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1, 9, 9),
		CFrame = cf * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(40, 40, 55),
		Parent = m,
	})
	-- glowing ring on the floor
	part({
		Name = "Ring",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.2, 7.6, 7.6),
		CFrame = cf * CFrame.new(0, 1.05, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = m,
	})
	-- back wall and pillars (front stays open toward the lobby center)
	part({
		Name = "Back",
		Size = Vector3.new(8, 10, 0.6),
		CFrame = cf * CFrame.new(0, 6, 4),
		Color = color,
		Transparency = 0.35,
		Material = Enum.Material.Glass,
		Parent = m,
	})
	for _, x in { -4, 4 } do
		part({
			Name = "Pillar",
			Size = Vector3.new(0.8, 10, 0.8),
			CFrame = cf * CFrame.new(x, 6, 3.6),
			Color = Color3.fromRGB(235, 235, 245),
			Parent = m,
		})
		part({
			Name = "SideGlass",
			Size = Vector3.new(0.3, 10, 7),
			CFrame = cf * CFrame.new(x, 6, 0.3),
			Color = color,
			Transparency = 0.6,
			Material = Enum.Material.Glass,
			Parent = m,
		})
	end
	local roof = part({
		Name = "Roof",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(1.2, 10, 10),
		CFrame = cf * CFrame.new(0, 11.6, 0) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.fromRGB(235, 235, 245),
		Parent = m,
	})
	local sign = part({
		Name = "Sign",
		Size = Vector3.new(7, 2.2, 0.3),
		CFrame = cf * CFrame.new(0, 13.4, 0),
		Color = color,
		Material = Enum.Material.Neon,
		Parent = m,
	})
	label(sign, Enum.NormalId.Front, (if shape == "Triangle" then "▲ " else "● ") .. roleLabel, Color3.new(1, 1, 1))
	label(sign, Enum.NormalId.Back, (if shape == "Triangle" then "▲ " else "● ") .. roleLabel, Color3.new(1, 1, 1))
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 14
	light.Brightness = 2
	light.Parent = roof

	part({
		Name = "Zone",
		Size = Vector3.new(7, 8, 7),
		CFrame = cf * CFrame.new(0, 5, 0),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = m,
	})
	m.PrimaryPart = m:FindFirstChild("Base") :: BasePart
	return m
end

local function zone(parent: Instance, cf: CFrame)
	part({
		Name = "Zone",
		Size = Vector3.new(6.5, 8, 6.5),
		CFrame = cf * CFrame.new(0, 5, 0),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = parent,
	})
end

local function meshPart(templates: { [string]: MeshPart }, name: string, cf: CFrame, parent: Instance): MeshPart
	local p = templates[name]:Clone()
	p.CFrame = cf * CFrame.new(CapsuleMeshes.Meshes[name].Offset)
	p.Parent = parent
	return p
end

-- Capsule from the Blender meshes. onNegativeX: this capsule is on the pair's -X side, so its knob turns to face out.
local function meshCapsule(
	templates: { [string]: MeshPart },
	name: string,
	cf: CFrame,
	color: Color3,
	roleLabel: string,
	shape: string,
	onNegativeX: boolean
): Model
	local m = Instance.new("Model")
	m.Name = name

	for _, partName in CapsuleMeshes.CapsuleParts do
		local p = meshPart(templates, partName, cf, m)
		if not CapsuleMeshes.Meshes[partName].Color then
			if partName == "Capsule_Glass" then
				p.Color = color:Lerp(Color3.new(1, 1, 1), 0.45)
			elseif partName == "Capsule_Glow_Role" then
				p.Color = color:Lerp(Color3.new(0, 0, 0), 0.3) -- Neon blows bright colors out (orange reads yellow)
			else
				p.Color = color
			end
		end
		if partName == "Capsule_Knob_Role" and onNegativeX then
			local off = CapsuleMeshes.Meshes[partName].Offset
			p.CFrame = cf * CFrame.new(-off.X, off.Y, off.Z) * CFrame.Angles(0, math.pi, 0)
		end
	end
	meshPart(templates, CapsuleMeshes.Emblem[shape], cf, m)

	-- role name on the front of the rim band
	local sign = part({
		Name = "Sign",
		Size = Vector3.new(5, 1.1, 0.1),
		CFrame = cf * CFrame.new(0, 10.5, -4.8),
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		Parent = m,
	})
	label(sign, Enum.NormalId.Front, (if shape == "Triangle" then "▲ " else "● ") .. roleLabel, color)

	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 12
	light.Brightness = 1.5
	light.Parent = m:FindFirstChild("Capsule_Glow_Role")

	zone(m, cf)
	m.PrimaryPart = m:FindFirstChild("Capsule_Base") :: BasePart
	return m
end

function LobbyBuilder.Build()
	if workspace:FindFirstChild("Lobby") then
		return
	end

	local lobby = Instance.new("Folder")
	lobby.Name = "Lobby"

	-- the lobby is Kai and Miko's bedroom at night, players doll-sized on the shared desk (LobbyRoom)
	Worlds.ApplyLook(Worlds.ByName.Lobby.Look)
	local room = LobbyRoom.Build(lobby)
	LobbyKit.Build(lobby, room)
	LobbyProps.Build(lobby)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 0.2, 12)
	-- in front of the chalkboard sign, facing it (and the CRT + moonlit window behind it)
	local spawnAt = RING_CENTER + Vector3.new(0, 0.1, -18)
	spawn.CFrame = CFrame.lookAt(spawnAt, spawnAt + Vector3.zAxis)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Duration = 0
	spawn.Parent = lobby

	-- the instructions: a double-sided A-frame chalkboard in the middle of the ring (meshes: LobbyKit Sign_*, built by
	-- tools/lobby_kit/sign.py; the chalk lettering lies on the same board planes, so keep SIGN in sync with HINGE etc.)
	for _, side in { -1, 1 } do
		local board = signPanel(side)
		local face = part({
			Name = "SignChalk",
			Size = Vector3.new(SIGN.W, SIGN.H, 0.04),
			CFrame = board * CFrame.new(0, 0, -0.23),
			Transparency = 1,
			Parent = lobby,
		})
		face.CanCollide = false
		face.CanQuery = false
		face.CanTouch = false
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 32
		gui.LightInfluence = 0.5 -- chalk stays readable in the night room
		gui.Brightness = 1.3
		gui.Parent = face
		-- hand-chalked lettering, smudges and doodles baked into one texture (textures/make_lobby_chalk.py)
		local img = Instance.new("ImageLabel")
		img.Size = UDim2.fromScale(1, 1)
		img.BackgroundTransparency = 1
		img.Image = CHALK
		img.Parent = gui
	end
	for _, side in { -1, 1 } do -- the panels are solid (invisible colliders on the board planes)
		local hinge = SIGN.Hinge
		local foot = Vector3.new(0, 0, hinge.Z + side * SIGN.Spread)
		local slope = (foot - hinge).Magnitude
		local panel = part({
			Name = "SignCollider",
			Size = Vector3.new(SIGN.W + 4, slope, 1.4),
			CFrame = signPanel(side) * CFrame.new(0, SIGN.BoardAt - slope / 2, 0),
			Transparency = 1,
			Parent = lobby,
		})
		panel.CanQuery = false
	end

	local pairsFolder = Instance.new("Folder")
	pairsFolder.Name = "CapsulePairs"
	pairsFolder.Parent = lobby

	local templates = MeshAssets.Load(CapsuleMeshes.Meshes, "Lobby capsule")

	for i = 1, PAIRS do
		local angle = (i - 1) / PAIRS * math.pi * 2
		local pos = RING_CENTER + Vector3.new(math.cos(angle) * RING_RADIUS, 0, math.sin(angle) * RING_RADIUS)
		-- LookVector points at the center, so the open (front, -Z) side of each capsule faces players.
		local pairCf = CFrame.lookAt(pos, RING_CENTER)

		local pair = Instance.new("Model")
		pair.Name = `Pair{i}`
		local kaiCf, mikoCf = pairCf * CFrame.new(-6, 0, 0), pairCf * CFrame.new(6, 0, 0)
		local screen: BasePart
		if templates then
			local kai = Roles.Kai
			meshCapsule(templates, "KaiCapsule", kaiCf, kai.Color, kai.Label, kai.Shape, true).Parent = pair
			local miko = Roles.Miko
			meshCapsule(templates, "MikoCapsule", mikoCf, miko.Color, miko.Label, miko.Shape, false).Parent = pair
			for _, name in CapsuleMeshes.MarqueeParts do
				meshPart(templates, name, pairCf, pair)
			end
			screen = meshPart(templates, CapsuleMeshes.Screen, pairCf, pair)
			screen.Name = "Screen"
		else
			capsule("KaiCapsule", kaiCf, Roles.Kai.Color, Roles.Kai.Label, Roles.Kai.Shape).Parent = pair
			capsule("MikoCapsule", mikoCf, Roles.Miko.Color, Roles.Miko.Label, Roles.Miko.Shape).Parent = pair
			screen = part({
				Name = "Screen",
				Size = Vector3.new(10, 4, 0.5),
				CFrame = pairCf * CFrame.new(0, 12, -1),
				Color = Color3.fromRGB(15, 15, 25),
				Parent = pair,
			})
		end
		label(screen, Enum.NormalId.Front, "STEP IN TO PLAY", Color3.fromRGB(255, 255, 255), "Status")

		pair.Parent = pairsFolder
		CollectionService:AddTag(pair, "CapsulePair")
	end

	lobby.Parent = workspace
end

return LobbyBuilder
