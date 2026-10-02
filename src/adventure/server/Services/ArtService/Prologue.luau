-- Prologue art (blender_assets/PrologueUI.*, briefs/PrologueUI.md): skins over the title-screen grey-box.
-- Offsets are from the grey-box part's center at Design size (front = -Z). Ids from Studio's 3D importer.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
local function Extras(world: Instance, apply: (BasePart, string) -> boolean)
	require(script.Parent.GlitchedCore).SavePoints(world, apply)
end

return { Skins = Skins, Dressing = Dressing, Decor = {}, Extras = Extras }
