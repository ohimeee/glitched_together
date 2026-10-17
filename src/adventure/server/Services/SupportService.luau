-- The adventure's tip jar + supporter recognition (shared with the lobby: Util/TipJar receipts, Util/Supporters).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Supporters = require(ReplicatedStorage.Shared.Util.Supporters)
local TipJar = require(ReplicatedStorage.Shared.Util.TipJar)

local SupportService = {}

function SupportService.Init()
	Supporters.Init()
	TipJar.Init()
end

return SupportService
