-- Blender art on top of the grey-box worlds (BLENDER_PLAYBOOK.md §6, briefs/PrologueUI.md).
-- Skins: a grey-box part keeps its collision, tags and SurfaceGuis but turns invisible; non-colliding MeshParts
-- scaled to part.Size / DesignSize sit in its place. Gameplay never depends on the art loading.
-- Pip: a model template published to ReplicatedStorage.PipModel for the client PipController.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)

local NAVY = Color3.fromRGB(20, 24, 58)
local SLATE = Color3.fromRGB(46, 54, 112) -- panel bodies: lighter than NAVY so they read against the night sky
local WHITE = Color3.fromRGB(240, 240, 250)
local PINK = Color3.fromRGB(255, 80, 170)
local SMOOTH = Enum.Material.SmoothPlastic

type Skin = { Design: Vector3, Meshes: { [string]: MeshAssets.MeshInfo } }

-- Offsets are from the grey-box part's center, at DesignSize (front = -Z).
local Skins: { [string]: Skin } = {
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
				Color = PINK,
			},
		},
	},
}

-- Which grey-box part (by name) gets which skin, per world.
local Dressing: { [string]: { [string]: string } } = {
	Prologue = {
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
	},
}

local PipMeshes: { [string]: MeshAssets.MeshInfo } = {
	Pip_Body = {
		Id = "rbxassetid://135129700526761",
		Offset = Vector3.new(0, -0.5, 0.01),
		Size = Vector3.new(2, 2, 0.75),
		Material = SMOOTH,
		Color = Color3.fromRGB(250, 245, 230),
	},
	Pip_Face = {
		Id = "rbxassetid://123843613543931",
		Offset = Vector3.new(0, -0.75, -0.335),
		Size = Vector3.new(1, 1, 0.1),
		Material = SMOOTH,
		Color = NAVY,
	},
	Pip_Cheek = {
		Id = "rbxassetid://107122889950116",
		Offset = Vector3.new(0, -0.875, -0.335),
		Size = Vector3.new(1.5, 0.25, 0.1),
		Material = SMOOTH,
		Color = Color3.fromRGB(255, 120, 190),
	},
	Pip_Wing = {
		Id = "rbxassetid://95379349566842",
		Offset = Vector3.new(0, -0.5, 0.26),
		Size = Vector3.new(3.5, 1, 0.25),
		Material = SMOOTH,
		Color = PINK,
	},
	Pip_Star = {
		Id = "rbxassetid://99816899660790",
		Offset = Vector3.new(-0.125, 1.25, 0.01),
		Size = Vector3.new(0.75, 0.5, 0.25),
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 205, 40),
	},
	Pip_Antenna = {
		Id = "rbxassetid://104360292988220",
		Offset = Vector3.new(-0.125, 0.75, 0.01),
		Size = Vector3.new(0.25, 0.5, 0.25),
		Material = SMOOTH,
		Color = Color3.fromRGB(240, 240, 250),
	},
}

local ArtService = {}

local loaded: { [string]: { [string]: MeshPart } | false } = {} -- skin name → templates, false = failed

local function templatesFor(skinName: string): { [string]: MeshPart }?
	local cached = loaded[skinName]
	if cached == nil then
		cached = MeshAssets.Load(Skins[skinName].Meshes, skinName) or false
		loaded[skinName] = cached
	end
	return if cached then cached else nil
end

-- Puts a skin over one grey-box part. Returns false (part untouched) if the meshes aren't available.
function ArtService.Apply(part: BasePart, skinName: string): boolean
	local skin = Skins[skinName]
	local templates = skin and templatesFor(skinName)
	if not (skin and templates) or not part.Parent then
		return false
	end
	local k = part.Size / skin.Design
	for name, info in skin.Meshes do
		local p = templates[name]:Clone()
		p.Size = info.Size * k
		p.CFrame = part.CFrame * CFrame.new(info.Offset * k)
		p.Parent = part
	end
	part.Transparency = 1
	return true
end

-- Dresses a freshly built grey-box world. Runs in the background: shells pop in once the meshes load.
function ArtService.Dress(world: Instance, worldName: string)
	local map = Dressing[worldName]
	if not map then
		return
	end
	task.spawn(function()
		for _, d in world:GetDescendants() do
			local skinName = map[d.Name]
			if skinName and d:IsA("BasePart") then
				ArtService.Apply(d, skinName)
			end
		end
	end)
end

function ArtService.Init()
	task.spawn(function()
		local templates = MeshAssets.Load(PipMeshes, "Pip")
		if not templates then
			return
		end
		local model = Instance.new("Model")
		model.Name = "PipModel"
		for name, info in PipMeshes do
			local p = templates[name]
			p.CFrame = CFrame.new(info.Offset)
			p.CastShadow = false
			p.Parent = model
		end
		model.PrimaryPart = templates.Pip_Body
		local glow = Instance.new("PointLight") -- keeps Pip readable in dark worlds
		glow.Color = Color3.fromRGB(255, 235, 200)
		glow.Range = 8
		glow.Brightness = 1.2
		glow.Parent = templates.Pip_Body
		model.Parent = ReplicatedStorage
	end)
end

return ArtService
