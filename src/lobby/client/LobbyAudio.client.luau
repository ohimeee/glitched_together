-- Lobby music + room ambience (Config/Sounds Lobby entries), faded in on join, and the toy train's whistle now
-- and then. One-shots (bed squeak, capsule clicks) are played where they happen: BedBounce, Capsules.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Sounds = require(ReplicatedStorage.Shared.Config.Sounds)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)

local WHISTLE_GAP = NumberRange.new(25, 45) -- seconds between train whistles

for name, volume in Sounds.Groups do
	Audio.group(name).Volume = volume
end

local function loop(def: Sounds.Def?, group: string)
	if not def then
		return
	end
	local s = Audio.make(def, "Lobby" .. group)
	s.Looped = true
	s.Volume = 0
	s.Parent = SoundService
	s:Play()
	TweenService:Create(s, TweenInfo.new(Sounds.MusicFade, Enum.EasingStyle.Sine), { Volume = def.Volume }):Play()
end

loop(Sounds.Music.Lobby, "Music")
loop(Sounds.Ambience.Lobby, "Ambience")

task.spawn(function()
	local train = workspace:WaitForChild("Lobby"):WaitForChild("Props"):WaitForChild("Train", 120)
	if not train then
		return
	end
	local rng = Random.new()
	while train.Parent do
		task.wait(rng:NextNumber(WHISTLE_GAP.Min, WHISTLE_GAP.Max))
		Audio.play("TrainWhistle", train)
	end
end)
