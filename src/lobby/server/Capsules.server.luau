-- Lobby capsule system (implementation.md §2): step into a Kai or Miko capsule, both filled → 5 s lock-in,
-- then the pair is teleported together into its own reserved Adventure server.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Places = require(ReplicatedStorage.Shared.Config.Places)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Roles = require(ReplicatedStorage.Shared.Config.Roles)
local Worlds = require(ReplicatedStorage.Shared.Config.Worlds)
local Net = require(ReplicatedStorage.Shared.Net)
local RunIndex = require(ReplicatedStorage.Shared.Util.RunIndex)
local LobbyBuilder = require(script.Parent.LobbyBuilder)
local DuoTeleport = require(script.Parent.DuoTeleport)

local LOCK_TIME = Tuning.LockTime
local CHECK_INTERVAL = 0.2
local MESSAGE_TIME = 2.5 -- how long TRY AGAIN / STUDIO notices stay on a screen

LobbyBuilder.Build()
Worlds.ApplyLook(Worlds.ByName.Lobby.Look)

local rejoinOffer = Net.event("RejoinOffer")
local rejoinAccept = Net.event("RejoinAccept")

type Pair = {
	model: Model,
	zones: { kai: BasePart, miko: BasePart },
	seats: { kai: Player?, miko: Player? },
	countdown: number?,
	sending: boolean,
	message: string?,
	messageUntil: number,
	status: TextLabel,
	saveFor: string?, -- "<kaiId>_<mikoId>" the save line below was read for
	saveLine: string?, -- "CONTINUE: PIXEL PLAINS" / "NEW GAME" (nil while reading)
	saveShort: string?, -- "STARFALL CASTLE · CP 9" for the seated players' choice chip (nil = no save to continue)
	swapped: boolean, -- they stand in the other capsules than in their saved run (allowed: same save, swapped powers)
	votes: { [Player]: boolean }, -- NEW GAME votes: both must press it to replace their save
}

local allPairs: { Pair } = {}
local seatedIn: { [Player]: Pair } = {}

-- How far from the capsule's centre a player's root may be and still count as inside (the inner floor is ~4 studs
-- across the glass): standing right outside, arms or accessories brushing the zone, no longer seats you.
local INSIDE_RADIUS = 2.6

-- Returns the set of players standing inside the capsule: the HumanoidRootPart's centre within INSIDE_RADIUS of the
-- zone's vertical axis and within its height.
local function occupants(zone: BasePart): { [Player]: boolean }
	local found = {}
	for _, p in Players:GetPlayers() do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local loc = zone.CFrame:PointToObjectSpace(root.Position)
			if Vector2.new(loc.X, loc.Z).Magnitude <= INSIDE_RADIUS and math.abs(loc.Y) <= zone.Size.Y / 2 then
				found[p] = true
			end
		end
	end
	return found
end

-- Name tag over the head: "▲ KAI" in orange / "● MIKO" in teal.
local function updateNameTag(p: Player)
	local character = p.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local tag = head:FindFirstChild("RoleTag") :: BillboardGui?
	local role = p:GetAttribute("Role")
	local info = role and (Roles :: any)[role]
	if not info then
		if tag then
			tag:Destroy()
		end
		return
	end
	if not tag then
		local newTag = Instance.new("BillboardGui")
		newTag.Name = "RoleTag"
		newTag.Size = UDim2.fromOffset(160, 44)
		newTag.StudsOffset = Vector3.new(0, 3, 0)
		newTag.AlwaysOnTop = true
		newTag.LightInfluence = 0
		local text = Instance.new("TextLabel")
		text.Name = "Text"
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Font = Enum.Font.FredokaOne
		text.TextScaled = true
		text.TextStrokeTransparency = 0.3
		text.Parent = newTag
		newTag.Parent = head
		tag = newTag
	end
	local text = (tag :: BillboardGui):FindFirstChild("Text") :: TextLabel
	text.Text = (if info.Shape == "Triangle" then "▲ " else "● ") .. info.Label
	text.TextColor3 = info.Color
end

local function setRole(p: Player, role: string?)
	p:SetAttribute("Role", role) -- "Kai" / "Miko" / nil
	updateNameTag(p)
end

local function refreshSeat(pair: Pair, seat: "kai" | "miko")
	local inside = occupants(pair.zones[seat])
	local current = pair.seats[seat]

	if current and inside[current] then
		return -- still standing in the capsule
	end
	if current then -- they stepped out
		pair.seats[seat] = nil
		seatedIn[current] = nil
		setRole(current, nil)
		pair.votes[current] = nil -- stepping out cancels their NEW GAME vote
		for _, a in { "SeatSave", "SeatPartner", "SeatVotes", "SeatMyVote" } do
			current:SetAttribute(a, nil)
		end
	end
	for p in inside do
		if not seatedIn[p] and not p:GetAttribute("Teleporting") then -- first free player inside takes the seat
			pair.seats[seat] = p
			seatedIn[p] = pair
			setRole(p, if seat == "kai" then "Kai" else "Miko")
			break
		end
	end
end

local function setFrozen(p: Player, frozen: boolean)
	local humanoid = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = if frozen then 0 else Tuning.WalkSpeed
		humanoid.JumpHeight = if frozen then 0 else Tuning.JumpHeight
	end
end

local function showMessage(pair: Pair, text: string)
	pair.message = text
	pair.messageUntil = os.clock() + MESSAGE_TIME
end

local function releasePair(pair: Pair, message: string)
	if pair.seats.kai then
		setFrozen(pair.seats.kai, false)
	end
	if pair.seats.miko then
		setFrozen(pair.seats.miko, false)
	end
	pair.sending = false
	pair.countdown = nil
	showMessage(pair, message)
end

local function sendPair(pair: Pair)
	local kai, miko = pair.seats.kai, pair.seats.miko
	if not (kai and miko) then
		return
	end
	pair.sending = true
	setFrozen(kai, true)
	setFrozen(miko, true)

	local ok, err = DuoTeleport.Send(kai, miko, pair.saveShort ~= nil and pair.votes[kai] and pair.votes[miko])
	if not ok then
		if err == "STUDIO" then
			-- Teleports don't work in Studio (and need the place id): prove the lock-in works, then release.
			task.wait(1.5)
			releasePair(pair, "LOCKED! (STUDIO)")
		else
			releasePair(pair, "TRY AGAIN")
		end
	end
end

-- Reads the pair's duo save once per new pair: the screen says whether they continue or start fresh.
local function readSave(pair: Pair)
	local kai, miko = pair.seats.kai, pair.seats.miko
	if not (kai and miko) then
		return
	end
	local id = `{kai.UserId}_{miko.UserId}`
	if pair.saveFor == id then
		return
	end
	pair.saveFor = id
	pair.saveLine = nil
	pair.saveShort = nil
	pair.swapped = false
	pair.votes = {}
	task.spawn(function()
		local save = RunIndex.DuoSave(kai.UserId, miko.UserId)
		if RunService:IsStudio() and workspace:GetAttribute("DebugSavedRuns") then
			save = { world = "StarfallCastle", checkpoint = 9 } -- Studio ids never save: a sample to test the chip
		end
		-- the roles they had: Kai's own run list says which side Kai stood on last time
		local swapped = false
		for _, e in RunIndex.Get(kai.UserId) do
			if e.partner == miko.UserId then
				swapped = e.role == "Miko"
				break
			end
		end
		if pair.saveFor ~= id then
			return -- someone swapped meanwhile
		end
		local info = save and Worlds.ByName[save.world]
		if save and save.complete then
			pair.saveLine = "FINISHED ★ PLAY AGAIN"
			pair.saveShort = "FINISHED ★"
		elseif info and not (save.world == "Prologue" and (save.checkpoint or 0) == 0) then
			pair.saveLine = `CONTINUE: {string.upper(info.Title)}`
			pair.saveShort = `{string.upper(info.Title)} · CP {save.checkpoint or 0}`
		else
			pair.saveLine = "NEW GAME"
		end
		pair.swapped = pair.saveShort ~= nil and swapped
	end)
end

local function voteCount(pair: Pair): number
	local n = 0
	for _, p in { pair.seats.kai, pair.seats.miko } do
		if p and pair.votes[p] then
			n += 1
		end
	end
	return n
end

-- The seated players' screens show a CONTINUE / NEW GAME chip when their pair has a save (SavedRunsUI).
local function syncSeats(pair: Pair)
	local kai, miko = pair.seats.kai, pair.seats.miko
	for _, side in { { kai, miko }, { miko, kai } } do
		local me, other = side[1], side[2]
		if me then
			local show = other ~= nil and pair.saveShort ~= nil and not pair.sending
			me:SetAttribute("SeatSave", if show then pair.saveShort else nil)
			me:SetAttribute("SeatPartner", if show and other then other.DisplayName else nil)
			me:SetAttribute("SeatVotes", if show then voteCount(pair) else nil)
			me:SetAttribute("SeatMyVote", if show then pair.votes[me] == true else nil)
		end
	end
end

Net.event("CapsuleNewGame").OnServerEvent:Connect(function(p: Player, want: unknown)
	local pair = seatedIn[p]
	if not pair or pair.sending or not pair.saveShort or type(want) ~= "boolean" then
		return
	end
	if pair.votes[p] == want then
		return
	end
	pair.votes[p] = want
	if pair.countdown then
		pair.countdown = LOCK_TIME -- the choice changed: give the partner time to see it
	end
end)

local function statusText(pair: Pair): string
	if pair.message and os.clock() < pair.messageUntil then
		return pair.message
	elseif pair.sending then
		return "LOADING..."
	elseif pair.seats.kai and pair.seats.miko then
		local count = `LOCKING IN... {math.max(1, math.ceil(pair.countdown or LOCK_TIME))}`
		local votes = voteCount(pair)
		local line = pair.saveLine
		if pair.saveShort and votes == 2 then
			line = "NEW GAME (REPLACES SAVE)"
		elseif pair.saveShort and votes == 1 then
			line = "NEW GAME? 1/2"
		elseif line and pair.swapped then
			line ..= " · ROLES SWAPPED"
		end
		return if line then `{line}\n{count}` else count
	elseif pair.seats.kai then
		return "WAITING FOR MIKO"
	elseif pair.seats.miko then
		return "WAITING FOR KAI"
	end
	return "STEP IN TO PLAY"
end

local function registerPair(model: Instance)
	local m = model :: any
	table.insert(allPairs, {
		model = model :: Model,
		zones = { kai = m.KaiCapsule.Zone, miko = m.MikoCapsule.Zone },
		seats = {},
		countdown = nil,
		sending = false,
		message = nil,
		messageUntil = 0,
		status = m.Screen.SurfaceGui.Status,
		swapped = false,
		votes = {},
	})
end

for _, model in CollectionService:GetTagged("CapsulePair") do
	registerPair(model)
end
CollectionService:GetInstanceAddedSignal("CapsulePair"):Connect(registerPair)

-- If a teleport fails after it started (e.g. a player's client failed), unfreeze and free the pair.
TeleportService.TeleportInitFailed:Connect(function(p: Player)
	local pair = seatedIn[p]
	if pair then
		releasePair(pair, "TRY AGAIN")
	end
end)

Players.PlayerAdded:Connect(function(p: Player)
	p.CharacterAdded:Connect(function()
		task.wait()
		updateNameTag(p)
	end)

	-- A player who dropped out of a duo run can jump back into their partner's server.
	if DuoTeleport.RejoinEntry(p.UserId) then
		rejoinOffer:FireClient(p)
	end
end)

rejoinAccept.OnServerEvent:Connect(function(p: Player)
	local entry = DuoTeleport.RejoinEntry(p.UserId)
	if not entry then
		return
	end
	local options = Instance.new("TeleportOptions")
	options.ReservedServerAccessCode = entry.code
	local sent, err = pcall(function()
		TeleportService:TeleportAsync(Places.Adventure, { p }, options)
	end)
	if not sent then
		warn("Rejoin failed:", err)
	end
end)

Players.PlayerRemoving:Connect(function(p: Player)
	local pair = seatedIn[p]
	if not pair then
		return
	end
	seatedIn[p] = nil
	if pair.seats.kai == p then
		pair.seats.kai = nil
	end
	if pair.seats.miko == p then
		pair.seats.miko = nil
	end
	pair.countdown = nil
	if not pair.seats.kai and not pair.seats.miko then
		pair.sending = false -- both have left (teleported): the pair is free again
	end
end)

while true do
	local dt = task.wait(CHECK_INTERVAL)
	for _, pair in allPairs do
		if not pair.sending then
			local beforeKai, beforeMiko = pair.seats.kai, pair.seats.miko
			refreshSeat(pair, "kai")
			refreshSeat(pair, "miko")

			if pair.seats.kai and pair.seats.miko then
				readSave(pair)
				local changed = pair.seats.kai ~= beforeKai or pair.seats.miko ~= beforeMiko
				if changed or pair.countdown == nil then
					pair.countdown = LOCK_TIME -- someone new stepped in: start (or restart) the 5 s
				else
					pair.countdown -= dt
					if pair.countdown <= 0 then
						task.spawn(sendPair, pair)
					end
				end
			else
				pair.countdown = nil -- someone stepped out: reset
			end
		end
		pair.status.Text = statusText(pair)
		syncSeats(pair)
	end
end
