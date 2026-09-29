-- Collision groups (implementation.md §8, Glitched Core): Code Layer parts are only solid for Miko while shifted.
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local Tags = require(game:GetService("ReplicatedStorage").Shared.Util.Tags)

local CollisionService = {}

local function setGroup(character: Model, group: string)
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") then
			d.CollisionGroup = group
		end
	end
end

function CollisionService.SetShifted(p: Player, shifted: boolean)
	if p.Character then
		setGroup(p.Character, if shifted then "MikoShifted" else "Miko")
	end
end

function CollisionService.Init()
	for _, name in { "CodeLayer", "Kai", "Miko", "MikoShifted", "Ghost" } do
		PhysicsService:RegisterCollisionGroup(name)
	end
	PhysicsService:CollisionGroupSetCollidable("CodeLayer", "Default", false)
	PhysicsService:CollisionGroupSetCollidable("CodeLayer", "Kai", false)
	PhysicsService:CollisionGroupSetCollidable("CodeLayer", "Miko", false)
	PhysicsService:CollisionGroupSetCollidable("CodeLayer", "Ghost", false)
	PhysicsService:CollisionGroupSetCollidable("CodeLayer", "MikoShifted", true)
	-- Players never block each other (a partner standing in a doorway shouldn't trap you).
	PhysicsService:CollisionGroupSetCollidable("Kai", "Miko", false)
	PhysicsService:CollisionGroupSetCollidable("Kai", "MikoShifted", false)

	Tags.each("CodeLayer", function(inst)
		if inst:IsA("BasePart") then
			inst.CollisionGroup = "CodeLayer"
		end
		for _, d in inst:GetDescendants() do
			if d:IsA("BasePart") then
				d.CollisionGroup = "CodeLayer"
			end
		end
	end)

	local function hook(p: Player)
		p.CharacterAdded:Connect(function(character)
			local role = p:GetAttribute("Role")
			local group = if role == "Miko" then "Miko" else "Kai"
			setGroup(character, group)
			character.DescendantAdded:Connect(function(d)
				if d:IsA("BasePart") then
					d.CollisionGroup = group
				end
			end)
		end)
	end
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)
end

return CollisionService
