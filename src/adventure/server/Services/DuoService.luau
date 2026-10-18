-- Who is Kai and who is Miko in this reserved server (implementation.md §3), plus partner-disconnect handling.
local Players = game:GetService("Players")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

local Places = require(ReplicatedStorage.Shared.Config.Places)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)

local DuoService = {}
DuoService.Kai = nil :: Player?
DuoService.Miko = nil :: Player?

local duo: { kai: number, miko: number, fresh: boolean? }? = nil
local changed = Instance.new("BindableEvent")
DuoService.Changed = changed.Event -- fires (player, role) when someone takes a role

local function assign(p: Player)
	local role: string? = nil
	if duo and p.UserId == duo.kai then
		role = "Kai"
	elseif duo and p.UserId == duo.miko then
		role = "Miko"
	elseif not duo then
		-- Studio / unpublished fallback: first player is Kai, second is Miko.
		if not DuoService.Kai then
			role = "Kai"
		elseif not DuoService.Miko then
			role = "Miko"
		end
	end

	if not role then
		p:Kick("This is a private duo server.")
		return
	end

	if role == "Kai" then
		DuoService.Kai = p
	else
		DuoService.Miko = p
	end
	p:SetAttribute("Role", role)

	-- Partner came back in time: stop the wait screen.
	local partner = DuoService.PartnerOf(p)
	if partner then
		partner:SetAttribute("PartnerWaitUntil", nil)
	end
	changed:Fire(p, role)
end

local function onLeave(p: Player)
	local wasKai = DuoService.Kai == p
	local wasMiko = DuoService.Miko == p
	if not (wasKai or wasMiko) then
		return
	end
	if wasKai then
		DuoService.Kai = nil
	else
		DuoService.Miko = nil
	end

	local remaining = if wasKai then DuoService.Miko else DuoService.Kai
	if not remaining then
		return
	end

	-- Pause for the remaining player: "Waiting for your partner… (reconnect)" for up to 2 minutes.
	local deadline = workspace:GetServerTimeNow() + Tuning.PartnerWaitTime
	remaining:SetAttribute("PartnerWaitUntil", deadline)
	task.delay(Tuning.PartnerWaitTime, function()
		if remaining.Parent ~= Players or remaining:GetAttribute("PartnerWaitUntil") ~= deadline then
			return -- left too, or partner came back
		end
		if Places.Lobby == 0 or RunService:IsStudio() then
			remaining:SetAttribute("PartnerWaitUntil", nil)
			warn("[DuoService] Partner timed out; would return to Lobby (skipped: Studio or no Lobby id).")
			return
		end
		pcall(function()
			TeleportService:TeleportAsync(Places.Lobby, { remaining })
		end)
	end)
end

function DuoService.Init()
	if game.PrivateServerId ~= "" then
		local ok, data = pcall(function()
			return MemoryStoreService:GetHashMap("Duos"):GetAsync(game.PrivateServerId)
		end)
		if ok and data then
			duo = data
		end
	end

	for _, p in Players:GetPlayers() do
		task.spawn(assign, p)
	end
	Players.PlayerAdded:Connect(assign)
	Players.PlayerRemoving:Connect(onLeave)

	-- The run is over for this server once everybody leaves: drop rejoin entries.
	game:BindToClose(function()
		if not duo then
			return
		end
		local rejoin = MemoryStoreService:GetHashMap("Rejoin")
		for _, id in { duo.kai, duo.miko } do
			pcall(function()
				rejoin:RemoveAsync(tostring(id))
			end)
		end
	end)
end

function DuoService.PartnerOf(p: Player): Player?
	if p == DuoService.Kai then
		return DuoService.Miko
	end
	if p == DuoService.Miko then
		return DuoService.Kai
	end
	return nil
end

function DuoService.Players(): { Player }
	local list = {}
	if DuoService.Kai then
		table.insert(list, DuoService.Kai)
	end
	if DuoService.Miko then
		table.insert(list, DuoService.Miko)
	end
	return list
end

function DuoService.RoleOf(p: Player): string?
	return p:GetAttribute("Role") :: string?
end

-- True when both players chose NEW GAME in the lobby capsules: their old duo save is replaced.
function DuoService.Fresh(): boolean
	return duo ~= nil and duo.fresh == true
end

-- User ids for the save key: from the lobby record, or whoever is here (Studio).
function DuoService.Ids(): (number?, number?)
	if duo then
		return duo.kai, duo.miko
	end
	return DuoService.Kai and DuoService.Kai.UserId, DuoService.Miko and DuoService.Miko.UserId
end

-- Yields until the first player (and, for up to `timeout` seconds, the second) has arrived.
function DuoService.WaitForDuo(timeout: number)
	while not DuoService.Kai and not DuoService.Miko do
		task.wait(0.1)
	end
	local start = os.clock()
	-- AdminSolo = an admin came alone via the lobby's /go (AdminCommands): no partner is coming
	while
		not (DuoService.Kai and DuoService.Miko)
		and os.clock() - start < timeout
		and not workspace:GetAttribute("AdminSolo")
	do
		task.wait(0.1)
	end
end

return DuoService
