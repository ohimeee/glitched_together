-- Role badges (blender_assets/Identity.*): a white rounded plate with Kai's ▲ or Miko's ● worn on the back
-- (BodyBackAttachment), where the partner's third-person camera sees it most. Colors survive every costume
-- (art-direction.md §5: "signature color on every outfit").
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)

local SMOOTH = Enum.Material.SmoothPlastic

local Meshes: { [string]: MeshAssets.MeshInfo } = {
	SH_Prop_Badge_Plate = {
		Id = "rbxassetid://120576043282507",
		Offset = Vector3.zero,
		Size = Vector3.new(1.8, 1.8, 0.3),
		Material = SMOOTH,
		Color = Palette.Duo,
	},
	SH_Prop_Badge_Tri = {
		Id = "rbxassetid://100706862898250",
		Offset = Vector3.new(0, 0.039, -0.225),
		Size = Vector3.new(1.211, 1.06, 0.25),
		Material = Enum.Material.Neon,
		Color = Palette.Glow.Kai,
	},
	SH_Prop_Badge_Circle = {
		Id = "rbxassetid://111396652980128",
		Offset = Vector3.new(0, 0, -0.225),
		Size = Vector3.new(1.1, 1.1, 0.25),
		Material = Enum.Material.Neon,
		Color = Palette.Glow.Miko,
	},
}

return {
	Meshes = Meshes,
	Emblem = { Kai = "SH_Prop_Badge_Tri", Miko = "SH_Prop_Badge_Circle" },
	Scale = 0.85,
	BackOffset = 0.25, -- studs behind BodyBackAttachment
}
