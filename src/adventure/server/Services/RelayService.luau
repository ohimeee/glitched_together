-- Ping markers and Partner Peek camera relay (implementation.md §11).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local DuoService = require(script.Parent.DuoService)

local RelayService = {}

local PING_COOLDOWN = 0.4
local CAM_MIN_GAP = 1 / 15

function RelayService.Init()
	local ping = Net.event("Ping")
	local camSync = Net.event("CamSync", true)
	local lastPing: { [Player]: number } = {}
	local lastCam: { [Player]: number } = {}

	ping.OnServerEvent:Connect(function(p: Player, pos: Vector3)
		if typeof(pos) ~= "Vector3" or pos.Magnitude > 1e5 then
			return
		end
		local now = os.clock()
		if now - (lastPing[p] or 0) < PING_COOLDOWN then
			return
		end
		lastPing[p] = now
		for _, member in DuoService.Players() do
			ping:FireClient(member, p, pos)
		end
	end)

	camSync.OnServerEvent:Connect(function(p: Player, cf: CFrame)
		if typeof(cf) ~= "CFrame" then
			return
		end
		local now = os.clock()
		if now - (lastCam[p] or 0) < CAM_MIN_GAP then
			return
		end
		lastCam[p] = now
		local partner = DuoService.PartnerOf(p)
		if partner then
			camSync:FireClient(partner, cf)
		end
	end)
end

return RelayService
