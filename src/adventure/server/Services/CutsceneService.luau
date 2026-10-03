-- Cutscenes (implementation.md §11). Camera paths live in ReplicatedStorage.Cutscenes.<id> as parts named 1, 2, 3…
-- with a `Duration` attribute; lines come from Config/Dialogue. Skippable only when BOTH players vote skip.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Dialogue = require(ReplicatedStorage.Shared.Config.Dialogue)
local Net = require(ReplicatedStorage.Shared.Net)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local DuoService = require(script.Parent.DuoService)

local CutsceneService = {}

local cutsceneEvent = Net.event("Cutscene")
local skipEvent = Net.event("SkipVote")
local doneEvent = Net.event("CutsceneDone")

local playing: string? = nil
local seen: { [string]: boolean } = {} -- `Once` triggers: played this session (survives game-over reloads)

export type Shot = { CFrame: CFrame, Duration: number }

-- Camera shots for a cutscene in the loaded world (sent to clients, so streaming never hides a path part):
--   Reveal_<Section>: a fly-over framed from the section's bounds (high 3/4 over its start, then across to its far end)
--   CamPath_<id>: a Folder in the world with parts 1, 2, 3… (Duration attribute), built with the level
function CutsceneService.Shots(id: string): { Shot }?
	local world = workspace:FindFirstChild("World")
	if not world then
		return nil
	end
	local section = string.match(id, "^Reveal_(.+)$")
	if section then
		local m = world:FindFirstChild(section)
		if not (m and m:IsA("Model")) then
			return nil
		end
		local cf, size = m:GetBoundingBox()
		local c = cf.Position
		local reach = math.max(size.X, size.Z) * 0.5
		local nearAim = c - Vector3.new(0, size.Y * 0.2, size.Z * 0.2)
		local farAim = c + Vector3.new(0, 0, size.Z * 0.3)
		return {
			{
				CFrame = CFrame.lookAt(c + Vector3.new(reach * 0.6 + 25, size.Y * 0.5 + 30, -size.Z * 0.5), nearAim),
				Duration = 2.2,
			},
			{
				CFrame = CFrame.lookAt(c + Vector3.new(-(reach * 0.6 + 25), size.Y * 0.5 + 22, size.Z * 0.05), farAim),
				Duration = 2.6,
			},
		}
	end
	local path = world:FindFirstChild("CamPath_" .. id, true)
	if not path then
		return nil
	end
	local points = path:GetChildren()
	table.sort(points, function(a, b)
		return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
	end)
	local shots = {}
	for _, p in points do
		if p:IsA("BasePart") then
			table.insert(shots, { CFrame = p.CFrame, Duration = (p:GetAttribute("Duration") or 2) :: number })
		end
	end
	return shots
end
local skipVotes: { [Player]: boolean } = {}
local doneVotes: { [Player]: boolean } = {}

local function everyone(votes: { [Player]: boolean }): boolean
	local duo = DuoService.Players()
	if #duo == 0 then
		return true
	end
	for _, p in duo do
		if not votes[p] then
			return false
		end
	end
	return true
end

-- Plays a cutscene for both players and yields until it ends (or both skip). Max 60 s by design.
function CutsceneService.Play(id: string)
	if playing then
		return
	end
	playing = id
	table.clear(skipVotes)
	table.clear(doneVotes)
	workspace:SetAttribute("SkipVotes", 0)
	local lines = Dialogue.Cutscenes[id] or {}
	for _, p in DuoService.Players() do
		p:SetAttribute("InCutscene", true)
	end
	cutsceneEvent:FireAllClients(id, lines, CutsceneService.Shots(id))

	local start = os.clock()
	while os.clock() - start < 60 do
		if everyone(skipVotes) and next(skipVotes) then
			break
		end
		if everyone(doneVotes) and next(doneVotes) then
			break
		end
		task.wait(0.1)
	end

	cutsceneEvent:FireAllClients(nil) -- end on every client
	for _, p in DuoService.Players() do
		p:SetAttribute("InCutscene", nil)
	end
	playing = nil
end

function CutsceneService.Init()
	skipEvent.OnServerEvent:Connect(function(p: Player)
		if playing then
			skipVotes[p] = true
			local count = 0
			for _ in skipVotes do
				count += 1
			end
			workspace:SetAttribute("SkipVotes", count) -- clients show "1/2 want to skip"
		end
	end)
	doneEvent.OnServerEvent:Connect(function(p: Player)
		if playing then
			doneVotes[p] = true
		end
	end)

	-- Story triggers in a level: a part tagged `CutsceneTrigger` (attribute `Cutscene` = a Dialogue id) plays once,
	-- when the whole duo stands inside it (`Any`: when the first player does). Rebuilding the world (a game over)
	-- arms it again, unless it's `Once` (section reveals, boss intros: once per session).
	task.spawn(function()
		while true do
			task.wait(0.25)
			local duo = DuoService.Players()
			if playing or #duo == 0 then
				continue
			end
			for _, trigger in Tags.list("CutsceneTrigger") do
				if not trigger:IsA("BasePart") or trigger:GetAttribute("Played") then
					continue
				end
				local id = trigger:GetAttribute("Cutscene") :: string
				if trigger:GetAttribute("Once") and seen[id] then
					continue
				end
				local any = trigger:GetAttribute("Any") == true
				local inside, total = 0, 0
				for _, p in duo do
					total += 1
					local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					local lp = root and trigger.CFrame:PointToObjectSpace(root.Position)
					local h = trigger.Size / 2
					if lp and math.abs(lp.X) <= h.X and math.abs(lp.Y) <= h.Y and math.abs(lp.Z) <= h.Z then
						inside += 1
					end
				end
				if (any and inside > 0) or inside == total then
					trigger:SetAttribute("Played", true)
					seen[id] = true
					task.spawn(CutsceneService.Play, id)
					break
				end
			end
		end
	end)
end

return CutsceneService
