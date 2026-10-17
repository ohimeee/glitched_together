-- Saved runs in the lobby (user, Oct 17): every player sees the partners they have a run with (RunIndex, written by
-- the Adventure's SaveService) and can "Continue with <partner>" when that partner is in this lobby: the partner
-- gets an offer, and on YES the two teleport straight into their run with the roles they had. A new partner (the
-- capsules) is always a fresh start, because the Adventure keys its save by the pair.
-- Studio: ids are <= 0 so nothing is stored; workspace "DebugSavedRuns" = true fills every list with sample runs
-- (plus the other test player, as online) to check the UI.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = require(ReplicatedStorage.Shared.Net)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local RunIndex = require(ReplicatedStorage.Shared.Util.RunIndex)
local DuoTeleport = require(script.Parent.DuoTeleport)

local listEvent = Net.event("SavedRuns") -- server → client: the list (with online flags)
local inviteEvent = Net.event("RunInvite") -- client → server: partner id
local offerEvent = Net.event("RunInviteOffer") -- server → client: from id, name, world, checkpoint
local replyEvent = Net.event("RunInviteReply") -- client → server: from id, accepted
local statusEvent = Net.event("RunInviteStatus") -- server → client: short notice

local INVITE_TTL = 30 -- seconds an offer stays open
local INVITE_GAP = 3 -- seconds between two invites from one player

local lists: { [Player]: { RunIndex.Entry } } = {}
local offers: { [Player]: { from: Player, expires: number } } = {} -- keyed by the invited player
local lastInvite: { [Player]: number } = {}

local function sample(p: Player): { RunIndex.Entry }
	local now = os.time()
	local list: { RunIndex.Entry } = {}
	for _, other in Players:GetPlayers() do
		if other ~= p then
			table.insert(list, {
				partner = other.UserId,
				name = other.DisplayName,
				role = if p.UserId < other.UserId then "Kai" else "Miko",
				world = "StarfallCastle",
				checkpoint = 9,
				t = now,
			})
		end
	end
	table.insert(
		list,
		{ partner = 1, name = "Sam", role = "Miko", world = "PixelPlains", checkpoint = 14, t = now - 3600 }
	)
	table.insert(
		list,
		{ partner = 2, name = "Jo", role = "Kai", world = "GlitchedCore", checkpoint = 6, t = now - 86400 }
	)
	table.insert(
		list,
		{
			partner = 3,
			name = "Ria",
			role = "Kai",
			world = "Epilogue",
			checkpoint = 0,
			complete = true,
			t = now - 86400 * 9,
		}
	)
	return list
end

local function partnerHere(id: number): Player?
	for _, other in Players:GetPlayers() do
		if other.UserId == id then
			return other
		end
	end
	return nil
end

local function send(p: Player)
	local list = lists[p]
	if not list or p.Parent ~= Players then
		return
	end
	local out = {}
	for _, e in list do
		local here = partnerHere(e.partner)
		table.insert(out, {
			partner = e.partner,
			name = if here then here.DisplayName else e.name,
			role = e.role,
			world = e.world,
			checkpoint = e.checkpoint,
			complete = e.complete,
			t = e.t,
			online = here ~= nil,
		})
	end
	listEvent:FireClient(p, out)
end

local function load(p: Player)
	local list = if RunService:IsStudio() and workspace:GetAttribute("DebugSavedRuns")
		then sample(p)
		else RunIndex.Get(p.UserId)
	if p.Parent ~= Players then
		return
	end
	lists[p] = list
	send(p)
end

local function entryFor(p: Player, partnerId: number): RunIndex.Entry?
	local list = lists[p]
	if not list then
		return nil
	end
	for _, e in list do
		if e.partner == partnerId then
			return e
		end
	end
	return nil
end

-- Someone joined or left: everyone with them in their list gets fresh online flags.
local function refreshAbout(id: number)
	for p in lists do
		if entryFor(p, id) then
			send(p)
		end
	end
end

local function busy(p: Player): boolean
	return p:GetAttribute("Teleporting") == true or p:GetAttribute("Role") ~= nil -- teleporting or in a capsule
end

inviteEvent.OnServerEvent:Connect(function(p: Player, partnerId: unknown)
	if type(partnerId) ~= "number" then
		return
	end
	if os.clock() - (lastInvite[p] or 0) < INVITE_GAP then
		return
	end
	lastInvite[p] = os.clock()
	local entry = entryFor(p, partnerId)
	local partner = partnerHere(partnerId)
	if not entry then
		return
	end
	if not partner then
		statusEvent:FireClient(p, `{entry.name} isn't in this lobby. Invite them first!`)
		return
	end
	if busy(p) or busy(partner) then
		statusEvent:FireClient(p, "Step out of the capsules first.")
		return
	end
	offers[partner] = { from = p, expires = os.clock() + INVITE_TTL }
	offerEvent:FireClient(partner, p.UserId, p.DisplayName, entry.world, entry.checkpoint, entry.complete == true)
	statusEvent:FireClient(p, `Asked {partner.DisplayName}...`)
end)

replyEvent.OnServerEvent:Connect(function(p: Player, fromId: unknown, accepted: unknown)
	local offer = offers[p]
	if not offer or offer.from.UserId ~= fromId then
		return
	end
	offers[p] = nil
	local from = offer.from
	if from.Parent ~= Players or os.clock() > offer.expires then
		statusEvent:FireClient(p, "That invite ran out.")
		return
	end
	if accepted ~= true then
		statusEvent:FireClient(from, `{p.DisplayName} can't right now.`)
		return
	end
	if busy(p) or busy(from) then
		return
	end
	-- the roles they had in this run (the inviter's entry says theirs)
	local entry = entryFor(from, p.UserId)
	local fromIsKai = not entry or entry.role ~= "Miko"
	local kai, miko = if fromIsKai then from else p, if fromIsKai then p else from
	for _, q in { kai, miko } do
		q:SetAttribute("Teleporting", true)
		statusEvent:FireClient(q, "Loading your run...")
		local humanoid = q.Character and q.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpHeight = 0
		end
	end
	local ok, err = DuoTeleport.Send(kai, miko)
	if not ok then
		task.wait(if err == "STUDIO" then 1.5 else 0)
		for _, q in { kai, miko } do
			q:SetAttribute("Teleporting", nil)
			statusEvent:FireClient(
				q,
				if err == "STUDIO" then "LOCKED! (STUDIO: no teleport)" else "Teleport failed. Try again."
			)
			local humanoid = q.Character and q.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = Tuning.WalkSpeed
				humanoid.JumpHeight = Tuning.JumpHeight
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(p)
	task.spawn(load, p)
	refreshAbout(p.UserId)
end)
for _, p in Players:GetPlayers() do
	task.spawn(load, p)
end
Players.PlayerRemoving:Connect(function(p)
	lists[p] = nil
	offers[p] = nil
	lastInvite[p] = nil
	refreshAbout(p.UserId)
end)
workspace:GetAttributeChangedSignal("DebugSavedRuns"):Connect(function()
	for _, p in Players:GetPlayers() do
		task.spawn(load, p)
	end
end)
