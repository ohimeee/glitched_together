-- Pip, the floating companion (blender_assets/Pip.*): split per material. ArtService builds ReplicatedStorage.PipModel.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)

local SMOOTH = Enum.Material.SmoothPlastic

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
		Color = Palette.Prologue.Navy,
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
		Color = Palette.Prologue.Pink, -- Pip's own color, not the Glitch
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

return PipMeshes
