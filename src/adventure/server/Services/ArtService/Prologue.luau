-- Prologue art (blender_assets/PrologueUI.*, briefs/PrologueUI.md): skins over the title-screen grey-box.
-- Offsets are from the grey-box part's center at Design size (front = -Z). Ids from Studio's 3D importer.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)

local NAVY = Palette.Prologue.Navy
local SLATE = Color3.fromRGB(46, 54, 112) -- panel bodies: lighter than NAVY so they read against the night sky
local WHITE = Palette.Prologue.White
local GLITCH = Palette.Glow.Glitch
local SMOOTH = Enum.Material.SmoothPlastic

local Skins: { [string]: MeshAssets.Skin } = {
	UIPanel = {
		Design = Vector3.new(20, 4, 20),
		Meshes = {
			PR_UIPanel_Body = {
				Id = "rbxassetid://122560251139444",
				Offset = Vector3.zero,
				Size = Vector3.new(19.6, 4, 19.6),
				Material = SMOOTH,
				Color = SLATE,
			},
			PR_UIPanel_Trim = {
				Id = "rbxassetid://70827562740693",
				Offset = Vector3.new(0, 1.3, 0),
				Size = Vector3.new(20, 0.6, 20),
				Material = SMOOTH,
				Color = WHITE,
			},
		},
	},
	MenuButton = {
		Design = Vector3.new(10, 4, 10),
		Meshes = {
			PR_MenuButton_Base = {
				Id = "rbxassetid://100400917746775",
				Offset = Vector3.new(0, -1.35, 0),
				Size = Vector3.new(10, 1.3, 10),
				Material = SMOOTH,
				Color = NAVY,
			},
			PR_MenuButton_Cap = {
				Id = "rbxassetid://112022825226517",
				Offset = Vector3.new(0, 0.55, 0),
				Size = Vector3.new(8.4, 2.9, 8.4),
				Material = SMOOTH,
				Color = WHITE,
			},
		},
	},
	TitleCard = {
		Design = Vector3.new(30, 10, 1),
		Meshes = {
			PR_TitleCard_Frame = {
				Id = "rbxassetid://96474385090873",
				Offset = Vector3.zero,
				Size = Vector3.new(30, 10, 1),
				Material = SMOOTH,
				Color = WHITE,
			},
			PR_TitleCard_Screen = {
				Id = "rbxassetid://126075840302195",
				Offset = Vector3.zero,
				Size = Vector3.new(27.3, 7.3, 0.4),
				Material = SMOOTH,
				Color = NAVY,
			},
			PR_TitleCard_Glitch = {
				Id = "rbxassetid://72446285863055",
				Offset = Vector3.new(-0.6, 0.65, 0),
				Size = Vector3.new(33.53, 13.43, 1.33),
				Material = Enum.Material.Neon,
				Color = GLITCH,
			},
		},
	},
}

-- Stage-set kit (blender_assets/PrologueKit.*, tools/prologue_kit/kit.py): the title screen as a theatre set in the
-- void, It Takes Two space-chapter style. Aluminium box trusses hold every panel up, par cans light the route from
-- truss towers, giant settings-menu props stand on their own trusses. Offsets = mesh centres from the Blender report.
local ALU = Color3.fromRGB(196, 200, 210)
local PINK = Palette.Prologue.Pink
local LAMP = Color3.fromRGB(255, 214, 160) -- warm stage light, never the Duo white
local METAL = Enum.Material.Metal
local KIT: { [string]: MeshAssets.Skin } = {
	PR_Truss = { -- 3×3 box truss, one 12-stud segment (stacked)
		Design = Vector3.new(3.08, 12, 3.1),
		Meshes = {
			Truss = {
				Id = "rbxassetid://130581096776983",
				Offset = Vector3.zero,
				Size = Vector3.new(3.08, 12, 3.1),
				Material = METAL,
				Color = ALU,
			},
		},
	},
	PR_Spot = { -- par can on a yoke, lens faces -Z, clamp on top
		Design = Vector3.new(3.08, 4.69, 3.2),
		Meshes = {
			Can = {
				Id = "rbxassetid://85243317894415",
				Offset = Vector3.new(0, 0.93, 0.1),
				Size = Vector3.new(3.08, 4.69, 3.2),
				Material = METAL,
				Color = Color3.fromRGB(30, 30, 36),
			},
			Lens = {
				Id = "rbxassetid://131686152943491",
				Offset = Vector3.new(0, 0, -1.33),
				Size = Vector3.new(2.24, 2.24, 0.12),
				Material = Enum.Material.Neon,
				Color = LAMP,
			},
		},
	},
	PR_Window = { -- settings window: title bar, three dots, close X, three menu rows
		Design = Vector3.new(40, 26, 1.5),
		Meshes = {
			Body = {
				Id = "rbxassetid://88754548791368",
				Offset = Vector3.zero,
				Size = Vector3.new(39.4, 25.4, 1.2),
				Material = SMOOTH,
				Color = SLATE,
			},
			Rim = {
				Id = "rbxassetid://134489917054499",
				Offset = Vector3.zero,
				Size = Vector3.new(40, 26, 1.5),
				Material = SMOOTH,
				Color = WHITE,
			},
			Bar = {
				Id = "rbxassetid://129801624738466",
				Offset = Vector3.new(0, 10.4, -0.9),
				Size = Vector3.new(37.8, 3.4, 0.6),
				Material = SMOOTH,
				Color = PINK,
			},
			Rows = {
				Id = "rbxassetid://78746990537351",
				Offset = Vector3.new(-1.43, 1.93, -0.9),
				Size = Vector3.new(32.86, 18.66, 0.6),
				Material = SMOOTH,
				Color = WHITE,
			},
		},
	},
	PR_Toggle = { -- an ON toggle switch
		Design = Vector3.new(16, 8, 2),
		Meshes = {
			Track = {
				Id = "rbxassetid://122766542562390",
				Offset = Vector3.zero,
				Size = Vector3.new(16, 8, 2),
				Material = SMOOTH,
				Color = PINK,
			},
			Knob = {
				Id = "rbxassetid://90177105809498",
				Offset = Vector3.new(-4, 0, -0.9),
				Size = Vector3.new(6.2, 6.2, 3.41),
				Material = SMOOTH,
				Color = WHITE,
			},
		},
	},
	PR_Check = { -- a ticked checkbox
		Design = Vector3.new(10, 10, 1.6),
		Meshes = {
			Box = {
				Id = "rbxassetid://78811448458568",
				Offset = Vector3.zero,
				Size = Vector3.new(10, 10, 1.6),
				Material = SMOOTH,
				Color = WHITE,
			},
			Tick = {
				Id = "rbxassetid://90526893232682",
				Offset = Vector3.new(-0.06, 0.35, -0.9),
				Size = Vector3.new(7.32, 5.69, 0.9),
				Material = SMOOTH,
				Color = PINK,
			},
		},
	},
	PR_Load = { -- a loading bar stuck at 72%
		Design = Vector3.new(50, 6, 2),
		Meshes = {
			Frame = {
				Id = "rbxassetid://84104222001240",
				Offset = Vector3.zero,
				Size = Vector3.new(50, 6, 2),
				Material = SMOOTH,
				Color = WHITE,
			},
			Fill = {
				Id = "rbxassetid://129281063199361",
				Offset = Vector3.new(6.64, 0, 0),
				Size = Vector3.new(34.13, 4.4, 1.2),
				Material = Enum.Material.Neon,
				Color = PINK,
				Transparency = 0.35, -- full neon glared like a light sabre
			},
			Back = {
				Id = "rbxassetid://123036514670795",
				Offset = Vector3.new(0, 0, 0.5),
				Size = Vector3.new(49.2, 5.2, 0.6),
				Material = SMOOTH,
				Color = NAVY,
			},
		},
	},
	PR_Gear = { -- the settings cog
		Design = Vector3.new(15.66, 15.95, 3),
		Meshes = {
			Gear = {
				Id = "rbxassetid://123675175460657",
				Offset = Vector3.zero,
				Size = Vector3.new(15.66, 15.95, 3),
				Material = SMOOTH,
				Color = WHITE,
			},
		},
	},
}
for name, skin in KIT do
	Skins[name] = skin
end

-- Which grey-box part (by name) gets which skin.
local Dressing: { [string]: string } = {
	Start = "UIPanel",
	OptionsSlider = "UIPanel",
	ChimneyBase = "UIPanel",
	LoadGame = "UIPanel",
	SaveSlots = "UIPanel",
	Credits = "UIPanel",
	HighLedge = "UIPanel",
	Extras = "UIPanel",
	FanTop = "UIPanel",
	DuoPoundRoom = "UIPanel",
	LeverRoom = "UIPanel",
	NewGame = "UIPanel",
	MenuButton1 = "MenuButton",
	MenuButton2 = "MenuButton",
	MenuButton3 = "MenuButton",
	TitleCard = "TitleCard",
}

-- checkpoints: the floppy-disk save point from the Core kit (a title screen's SAVE)
-- a SurfaceGui with one centred label on both big faces of a part
local function faceText(part: BasePart, text: string, color: Color3, font: Enum.Font, scale: number)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 24
		gui.LightInfluence = 0.3
		gui.Parent = part
		local t = Instance.new("TextLabel")
		t.AnchorPoint = Vector2.new(0.5, 0.5)
		t.Position = UDim2.fromScale(0.5, 0.5)
		t.Size = UDim2.fromScale(0.86, scale)
		t.BackgroundTransparency = 1
		t.Font = font
		t.TextScaled = true
		t.TextColor3 = color
		t.Text = text
		t.Parent = gui
	end
end

-- Gates (DuoGate) and the bounce pad were bare neon slabs that glared white. On a title screen a locked door is a
-- modal dialog box: a slate panel with a white frame and a "LOCKED" line (white = both players), the frame and text
-- ride along with the gate when it opens. The bounce pad becomes a white UI button with jump chevrons.
local function dialogGates(world: Instance)
	for _, gate in world:GetDescendants() do
		if gate:IsA("BasePart") and gate.Name:match("^Gate_") and gate.Material == Enum.Material.Neon then
			gate.Material = SMOOTH
			gate.Color = SLATE
			local frame = Instance.new("SelectionBox") -- crisp white rim, drawn on the gate's box (moves with it)
			frame.Adornee = gate
			frame.LineThickness = 0.35
			frame.Color3 = WHITE
			frame.SurfaceTransparency = 1
			frame.Parent = gate
			faceText(gate, "LOCKED\nboth players needed", WHITE, Enum.Font.GothamBold, 0.5)
			-- an opened gate sinks into the 2-stud gap between panels and would hang below them still saying LOCKED:
			-- the dialog closes (fades out) as it sinks, and comes back if the gate closes again
			local shown = gate.Transparency
			gate:GetAttributeChangedSignal("Open"):Connect(function()
				local open = gate:GetAttribute("Open") == true
				TweenService:Create(gate, TweenInfo.new(0.4), { Transparency = if open then 1 else shown }):Play()
				frame.Visible = not open
				for _, gui in gate:GetChildren() do
					if gui:IsA("SurfaceGui") then
						gui.Enabled = not open
					end
				end
			end)
		end
	end
	for _, pad in world:GetDescendants() do
		if pad:IsA("BasePart") and pad.Name == "BouncePad" and pad.Material == Enum.Material.Neon then
			pad.Material = SMOOTH
			pad.Color = WHITE
			local gui = Instance.new("SurfaceGui")
			gui.Face = Enum.NormalId.Top
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 24
			gui.LightInfluence = 0.3
			gui.Parent = pad
			local t = Instance.new("TextLabel")
			t.Size = UDim2.fromScale(1, 1)
			t.BackgroundTransparency = 1
			t.Font = Enum.Font.GothamBlack
			t.TextScaled = true
			t.TextColor3 = Palette.Prologue.Pink
			t.Text = "︽"
			t.Parent = gui
		end
	end
end

-- ---------------------------------------------------------------------------------------------- stage set
local TRUSS_FLOOR = -120 -- trusses run down into the dark and fade out before this
local FADE = { 0.25, 0.5, 0.72, 0.9 } -- transparency of the last truss segments (deepest last)

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

local function skinned(apply, name: string, skin: string, scale: number, cf: CFrame, parent: Instance): Part?
	local h = holder(name, KIT[skin].Design * scale, cf, parent)
	if apply(h, skin) then
		return h
	end
	h:Destroy()
	return nil
end

-- a vertical box-truss pylon from `top` down into the void, the deepest segments fading out
local function pylon(apply, parent: Instance, x: number, z: number, top: number, yaw: number?)
	local count = math.max(1, math.ceil((top - TRUSS_FLOOR) / 12))
	for i = 1, count do
		local y = top - 6 - (i - 1) * 12
		local seg = skinned(apply, "Truss", "PR_Truss", 1, CFrame.new(x, y, z) * CFrame.Angles(0, yaw or 0, 0), parent)
		if not seg then
			return
		end
		local fade = FADE[i - (count - #FADE)]
		if fade then
			for _, m in seg:GetChildren() do
				if m:IsA("BasePart") then
					m.Transparency = fade
				end
			end
		end
	end
end

-- a horizontal truss from a to b (same height), tiled in 12-stud segments
local function girder(apply, parent: Instance, a: Vector3, b: Vector3)
	local len = (b - a).Magnitude
	local n = math.max(1, math.round(len / 12))
	local k = len / (n * 12)
	for i = 0, n - 1 do
		local c = a:Lerp(b, (i + 0.5) / n)
		-- the segment's long axis is Y: lay it along a→b
		local cf = CFrame.lookAt(c, b) * CFrame.Angles(math.rad(90), 0, 0)
		local h = holder("Girder", Vector3.new(3.08, 12 * k, 3.1), cf, parent)
		if not apply(h, "PR_Truss") then
			h:Destroy()
			return
		end
	end
end

-- marquee bulbs along a panel's two long sides (warm, not the Duo white); no lights, just bloom
local BULB = Color3.fromRGB(255, 205, 140)
local function bulbs(parent: Instance, panel: BasePart)
	local s = panel.Size
	local top = s.Y / 2 - 0.9
	for _, side in { -1, 1 } do
		local n = math.max(2, math.floor(s.Z / 3))
		for i = 0, n - 1 do
			local b = Instance.new("Part")
			b.Name = "Bulb"
			b.Shape = Enum.PartType.Ball
			b.Size = Vector3.new(0.5, 0.5, 0.5)
			b.Material = Enum.Material.Neon
			b.Color = BULB
			b.Anchored = true
			b.CanCollide = false
			b.CanQuery = false
			b.CanTouch = false
			b.CastShadow = false
			local z = -s.Z / 2 + 1.5 + i * (s.Z - 3) / math.max(n - 1, 1)
			b.CFrame = panel.CFrame * CFrame.new(side * (s.X / 2 + 0.15), top, z)
			b.Parent = parent
		end
	end
end

-- a light tower beside the route: a pylon up past the route, a short cross truss, two par cans aimed at targets,
-- each with a small warm spotlight and a faint beam ribbon for the light cone
local function beamTo(spot: Part, target: Vector3, parent: Instance)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 0, -spot.Size.Z / 2)
	a0.Parent = spot
	local tgt = holder("BeamEnd", Vector3.new(0.2, 0.2, 0.2), CFrame.new(target), parent)
	local a1 = Instance.new("Attachment")
	a1.Parent = tgt
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Width0 = 2.2
	beam.Width1 = 16
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Color = ColorSequence.new(LAMP)
	beam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.82),
		NumberSequenceKeypoint.new(0.6, 0.93),
		NumberSequenceKeypoint.new(1, 1),
	})
	beam.Segments = 1
	beam.Parent = spot
	local light = Instance.new("SpotLight")
	light.Face = Enum.NormalId.Front
	light.Angle = 40
	light.Range = math.min(60, (target - spot.Position).Magnitude + 8)
	light.Brightness = 1.4
	light.Color = LAMP
	light.Shadows = false
	light.Parent = spot
end

local function lightTower(apply, parent: Instance, base: Vector3, targets: { Vector3 })
	local top = base.Y
	pylon(apply, parent, base.X, base.Z, top)
	-- head: a short cross truss the cans clamp under
	local dir = ((targets[1] + (targets[2] or targets[1])) / 2 - base) * Vector3.new(1, 0, 1)
	local side = dir.Unit:Cross(Vector3.yAxis)
	girder(apply, parent, base + Vector3.new(0, 1.5, 0) - side * 6, base + Vector3.new(0, 1.5, 0) + side * 6)
	for i, target in targets do
		local at = base + side * (if i == 1 then -4.5 else 4.5) - Vector3.new(0, 1.2, 0)
		local spot = skinned(apply, "Spot", "PR_Spot", 1, CFrame.lookAt(at, target), parent)
		if spot then
			beamTo(spot, target, parent)
		end
	end
end

-- a giant settings prop standing on its own truss, facing a point on the route
local function setPiece(
	apply,
	parent: Instance,
	skin: string,
	scale: number,
	pos: Vector3,
	face: Vector3,
	tilt: number?
)
	local cf = CFrame.lookAt(pos, Vector3.new(face.X, pos.Y, face.Z)) * CFrame.Angles(0, 0, math.rad(tilt or 0))
	local piece = skinned(apply, skin, skin, scale, cf, parent)
	if piece then
		-- the gear turns slowly on its axle: its truss runs up behind it to the hub instead of to its rim
		local spins = skin == "PR_Gear"
		if spins then
			piece:SetAttribute("Spin", 0.18)
			piece:AddTag("PropMotion")
		end
		local top = if spins then pos.Y else pos.Y - piece.Size.Y / 2 + 0.5
		local behind = if spins then -cf.LookVector * (piece.Size.Z / 2 + 1.6) else Vector3.zero
		pylon(apply, parent, pos.X + behind.X, pos.Z + behind.Z, top, math.atan2(-cf.LookVector.X, -cf.LookVector.Z))
	end
end

local function stageSet(world: Instance, apply: (BasePart, string) -> boolean)
	local set = Instance.new("Folder")
	set.Name = "StageSet"
	set.Parent = world
	-- every panel and menu button rests on trusses (two under wide panels), with bulbs along its long sides
	local panels = {}
	for _, p in world:GetDescendants() do
		local skin = p:IsA("BasePart") and Dressing[p.Name]
		if skin == "UIPanel" or skin == "MenuButton" then
			table.insert(panels, p)
		end
	end
	table.sort(panels, function(a, b)
		return a.Position.Z < b.Position.Z
	end)
	local feet = {}
	for _, p in panels do
		local bottom = p.Position.Y - p.Size.Y / 2
		local xs = if p.Size.X >= 18 then { -p.Size.X / 2 + 4, p.Size.X / 2 - 4 } else { 0 }
		for _, dx in xs do
			pylon(apply, set, p.Position.X + dx, p.Position.Z, bottom)
			table.insert(feet, Vector3.new(p.Position.X + dx, bottom, p.Position.Z))
		end
		if Dressing[p.Name] == "UIPanel" then
			bulbs(set, p)
		end
	end
	-- a girder spine low under the route ties neighbouring pylons together (a rig, not loose sticks)
	for i = 1, #feet - 1 do
		local a, b = feet[i], feet[i + 1]
		local y = math.min(a.Y, b.Y) - 14
		local flatA, flatB = Vector3.new(a.X, y, a.Z), Vector3.new(b.X, y, b.Z)
		if (flatB - flatA).Magnitude > 6 and (flatB - flatA).Magnitude < 70 then
			girder(apply, set, flatA, flatB)
		end
	end
	-- light towers along the route, cans aimed at the panels
	local function at(name: string): Vector3?
		local p = world:FindFirstChild(name, true)
		return p and p:IsA("BasePart") and p.Position + Vector3.new(0, p.Size.Y / 2, 0) or nil
	end
	local towers = {
		{ Vector3.new(-34, 30, 40), { "MenuButton2", "OptionsSlider" } },
		{ Vector3.new(36, 62, 130), { "LoadGame", "SaveSlots" } },
		{ Vector3.new(-38, 48, 268), { "Credits", "HighLedge" } },
		{ Vector3.new(38, 66, 330), { "FanTop", "DuoPoundRoom" } },
		{ Vector3.new(-36, 62, 410), { "LeverRoom", "NewGame" } },
	}
	for _, t in towers do
		local targets = {}
		for _, n in t[2] do
			local p = at(n)
			if p then
				table.insert(targets, p)
			end
		end
		if #targets > 0 then
			lightTower(apply, set, t[1], targets)
		end
	end
	-- giant settings props out in the void on both sides, facing the route
	-- faced back down the route (players walk +Z), so they read head-on instead of edge-on
	local pieces = {
		{ "PR_Window", 1.6, Vector3.new(-95, 48, 120), -4 },
		{ "PR_Toggle", 2.4, Vector3.new(82, 30, 60), 6 },
		{ "PR_Check", 2.6, Vector3.new(88, 52, 205), -5 },
		{ "PR_Load", 1.8, Vector3.new(-92, 70, 300), 3 },
		{ "PR_Gear", 2.8, Vector3.new(95, 80, 380), 0 },
		{ "PR_Window", 1.3, Vector3.new(-80, 22, -40), 5 },
	}
	for _, piece in pieces do
		local pos = piece[3]
		setPiece(apply, set, piece[1], piece[2], pos, Vector3.new(pos.X * 0.35, pos.Y, pos.Z - 140), piece[4])
	end
end

local function Extras(world: Instance, apply: (BasePart, string) -> boolean)
	require(script.Parent.GlitchedCore).SavePoints(world, apply)
	-- the faint neon pad read as a muddy brown slab on the navy panels: draw it as a highlighted save slot instead
	-- (yellow rounded outline + a tint, yellow = checkpoint), the pad part itself goes invisible
	for _, pad in world:GetDescendants() do
		if pad:IsA("BasePart") and pad:HasTag("Checkpoint") then
			pad.Transparency = 1
			local gui = Instance.new("SurfaceGui")
			gui.Face = Enum.NormalId.Top
			gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			gui.PixelsPerStud = 24
			gui.LightInfluence = 0.3
			gui.Parent = pad
			local slot = Instance.new("Frame")
			slot.AnchorPoint = Vector2.new(0.5, 0.5)
			slot.Position = UDim2.fromScale(0.5, 0.5)
			slot.Size = UDim2.fromScale(0.92, 0.92)
			slot.BackgroundColor3 = Palette.Neutral
			slot.BackgroundTransparency = 0.85
			slot.Parent = gui
			Instance.new("UICorner", slot).CornerRadius = UDim.new(0.12, 0)
			local rim = Instance.new("UIStroke")
			rim.Color = Palette.Neutral
			rim.Thickness = 7
			rim.Parent = slot
			local t = Instance.new("TextLabel")
			t.AnchorPoint = Vector2.new(0.5, 0.5)
			t.Position = UDim2.fromScale(0.62, 0.5) -- clear of the floppy disk standing on the slot's left
			t.Size = UDim2.fromScale(0.62, 0.2)
			t.BackgroundTransparency = 1
			t.Font = Enum.Font.GothamBold
			t.TextScaled = true
			t.TextColor3 = Palette.Neutral
			t.Text = `SAVE SLOT {pad:GetAttribute("Order") or ""}`
			t.Parent = slot
		end
	end
	dialogGates(world)
	stageSet(world, apply)
	-- the chimney's cling walls were bare dark slabs: stand a menu panel on its edge over each one (a giant scrollbar
	-- track with a white trim and a scroll thumb), the wall itself stays as the invisible clingable collider
	for _, wall in world:GetDescendants() do
		if wall:IsA("BasePart") and wall.Name == "ClingWall" then
			local holder = Instance.new("Part")
			holder.Name = "ClingPanel"
			holder.Anchored = true
			holder.CanCollide = false
			holder.CanQuery = false
			holder.CanTouch = false
			holder.Transparency = 1
			-- local X = the wall's height, local Y = its thickness: the panel lies on its edge
			holder.Size = Vector3.new(wall.Size.Y, wall.Size.X + 0.2, wall.Size.Z)
			holder.CFrame = wall.CFrame * CFrame.Angles(0, 0, math.rad(90))
			holder.Parent = wall.Parent
			if apply(holder, "UIPanel") then
				wall.Transparency = 1
				wall:SetAttribute("ArtHidden", true)
				for _, side in { -1, 1 } do -- the scroll thumb, on both faces
					local thumb = Instance.new("Part")
					thumb.Name = "ScrollThumb"
					thumb.Anchored = true
					thumb.CanCollide = false
					thumb.CanQuery = false
					thumb.CanTouch = false
					thumb.Material = SMOOTH
					thumb.Color = WHITE
					thumb.Size = Vector3.new(0.3, wall.Size.Y * 0.22, wall.Size.Z * 0.42)
					thumb.CFrame = wall.CFrame * CFrame.new(side * (wall.Size.X / 2 + 0.2), wall.Size.Y * 0.2, 0)
					thumb.Parent = holder
				end
			else
				holder:Destroy()
			end
		end
	end
end

return { Skins = Skins, Dressing = Dressing, Decor = {}, Extras = Extras }
