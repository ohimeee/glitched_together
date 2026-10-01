-- Stations (obstacles.md Part 3; It Takes Two's "operator and runner"): a crank one player holds (they're rooted
-- while cranking, like a player who can't move while using their tool) while their forward / back input drives a
-- linked Driven mover; the partner platforms on what it moves. Let go and it eases back home, so the operator has
-- to keep at it. A frozen driven mover stays where it is, so Kai can freeze a bridge out and free the operator.
--
-- Level data: a BasePart tagged `Station` with one or more ObjectValues named `Drives` pointing at Driven movers
-- (MoverService), optional `Owner` = "Kai" | "Miko" (only that role can crank it).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Net = require(ReplicatedStorage.Shared.Net)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)
local MoverService = require(script.Parent.MoverService)

local T = Tuning.Station
local StationService = {}

type Station = { part: BasePart, prompt: ProximityPrompt, occupant: Player?, axis: number, home: CFrame }
local stations: { [BasePart]: Station } = {}
local inputEvent = Net.event("StationInput")

local function targets(part: BasePart): { Instance }
	local list = {}
	for _, v in part:GetChildren() do
		if v:IsA("ObjectValue") and v.Name == "Drives" and v.Value then
			table.insert(list, v.Value)
		end
	end
	return list
end

local function release(s: Station)
	local p = s.occupant
	s.occupant = nil
	s.axis = 0
	for _, target in targets(s.part) do
		MoverService.Drive(target, 0)
	end
	s.prompt.ActionText = "Crank"
	if p then
		p:SetAttribute("Station", nil)
	end
end

local function occupy(s: Station, p: Player)
	s.occupant = p
	s.axis = 0
	p:SetAttribute("Station", s.part.Name)
	s.prompt.ActionText = "Let go"
	Audio.play("Lever", s.part)
end

local function register(part: Instance)
	if not part:IsA("BasePart") or stations[part] then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StationPrompt"
	prompt.ActionText = "Crank"
	local owner = part:GetAttribute("Owner")
	prompt.ObjectText = if owner then `{owner}'s crank: W / S` else "Crank: W / S"
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = T.Reach
	prompt.Parent = part
	local s: Station = { part = part, prompt = prompt, occupant = nil, axis = 0, home = part.CFrame }
	stations[part] = s
	-- one press = one toggle: in a 2-player Studio test each E press arrived twice, grabbing and instantly
	-- letting go of the crank (playtest Oct 1)
	local lastPress: { [Player]: number } = {}
	prompt.Triggered:Connect(function(p: Player)
		if os.clock() - (lastPress[p] or -math.huge) < T.PressDebounce then
			return
		end
		lastPress[p] = os.clock()
		if s.occupant == p then
			release(s)
		elseif not s.occupant and not p:GetAttribute("Downed") then
			local owner = part:GetAttribute("Owner")
			if owner == nil or p:GetAttribute("Role") == owner then
				occupy(s, p)
			end
		end
	end)
	-- Studio test hook (prompts can't be pressed from a scripted playtest): set DebugOccupant to a player's name.
	if RunService:IsStudio() then
		part:GetAttributeChangedSignal("DebugOccupant"):Connect(function()
			local p = Players:FindFirstChild((part:GetAttribute("DebugOccupant") or "") :: string)
			if p and p:IsA("Player") then
				occupy(s, p)
			else
				release(s)
			end
		end)
	end
end

local function unregister(part: Instance)
	local s = stations[part :: BasePart]
	if s then
		release(s)
		stations[part :: BasePart] = nil
	end
end

function StationService.Init()
	Tags.each("Station", register, unregister)
	inputEvent.OnServerEvent:Connect(function(p: Player, axis: number)
		if type(axis) ~= "number" or axis ~= axis then
			return
		end
		for _, s in stations do
			if s.occupant == p then
				s.axis = math.clamp(axis, -1, 1)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		for _, s in stations do
			if s.occupant == p then
				release(s)
			end
		end
	end)
	RunService.Heartbeat:Connect(function(dt)
		for part, s in stations do
			local p = s.occupant
			if not p then
				continue
			end
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if
				not part.Parent
				or not root
				or p:GetAttribute("Downed")
				or (root.Position - part.Position).Magnitude > T.Reach + 4
			then
				release(s)
				continue
			end
			for _, target in targets(part) do
				MoverService.Drive(target, s.axis)
			end
			-- the crank wheel turns with the input (it spins around its own X axis, like a ship's wheel facing you)
			if s.axis ~= 0 then
				part.CFrame *= CFrame.Angles(s.axis * dt * T.WheelSpin, 0, 0)
			end
		end
	end)
end

return StationService
