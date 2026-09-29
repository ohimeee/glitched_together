-- Mesh data for the lobby capsule pair (blender_assets/LobbyCapsule.fbx, brief: blender_assets/briefs/LobbyCapsule.md).
-- Ids come from Studio's 3D importer. Offsets are in studs, in the capsule's own frame (front/door = -Z):
--   Capsule_* : from the capsule's bottom center. Modeled as Kai's capsule; Miko uses the same meshes recolored.
--   Emblems   : Tri sits on Kai's dome, Circle on Miko's (same offset idea).
--   Marquee_* : from the pair's center on the ground (between the two capsules).
-- Knob: as imported it sits on +X; LobbyBuilder turns it 180° for the capsule on the pair's -X side so it always faces out.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)

local NAVY = Palette.Prologue.Navy
local WHITE = Palette.Prologue.White
local GLITCH = Palette.Glitch

-- Color nil = the role's color.
local Meshes: { [string]: MeshAssets.MeshInfo } = {
	Capsule_Base = {
		Id = "rbxassetid://108644351274377",
		Offset = Vector3.new(0, 0.275, 0),
		Size = Vector3.new(9.6, 0.55, 9.6),
		Material = Enum.Material.SmoothPlastic,
		Color = NAVY,
		Collision = Enum.CollisionFidelity.Hull,
	},
	Capsule_Frame = {
		Id = "rbxassetid://110572287333692",
		Offset = Vector3.new(0, 5.85, 0),
		Size = Vector3.new(9.5, 10.7, 9.5),
		Material = Enum.Material.SmoothPlastic,
		Color = WHITE,
		Collision = Enum.CollisionFidelity.PreciseConvexDecomposition, -- keeps the doorway open
	},
	Capsule_Glass = {
		Id = "rbxassetid://115768286739139",
		Offset = Vector3.new(0, 5.35, 1.005),
		Size = Vector3.new(8.04, 8.9, 6.03),
		Material = Enum.Material.Glass,
		Transparency = 0.55,
		Collision = Enum.CollisionFidelity.PreciseConvexDecomposition,
	},
	Capsule_Glow_Role = {
		Id = "rbxassetid://72676888275205",
		Offset = Vector3.new(0, 5.34, 0),
		Size = Vector3.new(7.5, 8.96, 7.5),
		Material = Enum.Material.Neon,
	},
	Capsule_Dome_Role = {
		Id = "rbxassetid://101804613466820",
		Offset = Vector3.new(0, 12.529, 0),
		Size = Vector3.new(8.9, 2.759, 8.9),
		Material = Enum.Material.SmoothPlastic,
		Collision = Enum.CollisionFidelity.Hull,
	},
	Capsule_Knob_Role = {
		Id = "rbxassetid://106494233915239",
		Offset = Vector3.new(5.112, 10.5, 0),
		Size = Vector3.new(0.875, 1.9, 1.9),
		Material = Enum.Material.SmoothPlastic,
	},
	Capsule_Emblem_Tri = {
		Id = "rbxassetid://77494926759815",
		Offset = Vector3.new(0, 14.61, 0),
		Size = Vector3.new(2.39, 2.102, 0.56),
		Material = Enum.Material.SmoothPlastic,
		Color = WHITE,
	},
	Capsule_Emblem_Circle = {
		Id = "rbxassetid://133332033957757",
		Offset = Vector3.new(0, 14.709, 0),
		Size = Vector3.new(2.3, 2.3, 0.56),
		Material = Enum.Material.SmoothPlastic,
		Color = WHITE,
	},
	Marquee_Frame = {
		Id = "rbxassetid://126185367789518",
		Offset = Vector3.new(0, 15.75, 0),
		Size = Vector3.new(9, 5.7, 1.4),
		Material = Enum.Material.SmoothPlastic,
		Color = WHITE,
		Collision = Enum.CollisionFidelity.Hull,
	},
	Marquee_Screen = {
		Id = "rbxassetid://83111884758357",
		Offset = Vector3.new(0, 16.5, -0.4),
		Size = Vector3.new(8, 3.2, 0.12),
		Material = Enum.Material.SmoothPlastic,
		Color = NAVY,
	},
	Marquee_Glitch = {
		Id = "rbxassetid://111129027748995",
		Offset = Vector3.new(0.025, 16.55, -0.05),
		Size = Vector3.new(10.74, 5.69, 0.49),
		Material = Enum.Material.Neon,
		Color = GLITCH,
	},
}

return {
	Meshes = Meshes,
	CapsuleParts = {
		"Capsule_Base",
		"Capsule_Frame",
		"Capsule_Glass",
		"Capsule_Glow_Role",
		"Capsule_Dome_Role",
		"Capsule_Knob_Role",
	},
	Emblem = { Triangle = "Capsule_Emblem_Tri", Circle = "Capsule_Emblem_Circle" },
	MarqueeParts = { "Marquee_Frame", "Marquee_Glitch" },
	Screen = "Marquee_Screen", -- becomes the pair's "Screen" (SurfaceGui.Status on its Front face)
}
