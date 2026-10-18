-- Pip hints (user, Oct 19: "only when needed", "only what player you are", "aware where the player is").
-- A player gets a hint when the duo is really stuck: Tuning.HintAfter seconds without progress while someone is
-- moving (standing still / AFK doesn't count), or Tuning.HintDeaths setbacks (downed or fallen) in one section.
-- The line comes from Config/Hints: the entries of the duo's current section (checkpoint order), the one nearest to
-- this player, in this player's role (Kai never hears Miko's job). A section without hints = Pip stays quiet.
-- Boss fights: entries carry `phase`; a duo stuck Tuning.HintBossAfter seconds in one phase gets that phase's hint
-- once, and setbacks work as everywhere.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Hints = require(ReplicatedStorage.Shared.Config.Hints)
local Net = require(ReplicatedStorage.Shared.Net)
local CheckpointService = require(script.Parent.CheckpointService)

local HintService = {}

local hintEvent = Net.event("Hint")
local stuck = 0 -- seconds without progress while someone moved
local sent = 0 -- auto hints since the last progress
local enabled = true
local setbacks: { [Player]: number } = {}
local lastPos: { [Player]: Vector3 } = {}
local phaseSince, phaseHinted, lastPhase = 0, false, nil

function HintService.Progress()
	stuck = 0
	sent = 0
	table.clear(setbacks)
end

function HintService.SetEnabled(on: boolean)
	enabled = on
	HintService.Progress()
end

-- A line for everyone (story moments); hints go through HintService.Hint.
function HintService.Say(text: string)
	hintEvent:FireAllClients(text)
end

local function rootOf(p: Player): BasePart?
	local c = p.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- The checkpoint pad of this world with this Order (hint spots are offsets from it: sections can be moved).
local function checkpointPart(world: string, order: number): BasePart?
	for _, cp in CollectionService:GetTagged("Checkpoint") do
		if
			cp:IsA("BasePart")
			and cp:IsDescendantOf(workspace)
			and cp:GetAttribute("Order") == order
			and (cp:GetAttribute("World") == nil or cp:GetAttribute("World") == world)
		then
			return cp
		end
	end
	return nil
end

-- The hint for this player where they stand, or nil. level 2 = the more direct line when an entry has one.
-- Entry: { cp = section, off = Vector3? (from that checkpoint pad), r = studs?, phase = boss phase?, Kai/Miko/Both,
-- Kai2/Miko2/Both2 }. Entries with a spot: the nearest one within r wins; entries without one are the fallback.
function HintService.LineFor(p: Player, level: number): string?
	local world = workspace:GetAttribute("World")
	local list = world and (Hints :: any)[world]
	if not list then
		return nil
	end
	local section = CheckpointService.Current()
	local pad = checkpointPart(world, section)
	local root = rootOf(p)
	local phase = workspace:GetAttribute("BossPhase")
	local best, bestD = nil, math.huge
	for _, e in list do
		if e.cp ~= section or (e.phase ~= nil and e.phase ~= phase) then
			continue
		end
		local d = 1e6 -- no spot: fallback
		if e.off and pad and root then
			d = (root.Position - (pad.Position + e.off)).Magnitude
			if e.r and d > e.r then
				continue
			end
		end
		if d < bestD then
			best, bestD = e, d
		end
	end
	if not best then
		return nil
	end
	local role = p:GetAttribute("Role")
	local function pick(key: string): string?
		return best[key .. (if level >= 2 then "2" else "")] or best[key]
	end
	return (role and pick(role)) or pick("Both")
end

function HintService.Hint(p: Player, level: number): boolean
	if p:GetAttribute("InCutscene") then
		return false
	end
	local line = HintService.LineFor(p, level)
	if line then
		hintEvent:FireClient(p, line)
		return true
	end
	return false
end

local function setback(p: Player)
	if not enabled then
		return
	end
	setbacks[p] = (setbacks[p] or 0) + 1
	if setbacks[p] % Tuning.HintDeaths == 0 then
		HintService.Hint(p, math.max(2, sent + 1))
	end
end

local function watch(p: Player)
	for _, attr in { "Downed", "Falling" } do
		p:GetAttributeChangedSignal(attr):Connect(function()
			if p:GetAttribute(attr) then
				setback(p)
			end
		end)
	end
end

function HintService.Init()
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		setbacks[p] = nil
		lastPos[p] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			-- someone moving = trying; idle or AFK duos don't get nagged
			local moved = false
			for _, p in Players:GetPlayers() do
				local root = rootOf(p)
				if root then
					local before = lastPos[p]
					if before and (root.Position - before).Magnitude > Tuning.HintMoveStuds then
						moved = true
					end
					lastPos[p] = root.Position
				end
			end
			if not enabled then
				continue
			end
			if workspace:GetAttribute("BossFight") then
				-- boss: one hint per phase after a while in it
				local phase = workspace:GetAttribute("BossPhase")
				if phase ~= lastPhase then
					lastPhase, phaseSince, phaseHinted = phase, os.clock(), false
				end
				if not phaseHinted and os.clock() - phaseSince >= Tuning.HintBossAfter then
					phaseHinted = true
					for _, p in Players:GetPlayers() do
						HintService.Hint(p, 1)
					end
				end
				continue
			end
			lastPhase = nil
			if not moved then
				continue
			end
			stuck += 1
			local nextAt = Tuning.HintAfter[sent + 1]
			if nextAt and stuck >= nextAt then
				sent += 1
				for _, p in Players:GetPlayers() do
					HintService.Hint(p, sent)
				end
			end
		end
	end)
end

return HintService
