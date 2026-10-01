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
	cutsceneEvent:FireAllClients(id, lines)

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
	-- when the whole duo stands inside it. Rebuilding the world (a game over) arms it again.
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
				local all = true
				for _, p in duo do
					local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					local lp = root and trigger.CFrame:PointToObjectSpace(root.Position)
					local h = trigger.Size / 2
					if not (lp and math.abs(lp.X) <= h.X and math.abs(lp.Y) <= h.Y and math.abs(lp.Z) <= h.Z) then
						all = false
						break
					end
				end
				if all then
					trigger:SetAttribute("Played", true)
					task.spawn(CutsceneService.Play, trigger:GetAttribute("Cutscene") :: string)
					break
				end
			end
		end
	end)
end

return CutsceneService
