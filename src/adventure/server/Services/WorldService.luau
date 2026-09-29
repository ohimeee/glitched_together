-- Loads worlds, hands out kits and camera modes, spawns players, and moves the duo to the next world.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Kits = require(ReplicatedStorage.Shared.Config.Kits)
local Worlds = require(ReplicatedStorage.Shared.Config.Worlds)
local DuoService = require(script.Parent.DuoService)
local SaveService = require(script.Parent.SaveService)
local CheckpointService = require(script.Parent.CheckpointService)
local Greybox = require(script.Parent.Parent.Greybox)
local ArtService = require(script.Parent.ArtService)

local WorldService = {}
WorldService.Current = "Prologue"

local loaded = Instance.new("BindableEvent")
WorldService.Loaded = loaded.Event -- (worldName)
local advancing = false

function WorldService.SetKit(p: Player, tool: string?, camera: string?)
	p:SetAttribute("Kit", tool)
	p:SetAttribute("CameraMode", camera or "Follow")
end

local function applyKit(p: Player)
	local role = p:GetAttribute("Role")
	local kit = Kits.Worlds[WorldService.Current]
	if not (role and kit) then
		return
	end
	WorldService.SetKit(p, (kit :: any)[role], kit.Camera)
	-- Castle is top-down with no jumping (mechanics.md §4, World 2).
	p:SetAttribute("NoJump", kit.Camera == "TopDown")
end

function WorldService.SpawnPlayer(p: Player)
	local character = p.Character
	if not character then
		return
	end
	local cf = CheckpointService.SpawnCFrame(p)
	pcall(function()
		p:RequestStreamAroundAsync(cf.Position, 5)
	end)
	character:PivotTo(cf)
end

function WorldService.Load(worldName: string, checkpoint: number?)
	WorldService.Current = worldName
	workspace:SetAttribute("World", worldName)

	local old = workspace:FindFirstChild("World")
	if old then
		old:Destroy()
	end

	local source = ServerStorage:FindFirstChild("Worlds") and (ServerStorage :: any).Worlds:FindFirstChild(worldName)
	local model: Instance
	if source then
		model = source:Clone()
	else
		model = Greybox.Build(worldName) -- grey-box until the real world is built in Studio
	end
	model.Name = "World"
	model.Parent = workspace
	if not source then
		ArtService.Dress(model, worldName)
	end

	local info = Worlds.ByName[worldName]
	if info then
		Worlds.ApplyLook(info.Look)
	end

	CheckpointService.Reset(worldName, checkpoint or 0)
	for _, p in DuoService.Players() do
		applyKit(p)
		WorldService.SpawnPlayer(p)
	end
	loaded:Fire(worldName)
end

-- Both players reached the exit: unlock and load the next world.
function WorldService.Advance()
	if advancing then
		return
	end
	advancing = true
	local index = table.find(Worlds.Order, WorldService.Current) or 0
	local nextWorld = Worlds.Order[index + 1]
	if not nextWorld then
		SaveService.Set({ complete = true })
		SaveService.Flush()
		advancing = false
		return
	end
	SaveService.Unlock(nextWorld)
	SaveService.Set({ world = nextWorld, checkpoint = 0 })
	task.spawn(SaveService.Flush)
	WorldService.Load(nextWorld, 0)
	advancing = false
end

-- Exit portals (tag WorldExit): the world ends only when BOTH players stand inside (a sync point).
local function watchExits()
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	while true do
		task.wait(0.25)
		local duo = DuoService.Players()
		if #duo < 2 then
			continue
		end
		local chars = {}
		for _, p in duo do
			if p.Character then
				table.insert(chars, p.Character)
			end
		end
		overlap.FilterDescendantsInstances = chars
		for _, exit in game:GetService("CollectionService"):GetTagged("WorldExit") do
			if exit:IsA("BasePart") and exit:IsDescendantOf(workspace) then
				local inside = {}
				for _, part in workspace:GetPartBoundsInBox(exit.CFrame, exit.Size, overlap) do
					local p = Players:GetPlayerFromCharacter(part:FindFirstAncestorOfClass("Model"))
					if p then
						inside[p] = true
					end
				end
				if inside[duo[1]] and inside[duo[2]] then
					WorldService.Advance()
					break
				end
			end
		end
	end
end

function WorldService.Init()
	DuoService.Changed:Connect(function(p: Player)
		applyKit(p)
	end)

	local function hook(p: Player)
		p.CharacterAdded:Connect(function()
			task.defer(WorldService.SpawnPlayer, p)
		end)
	end
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)

	CheckpointService.Reached:Connect(function(order: number)
		SaveService.Set({ world = WorldService.Current, checkpoint = order })
		task.spawn(SaveService.Flush)
	end)

	task.spawn(watchExits)
end

return WorldService
