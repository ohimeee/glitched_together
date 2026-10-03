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
