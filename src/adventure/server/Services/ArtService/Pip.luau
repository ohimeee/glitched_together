-- Pip, the floating companion: Roblox Studio generate_mesh (textured glossy voxel sprite, the graphics
-- baseline), split into Body / WingL / WingR / Antenna so PipController can flap the wings. The generation faced
-- +Z; offsets here are already turned 180° (face on -Z, as PipController expects) and every part gets Yaw = 180.
-- ArtService builds ReplicatedStorage.PipModel from this (pivot = Body).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)

local SMOOTH = Enum.Material.SmoothPlastic
local v = Vector3.new

local PipMeshes: { [string]: MeshAssets.MeshInfo } = {
	Body = {
		Id = "rbxassetid://79472728381879",
		TextureId = "rbxassetid://100885623527464",
		Offset = v(0.001, -0.222, 0),
		Size = v(1.583, 1.95, 1.6),
		Material = SMOOTH,
		Yaw = 180,
	},
	WingL = {
		Id = "rbxassetid://120702701400605",
		TextureId = "rbxassetid://80331020612231",
		Offset = v(-0.946, -0.024, -0.078),
		Size = v(0.696, 1.336, 0.476),
		Material = SMOOTH,
		Yaw = 180,
	},
	WingR = {
		Id = "rbxassetid://74852559275551",
		TextureId = "rbxassetid://126383625960546",
		Offset = v(0.947, -0.025, -0.078),
		Size = v(0.694, 1.336, 0.475),
		Material = SMOOTH,
		Yaw = 180,
	},
	Antenna = {
		Id = "rbxassetid://111170738058732",
		TextureId = "rbxassetid://115898407403995",
		Offset = v(-0.375, 0.845, -0.218),
		Size = v(0.36, 0.704, 0.173),
		Material = SMOOTH,
		Yaw = 180,
	},
}

return PipMeshes
