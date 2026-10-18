-- Per-player settings in the lobby (Util/Settings: the same saved table as the Adventure).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

require(ReplicatedStorage.Shared.Util.Settings).InitServer()
