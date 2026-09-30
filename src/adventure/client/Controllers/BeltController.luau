-- Conveyor treads (ArtService skin textures tagged "BeltScroll") scroll at their belt's speed and stop while the
-- belt is frozen, so players can read a belt's direction and Kai's freeze at a glance. Purely visual, per client.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)

local BeltController = {}

local treads: { [Texture]: true } = {}
local SIGN = -1 -- on a belt's top face +V points back along its LookVector (checked in Studio)

function BeltController.Init()
	Tags.each("BeltScroll", function(inst)
		if inst:IsA("Texture") then
			treads[inst] = true
		end
	end, function(inst)
		treads[inst :: Texture] = nil
	end)

	RunService.RenderStepped:Connect(function(dt)
		for tread in treads do
			local mesh = tread.Parent
			local belt = mesh and mesh.Parent -- skin meshes are parented to their grey-box conveyor
			if not (belt and belt:IsA("BasePart")) or belt:GetAttribute("Frozen") then
				continue
			end
			local speed = (belt:GetAttribute("Speed") or Tuning.Contraptions.ConveyorSpeed) :: number
			-- V runs along the belt; the chevrons point (and scroll) the way it carries you
			tread.OffsetStudsV = (tread.OffsetStudsV + SIGN * speed * dt) % tread.StudsPerTileV
		end
	end)
end

return BeltController
