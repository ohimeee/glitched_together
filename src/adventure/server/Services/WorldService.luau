-- Loads worlds, hands out kits and camera modes, spawns players, and moves the duo to the next world.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Kits = require(ReplicatedStorage.Shared.Config.Kits)
local Worlds = require(ReplicatedStorage.Shared.Config.Worlds)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Net = require(ReplicatedStorage.Shared.Net)
local Places = require(ReplicatedStorage.Shared.Config.Places)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local DuoService = require(script.Parent.DuoService)
local SaveService = require(script.Parent.SaveService)
local CheckpointService = require(script.Parent.CheckpointService)
local Greybox = require(script.Parent.Parent.Greybox)
local ArtService = require(script.Parent.ArtService)

local WorldService = {}
WorldService.Current = "Prologue"

local loaded = Instance.new("BindableEvent")
WorldService.Loaded = loaded.Event -- (worldName, restart: boolean?)
local advancing = false

function WorldService.SetKit(p: Player, tool: string?, camera: string?)
	if p:GetAttribute("Kit") ~= tool then
		-- a held tool state never carries into the next kit (2P playtest Oct 11: Miko's raised shield followed her into
		-- the Glitched Core: the client's "release" reached the server after the kit had already changed)
		p:SetAttribute("Blocking", nil)
		p:SetAttribute("SwordSwing", nil)
	end
	p:SetAttribute("Kit", tool)
	p:SetAttribute("CameraMode", camera or "Follow")
end

-- Kit zones (3-3 Memory Lane, Story Line: "all three ability sets as they swap automatically per area"): a part
-- tagged `KitZone` with `Kit` = a world name hands whoever stands in it that world's kit and camera (Prologue = no
-- tools). Outside every zone you hold the current world's kit.
local zoneOf: { [Player]: string } = {}
-- the final boss swaps everyone's kit per phase (ForceKit) without leaving the Core; beats any zone
local forced: string? = nil

local function applyKit(p: Player)
	local role = p:GetAttribute("Role")
	local kit = Kits.Worlds[forced or zoneOf[p] or WorldService.Current]
	if not (role and kit) then
		return
	end
	WorldService.SetKit(p, (kit :: any)[role], kit.Camera)
	-- Castle is top-down with no jumping (mechanics.md §4, World 2).
	p:SetAttribute("NoJump", kit.Camera == "TopDown")
end

-- Hand every player `world`'s kit and camera (nil = back to the current world's own)
function WorldService.ForceKit(world: string?)
	forced = world
	for _, p in DuoService.Players() do
		applyKit(p)
	end
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

local loadToken = 0

local function freeze(on: boolean)
	for _, p in DuoService.Players() do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			root.Anchored = on
		end
	end
end

-- `restart`: a game over reloading the same world (Loaded listeners keep progress like castle levels).
-- Loading screen (client LoadingController): workspace `WorldLoading` = true (+ `LoadingWorld`, `LoadProgress` 0..1)
-- while the world builds and dresses; the duo waits frozen, then spawns into the finished world (art nearest the
-- spawn is dressed first). Yields until then, at most Tuning.WorldLoad.Timeout s. Then the next world's art starts
-- downloading in the background so the next load is quick.
function WorldService.Load(worldName: string, checkpoint: number?, restart: boolean?)
	loadToken += 1
	local token = loadToken
	WorldService.Current = worldName
	workspace:SetAttribute("World", worldName)
	workspace:SetAttribute("LoadingWorld", worldName)
	workspace:SetAttribute("LoadProgress", 0)
	workspace:SetAttribute("WorldLoading", true)
	freeze(true)

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
	CheckpointService.Reset(worldName, checkpoint or 0)
	if source then
		model:SetAttribute("Dressed", true)
	else
		ArtService.Dress(model, worldName, CheckpointService.SpawnCFrame(nil).Position, function(k)
			if token == loadToken then
				workspace:SetAttribute("LoadProgress", k)
			end
		end)
	end

	local info = Worlds.ByName[worldName]
	if info then
		Worlds.ApplyLook(info.Look)
	end

	local started = os.clock()
	while
		not model:GetAttribute("Dressed")
		and os.clock() - started < Tuning.WorldLoad.Timeout
		and token == loadToken
	do
		task.wait(0.1)
	end
	if token ~= loadToken then
		return -- a newer Load took over (Studio world jumps)
	end

	table.clear(zoneOf)
	forced = nil
	for _, p in DuoService.Players() do
		applyKit(p)
		WorldService.SpawnPlayer(p)
	end
	freeze(false)
	workspace:SetAttribute("WorldLoading", false)
	loaded:Fire(worldName, restart)

	local index = table.find(Worlds.Order, worldName)
	local nextWorld = index and Worlds.Order[index + 1]
	if nextWorld then
		task.spawn(ArtService.Preload, nextWorld)
	end
end

-- The game is finished: mark the save complete and send these players home to the lobby (the Epilogue's exit, both
-- inside it, or one player pressing its [E] TELEPORT). Studio / no Lobby id: only a warning and a hint line.
function WorldService.ToLobby(players: { Player })
	SaveService.Set({ complete = true })
	SaveService.Flush()
	if Places.Lobby == 0 or RunService:IsStudio() then
		warn("[WorldService] Would return to Lobby (skipped: Studio or no Lobby id).")
		for _, p in players do
			Net.event("Hint"):FireClient(p, "Back to the lobby: works once the game is published.")
		end
		return
	end
	local ok, err = pcall(function()
		TeleportService:TeleportAsync(Places.Lobby, players)
	end)
	if not ok then
		warn("[WorldService] Lobby teleport failed:", err)
	end
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
		-- past the last world (the Epilogue's BACK TO LOBBY exit): the duo goes home together
		WorldService.ToLobby(DuoService.Players())
		task.wait(3) -- don't fire again every 0.25 s while they still stand inside
		advancing = false
		return
	end
	SaveService.Unlock(nextWorld)
	SaveService.Set({ world = nextWorld, checkpoint = 0 })
	task.spawn(SaveService.Flush)
	WorldService.Load(nextWorld, 0)
	advancing = false
end

-- Exit portals (tag WorldExit): the world ends only when BOTH players stand inside (a sync point). A `Locked` exit
-- (behind a boss) doesn't count until the boss falls.
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
			if exit:IsA("BasePart") and exit:IsDescendantOf(workspace) and not exit:GetAttribute("Locked") then
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

local function inside(part: BasePart, pos: Vector3): boolean
	local lp = part.CFrame:PointToObjectSpace(pos)
	local h = part.Size / 2
	return math.abs(lp.X) <= h.X and math.abs(lp.Y) <= h.Y and math.abs(lp.Z) <= h.Z
end

local function watchKitZones()
	while true do
		task.wait(Tuning.KitZoneCheck)
		local zones = Tags.list("KitZone")
		for _, p in DuoService.Players() do
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not root or p:GetAttribute("Falling") or p:GetAttribute("Downed") then
				continue -- keep the kit while being put back after a fall
			end
			local want: string? = nil
			for _, zone in zones do
				if zone:IsA("BasePart") and inside(zone, root.Position) then
					want = zone:GetAttribute("Kit") :: string?
					break
				end
			end
			if want ~= zoneOf[p] then
				zoneOf[p] = want :: any
				applyKit(p)
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
	task.spawn(watchKitZones)
	Players.PlayerRemoving:Connect(function(p)
		zoneOf[p] = nil
	end)
end

return WorldService
