-- Lobby capsule system (implementation.md §2): step into a Kai or Miko capsule, both filled → 5 s lock-in,
-- then the pair is teleported together into its own reserved Adventure server.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Places = require(ReplicatedStorage.Shared.Config.Places)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Roles = require(ReplicatedStorage.Shared.Config.Roles)
local Worlds = require(ReplicatedStorage.Shared.Config.Worlds)
local Net = require(ReplicatedStorage.Shared.Net)
local LobbyBuilder = require(script.Parent.LobbyBuilder)

local LOCK_TIME = Tuning.LockTime
local CHECK_INTERVAL = 0.2
local DUO_TTL = 60 * 60 -- seconds the duo record lives in MemoryStore
local MESSAGE_TIME = 2.5 -- how long TRY AGAIN / STUDIO notices stay on a screen

LobbyBuilder.Build()
Worlds.ApplyLook(Worlds.ByName.Lobby.Look)

-- MemoryStore throws in an unpublished place; keep going so the capsule lock-in can still be tested in Studio.
-- Every later use is inside a pcall, so missing maps only turn off teleport/rejoin.
local duoMap: MemoryStoreHashMap, rejoinMap: MemoryStoreHashMap
local storeOk, storeErr = pcall(function()
	duoMap = MemoryStoreService:GetHashMap("Duos")
	rejoinMap = MemoryStoreService:GetHashMap("Rejoin")
end)
if not storeOk then
	warn(`[Capsules] MemoryStore unavailable ({storeErr}); duo teleport and rejoin are off`)
end
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
}

local allPairs: { Pair } = {}
local seatedIn: { [Player]: Pair } = {}

local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include

-- Returns the set of players whose characters are inside the zone.
local function occupants(zone: BasePart): { [Player]: boolean }
	local chars = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(chars, p.Character)
		end
	end
	overlap.FilterDescendantsInstances = chars

	local found = {}
	for _, part in workspace:GetPartBoundsInBox(zone.CFrame, zone.Size, overlap) do
		local character = part:FindFirstAncestorOfClass("Model")
		local p = character and Players:GetPlayerFromCharacter(character)
		if p then
			found[p] = true
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
	end
	for p in inside do
		if not seatedIn[p] then -- first free player inside takes the seat
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

	if RunService:IsStudio() or Places.Adventure == 0 then
		-- Teleports don't work in Studio (and need the place id): prove the lock-in works, then release.
		print(`[Capsules] {kai.Name} (Kai) + {miko.Name} (Miko) locked in. Teleport skipped in Studio.`)
		task.wait(1.5)
		releasePair(pair, "LOCKED! (STUDIO)")
		return
	end

	local ok, err = pcall(function()
		local accessCode, privateServerId = TeleportService:ReserveServer(Places.Adventure)
		duoMap:SetAsync(privateServerId, { kai = kai.UserId, miko = miko.UserId }, DUO_TTL)
		rejoinMap:SetAsync(tostring(kai.UserId), { code = accessCode, server = privateServerId }, DUO_TTL)
		rejoinMap:SetAsync(tostring(miko.UserId), { code = accessCode, server = privateServerId }, DUO_TTL)

		local options = Instance.new("TeleportOptions")
		options.ReservedServerAccessCode = accessCode
		TeleportService:TeleportAsync(Places.Adventure, { kai, miko }, options)
	end)

	if not ok then
		warn("Duo teleport failed:", err)
		releasePair(pair, "TRY AGAIN")
	end
end

local function statusText(pair: Pair): string
	if pair.message and os.clock() < pair.messageUntil then
		return pair.message
	elseif pair.sending then
		return "LOADING..."
	elseif pair.seats.kai and pair.seats.miko then
		return `LOCKING IN... {math.max(1, math.ceil(pair.countdown or LOCK_TIME))}`
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
	if Places.Adventure ~= 0 and not RunService:IsStudio() then
		local ok, entry = pcall(function()
			return rejoinMap:GetAsync(tostring(p.UserId))
		end)
		if ok and entry then
			rejoinOffer:FireClient(p)
		end
	end
end)

rejoinAccept.OnServerEvent:Connect(function(p: Player)
	local ok, entry = pcall(function()
		return rejoinMap:GetAsync(tostring(p.UserId))
	end)
	if not (ok and entry) then
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
	end
end
