-- Admin trailer recording (user, Oct 18: record scenes + environments + a bit of gameplay for the game's trailer).
--   /trailer                     the caller's client enters / leaves trailer mode (client TrailerController: no UI,
--                                fly camera, camera paths; keys listed there)
--   /puppet kai|miko [userId]    a stand-in for the other character beside the caller: that avatar (default: a plain
--                                R15), role badge + the world's held kit items, idling
--   /puppet clip <MoveAnims name | idle>   loop a pose clip;  /puppet here   move it beside the caller;  /puppet off
--   /ghost rec [seconds]         the caller's client records its own character (3 s countdown) and sends it here
--   /ghost play | loop | stop    the puppet replays that take (position + every animation track) while the caller
--                                plays the other character live: two-player shots with one person
-- Effects (shots, beams, glows) are not part of a ghost: only body motion and animations.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Kits = require(ReplicatedStorage.Shared.Config.Kits)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local MoveAnims = require(ReplicatedStorage.Shared.Config.MoveAnims)
local Net = require(ReplicatedStorage.Shared.Net)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local ArtService = require(script.Parent.ArtService)

local T = Tuning.Trailer

local Trailer = {}

type Track = { id: string, t: number, speed: number }
type Sample = { cf: CFrame, tracks: { Track } }
type Ghost = { rate: number, hip: number, samples: { Sample } }

local puppet: Model? = nil
local loopTrack: AnimationTrack? = nil
local ghosts: { [Player]: Ghost } = {}
local incoming: { [Player]: Ghost } = {}
local playConn: RBXScriptConnection? = nil
local tracks: { [string]: AnimationTrack } = {} -- the puppet's loaded tracks by AnimationId

local function rootOf(model: Model?): BasePart?
	return model and model:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- distance from the root's centre down to the floor (avatars differ: a replay keeps the feet on the ground)
local function hipOf(model: Model): number
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = rootOf(model)
	return (if humanoid then humanoid.HipHeight else 2) + (if root then root.Size.Y / 2 else 1)
end

local function animator(): Animator?
	local humanoid = puppet and puppet:FindFirstChildOfClass("Humanoid")
	return humanoid and humanoid:FindFirstChildOfClass("Animator")
end

local function track(id: string): AnimationTrack?
	local cached = tracks[id]
	if cached then
		return cached
	end
	local a = animator()
	if not a then
		return nil
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local ok, loaded = pcall(a.LoadAnimation, a, anim)
	if not ok then
		warn("[Trailer] can't load", id, loaded)
		return nil
	end
	tracks[id] = loaded
	return loaded
end

local function stopGhost()
	if playConn then
		playConn:Disconnect()
		playConn = nil
	end
	for _, t in tracks do
		if t ~= loopTrack then
			t:Stop(0.1)
		end
	end
	local root = rootOf(puppet)
	if root then
		root.Anchored = false
	end
end

local function loop(id: string)
	if loopTrack then
		loopTrack:Stop(0.2)
	end
	loopTrack = track(id)
	if loopTrack then
		loopTrack.Looped = true
		loopTrack:Play(0.2)
	end
end

local function remove()
	stopGhost()
	if puppet then
		puppet:Destroy()
	end
	puppet, loopTrack = nil, nil
	table.clear(tracks)
end

local function beside(player: Player): CFrame?
	local root = rootOf(player.Character)
	return root and root.CFrame * CFrame.new(T.PuppetOffset, 0, 0)
end

local function spawn(player: Player, role: "Kai" | "Miko", userId: number?)
	remove()
	local ok, model = pcall(function(): Model
		if userId then
			return Players:CreateHumanoidModelFromUserId(userId)
		end
		-- no avatar given: a blank description is all black, so skin + the role's shirt color + dark trousers
		local d = Instance.new("HumanoidDescription")
		d.HeadColor, d.LeftArmColor, d.RightArmColor = T.PuppetSkin, T.PuppetSkin, T.PuppetSkin
		d.TorsoColor = (Palette :: any)[role]
		d.LeftLegColor, d.RightLegColor = T.PuppetLegs, T.PuppetLegs
		return Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R15)
	end)
	if not ok then
		warn("[Trailer] puppet avatar failed:", model)
		return
	end
	local m = model :: Model
	m.Name = "TrailerPuppet"
	local world = workspace:GetAttribute("World")
	local kits = type(world) == "string" and Kits.Worlds[world]
	m:SetAttribute("Role", role)
	m:SetAttribute("Kit", kits and (kits :: any)[role] or nil)
	local humanoid = m:FindFirstChildOfClass("Humanoid") :: Humanoid
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	if not humanoid:FindFirstChildOfClass("Animator") then
		Instance.new("Animator").Parent = humanoid
	end
	local at = beside(player)
	if at then
		m:PivotTo(at + Vector3.new(0, hipOf(m) - hipOf(player.Character :: Model), 0))
	end
	m.Parent = workspace
	local root = rootOf(m)
	if root then
		root:SetNetworkOwner(nil)
	end
	puppet = m
	ArtService.DressPuppet(m)
	loop(T.PuppetIdle)
end

-- replays the caller's last take on the puppet from its first sample
local function playGhost(player: Player, looping: boolean)
	local ghost = ghosts[player]
	local root = rootOf(puppet)
	if not (ghost and puppet and root and #ghost.samples > 1) then
		warn("[Trailer] /ghost play needs a /puppet and a /ghost rec take")
		return
	end
	stopGhost()
	if loopTrack then
		loopTrack:Stop(0.2)
	end
	root.Anchored = true
	local lift = Vector3.new(0, hipOf(puppet :: Model) - ghost.hip, 0)
	local samples = ghost.samples
	local length = (#samples - 1) / ghost.rate
	local t = 0
	playConn = RunService.Heartbeat:Connect(function(dt)
		t += dt
		if t > length then
			if not looping then
				stopGhost()
				if loopTrack then
					loopTrack:Play(0.3)
				end
				return
			end
			t = 0
		end
		local f = t * ghost.rate
		local i = math.clamp(math.floor(f) + 1, 1, #samples - 1)
		local a, b = samples[i], samples[i + 1]
		root.CFrame = a.cf:Lerp(b.cf, f - (i - 1)) + lift
		-- animations: play what the take played at that moment, stop the rest
		local live: { [string]: boolean } = {}
		for _, s in a.tracks do
			live[s.id] = true
			local tr = track(s.id)
			if tr then
				if not tr.IsPlaying then
					tr:Play(0.1)
				end
				if math.abs(tr.TimePosition - s.t) > 0.15 then
					tr.TimePosition = s.t
				end
				tr:AdjustSpeed(s.speed)
			end
		end
		for id, tr in tracks do
			if not live[id] and tr.IsPlaying then
				tr:Stop(0.1)
			end
		end
	end)
end

function Trailer.Command(name: string, args: { string }, player: Player)
	if name == "trailer" then
		Net.event("Trailer"):FireClient(player, "Toggle")
	elseif name == "puppet" then
		local sub = (args[1] or ""):lower()
		if sub == "off" then
			remove()
		elseif sub == "here" then
			local at = beside(player)
			if puppet and at then
				stopGhost()
				puppet:PivotTo(at + Vector3.new(0, hipOf(puppet) - hipOf(player.Character :: Model), 0))
			end
		elseif sub == "clip" then
			local clip = args[2] or "idle"
			local id = if clip:lower() == "idle" then T.PuppetIdle else (MoveAnims.Ids :: any)[clip]
			if puppet and id then
				stopGhost()
				loop(id)
			else
				warn(`[Trailer] /puppet clip <name>: one of idle, {table.concat(Trailer.ClipNames(), ", ")}`)
			end
		elseif sub == "kai" or sub == "miko" then
			spawn(player, if sub == "kai" then "Kai" else "Miko", tonumber(args[2]))
		else
			warn("[Trailer] /puppet kai|miko [userId] | here | clip <name> | off")
		end
	elseif name == "ghost" then
		local sub = (args[1] or ""):lower()
		if sub == "rec" then
			local secs = math.clamp(tonumber(args[2]) or 15, 1, T.GhostMax)
			Net.event("Trailer"):FireClient(player, "Record", secs)
		elseif sub == "play" or sub == "loop" then
			playGhost(player, sub == "loop")
		elseif sub == "stop" then
			stopGhost()
			if loopTrack then
				loopTrack:Play(0.3)
			end
		else
			warn("[Trailer] /ghost rec [seconds] | play | loop | stop")
		end
	end
end

function Trailer.ClipNames(): { string }
	local names = {}
	for n in MoveAnims.Ids do
		table.insert(names, n)
	end
	table.sort(names)
	return names
end

-- a take arrives in chunks: (part, isLast, hip, samples); only from an admin who asked for it (AdminCommands checks)
function Trailer.Init(allowed: (number) -> boolean)
	Net.event("TrailerGhost").OnServerEvent
		:Connect(function(player: Player, first: unknown, last: unknown, hip: unknown, part: unknown)
			if not allowed(player.UserId) or type(part) ~= "table" or type(hip) ~= "number" then
				return
			end
			local ghost = incoming[player]
			if first == true or not ghost then
				ghost = { rate = T.GhostRate, hip = hip, samples = {} }
				incoming[player] = ghost
			end
			local g = ghost :: Ghost
			for _, s in part :: { any } do
				if type(s) == "table" and typeof(s.cf) == "CFrame" and type(s.tracks) == "table" then
					table.insert(g.samples, s)
				end
				if #g.samples >= T.GhostMax * T.GhostRate then
					break
				end
			end
			if last == true then
				ghosts[player] = g
				incoming[player] = nil
				print(`[Trailer] ghost take from {player.Name}: {#g.samples} samples ({#g.samples / g.rate} s)`)
			end
		end)
	Players.PlayerRemoving:Connect(function(p)
		ghosts[p], incoming[p] = nil, nil
	end)
end

return Trailer
