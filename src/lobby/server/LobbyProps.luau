-- Hero props in the lobby bedroom (blender_assets/briefs/Lobby.md), all Studio generate_mesh (Oct 3, 2026), placed
-- at doll scale (1 stud ≈ 1.5 cm) around the capsule ring on the desk. Each entry: mesh + texture, the size it is
-- placed at, where it stands (bottom centre), yaw (generations face −Z), and whether players can stand on it.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)

local LobbyProps = {}

local v = Vector3.new
local rgb = Color3.fromRGB

type Prop = {
	Id: string,
	Tex: string,
	Size: Vector3,
	At: Vector3, -- bottom centre
	Yaw: number, -- degrees
	Solid: boolean?,
}

local PROPS: { [string]: Prop } = {
	-- a beige 90s CRT: the screen shows the game's title. Blender kit piece since Oct 18 (tools/lobby_kit/fix_oct18.py,
	-- lobby palette atlas): the generated one had a domed front the screen panel hung off. glTF upload: +180 yaw.
	Monitor = {
		Id = "rbxassetid://136806831133697",
		Tex = "rbxassetid://85641984484582",
		Size = v(30, 31, 26.65),
		At = v(64, 0, 40),
		Yaw = 22 + 180,
		Solid = true,
	},
	DeskLamp = { -- anglepoise lamp: the warm pool over the capsules
		Id = "rbxassetid://135181796673394",
		Tex = "rbxassetid://129948869077306",
		Size = v(15, 38.2, 30),
		At = v(-72, 0, 44),
		Yaw = -40,
		Solid = true,
	},
	PencilMug = {
		Id = "rbxassetid://132738936906712",
		Tex = "rbxassetid://121658238026065",
		Size = v(12, 16.3, 9.4),
		At = v(86, 0, -46),
		Yaw = 200,
		Solid = true,
	},
	-- felt owl plush against the lamp (Night Owl Interactive's owl). Replaced the bunny on Oct 18: the user said it read
	-- as an It Takes Two toy
	Owl = {
		Id = "rbxassetid://111224340763459",
		Tex = "rbxassetid://125907762193199",
		Size = v(13.8, 16, 11),
		At = v(-88, 0, 12),
		Yaw = -60,
		Solid = true,
	},
	Gamepad = { -- the two of them shared one controller
		Id = "rbxassetid://138386948894306",
		Tex = "rbxassetid://92886969535241",
		Size = v(18.3, 3.6, 14.4),
		At = v(-78, 0, -34),
		Yaw = 30,
		Solid = true,
	},
	TinRobot = { -- Kai's wind-up robot, watching the capsules
		Id = "rbxassetid://134156560692781",
		Tex = "rbxassetid://118087201797085",
		Size = v(10.8, 20.8, 6.8),
		At = v(90, 0, 8),
		Yaw = 90,
		Solid = true,
	},
	Crayons = {
		Id = "rbxassetid://78249840480132",
		Tex = "rbxassetid://122717164017484",
		Size = v(12.2, 5.4, 14.4),
		At = v(30, 0, 54),
		Yaw = 15,
		Solid = true,
	},
	Sneakers = { -- kicked off by the bed
		Id = "rbxassetid://110025490841078",
		Tex = "rbxassetid://108606592099967",
		Size = v(13.5, 5.5, 13.2),
		At = v(-74, -50, -104),
		Yaw = 35,
		Solid = true,
	},
	Backpack = { -- dropped against the desk drawers after school
		Id = "rbxassetid://94015730973191",
		Tex = "rbxassetid://111877754706453",
		Size = v(19.3, 24, 18.8),
		At = v(112, -50, -48),
		Yaw = 200,
		Solid = true,
	},
	-- painted wooden hot-air balloon on a stand, on the bookshelf's second shelf (replaced the toy rocket, Oct 18:
	-- also too It Takes Two)
	Balloon = {
		Id = "rbxassetid://82873346947082",
		Tex = "rbxassetid://91607886263640",
		Size = v(7, 16, 7.1),
		At = v(131, -24, -142),
		Yaw = 80,
	},
	ToyChest = { -- painted star chest against the left wall, between the window and the bed
		Id = "rbxassetid://122546609019215",
		Tex = "rbxassetid://102882813964117",
		Size = v(30, 20.6, 20),
		At = v(-144, -50, 20),
		Yaw = -90,
		Solid = true,
	},
	Dino = { -- plush triceratops on the wall shelf over the bed
		Id = "rbxassetid://104177434934291",
		Tex = "rbxassetid://138024132081161",
		Size = v(8.8, 11.5, 12),
		At = v(-153, 76, -182),
		Yaw = -90,
	},
	Train = { -- wooden engine on the track loop (LobbyTrain.client drives it round)
		Id = "rbxassetid://104298266714340",
		Tex = "rbxassetid://130571225608901",
		Size = v(6.3, 7.7, 12),
		At = v(110, -48.5, -160),
		Yaw = 0,
	},
	WallClock = { -- over the door
		Id = "rbxassetid://113512693537874",
		Tex = "rbxassetid://113358452816568",
		Size = v(16, 16, 2.7),
		At = v(90, 102, -228.6),
		Yaw = 180,
	},
	Hoodie = { -- hanging on the peg rail by the door
		Id = "rbxassetid://139800686223767",
		Tex = "rbxassetid://81767989145794",
		Size = v(16, 17.7, 6.3),
		At = v(144, 29.3, -226.6),
		Yaw = 180,
	},
	BoardGames = { -- stacked on top of the cubbies
		Id = "rbxassetid://115828591954845",
		Tex = "rbxassetid://130381342052983",
		Size = v(12.7, 14.4, 11.6),
		At = v(147, 1, -88),
		Yaw = -90,
		Solid = true,
	},
	Beanbag = { -- lavender beanbag in the corner by the window: a spot to sit while waiting
		Id = "rbxassetid://88560702166360",
		Tex = "rbxassetid://107444850742486",
		Size = v(26, 24.5, 28.3),
		At = v(-132, -50, 50),
		Yaw = -45,
		Solid = true,
	},
	ToyBasket = { -- wicker basket of toys under the desk
		Id = "rbxassetid://111726445910970",
		Tex = "rbxassetid://96748173716905",
		Size = v(20.8, 17.8, 20.8),
		At = v(-56, -50, 34),
		Yaw = 160,
		Solid = true,
	},
	PictureBook = { -- a picture book left on the rug
		Id = "rbxassetid://120251024183715",
		Tex = "rbxassetid://80072381380805",
		Size = v(14.8, 4.1, 15),
		At = v(-36, -47.6, -118),
		Yaw = 25,
		Solid = true,
	},
	AlarmClock = { -- on the bookshelf's top shelf
		Id = "rbxassetid://126811922982958",
		Tex = "rbxassetid://125531394157193",
		Size = v(7.2, 10, 3.8),
		At = v(140, 48.5, -170),
		Yaw = 90,
	},
}

local function place(name: string, prop: Prop, parent: Instance): MeshPart?
	local ok, part = pcall(MeshAssets.Template, name, {
		Id = prop.Id,
		TextureId = prop.Tex,
		Offset = Vector3.zero,
		Size = prop.Size,
		Material = Enum.Material.SmoothPlastic,
		Collision = if prop.Solid then Enum.CollisionFidelity.Hull else nil,
	})
	if not ok or not part then
		warn("[LobbyProps] couldn't load", name, part)
		return nil
	end
	part.CFrame = CFrame.new(prop.At + v(0, prop.Size.Y / 2, 0)) * CFrame.Angles(0, math.rad(prop.Yaw), 0)
	part.Parent = parent
	return part
end

-- The CRT shows the title screen: navy, the handwritten logo, a blinking PRESS START, and lights the desk.
local function monitorScreen(monitor: MeshPart, parent: Instance)
	local screen = Instance.new("Part")
	screen.Name = "MonitorScreen"
	screen.Anchored = true
	screen.CanCollide = false
	screen.CanQuery = false
	screen.CanTouch = false
	-- in the bezel's 22 x 17 opening (fix_oct18.py: centre 3 above the mesh centre, glass 1.3 behind the bezel front),
	-- edges tucked 0.2 into its walls; the extra half turn undoes the glTF one so -Z is the screen's front
	screen.Size = v(22.4, 17.4, 0.2)
	screen.CFrame = monitor.CFrame * CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 3, -11.275)
	screen.Material = Enum.Material.SmoothPlastic
	screen.Color = rgb(14, 20, 48)
	screen.Parent = parent
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 30
	gui.LightInfluence = 0
	gui.Brightness = 1.6
	gui.Parent = screen
	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = rgb(16, 24, 62)
	bg.BorderSizePixel = 0
	bg.Parent = gui
	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new(rgb(40, 52, 120), rgb(10, 14, 36))
	grad.Parent = bg
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(0.9, 0.36)
	title.Position = UDim2.fromScale(0.05, 0.16)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.PermanentMarker
	title.TextScaled = true
	title.TextColor3 = rgb(255, 244, 224)
	title.Text = "Starfall Kingdom" -- the game Kai and Miko made on this desk (Story Line)
	title.Parent = bg
	local star = Instance.new("TextLabel")
	star.Size = UDim2.fromScale(0.2, 0.18)
	star.Position = UDim2.fromScale(0.4, 0.02)
	star.BackgroundTransparency = 1
	star.Font = Enum.Font.FredokaOne
	star.TextScaled = true
	star.TextColor3 = rgb(255, 217, 138)
	star.Text = "★"
	star.Parent = bg
	local press = Instance.new("TextLabel")
	press.Name = "PressStart"
	press.Size = UDim2.fromScale(0.7, 0.14)
	press.Position = UDim2.fromScale(0.15, 0.66)
	press.BackgroundTransparency = 1
	press.Font = Enum.Font.Arcade
	press.TextScaled = true
	press.TextColor3 = rgb(238, 242, 255)
	press.Text = "PRESS START"
	press.Parent = bg
	local scan = Instance.new("Frame") -- faint scanlines
	scan.Size = UDim2.fromScale(1, 1)
	scan.BackgroundTransparency = 1
	scan.Parent = bg
	for k = 0, 40 do
		local line = Instance.new("Frame")
		line.Size = UDim2.new(1, 0, 0, 2)
		line.Position = UDim2.fromScale(0, k / 40)
		line.BackgroundColor3 = rgb(0, 0, 0)
		line.BackgroundTransparency = 0.82
		line.BorderSizePixel = 0
		line.Parent = scan
	end
	local glow = Instance.new("SurfaceLight")
	glow.Face = Enum.NormalId.Front
	glow.Color = rgb(150, 170, 255)
	glow.Brightness = 1.4
	glow.Range = 34
	glow.Angle = 100
	glow.Parent = screen
	task.spawn(function() -- PRESS START blinks
		while screen.Parent do
			press.TextTransparency = if press.TextTransparency == 0 then 1 else 0
			task.wait(0.6)
		end
	end)
end

-- The lamp's warm cone over the capsule ring (small and soft: memory subtle-lighting).
local function lampLight(lamp: MeshPart, parent: Instance)
	local head = Instance.new("Part")
	head.Name = "LampBulb"
	head.Anchored = true
	head.CanCollide = false
	head.CanQuery = false
	head.CanTouch = false
	head.Transparency = 1
	head.Size = v(1, 1, 1)
	-- the shade sits high and forward (−Z) on the mesh; aim the light down at the capsule ring
	local pos = (lamp.CFrame * CFrame.new(0, lamp.Size.Y * 0.32, -lamp.Size.Z * 0.28)).Position
	head.CFrame = CFrame.lookAt(pos, v(-10, 0, -14))
	head.Parent = parent
	lamp.CastShadow = false -- the shade would shadow its own bulb
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Front
	spot.Color = rgb(255, 206, 150)
	spot.Brightness = 2.2
	spot.Range = 70
	spot.Angle = 75
	spot.Shadows = true
	spot.Parent = head
	local bulb = Instance.new("PointLight") -- a little spill around the shade itself
	bulb.Color = rgb(255, 196, 130)
	bulb.Brightness = 0.6
	bulb.Range = 10
	bulb.Parent = head
end

function LobbyProps.Build(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Props"
	folder.Parent = parent
	task.spawn(function() -- meshes load asynchronously; the room is playable meanwhile
		local made: { [string]: MeshPart } = {}
		for name, prop in PROPS do
			made[name] = place(name, prop, folder) :: any
		end
		if made.Monitor then
			monitorScreen(made.Monitor, folder)
		end
		if made.DeskLamp then
			lampLight(made.DeskLamp, folder)
		end
	end)
	return folder
end

return LobbyProps
