-- Music and ambience per world (design.md §8), from Config/Sounds. Follows workspace "World" (set by
-- WorldService) and "BossFight" (BossService), crossfading tracks; ducks the music while a cutscene plays.
-- One-shot SFX go through Util/Audio from the controllers and services that own each moment.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage.Shared.Net)
local Sounds = require(ReplicatedStorage.Shared.Config.Sounds)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)

local AudioController = {}

type Layer = { sound: Sound?, id: string?, base: number }

local music: Layer = { base = 1 }
local ambience: Layer = { base = 1 }
local duck = 1

local function fade(s: Sound, to: number, time: number, destroy: boolean)
	local tween = TweenService:Create(s, TweenInfo.new(time, Enum.EasingStyle.Sine), { Volume = to })
	if destroy then
		tween.Completed:Once(function()
			s:Destroy()
		end)
	end
	tween:Play()
end

local function set(layer: Layer, def: Sounds.Def?, group: string, scale: number)
	local id = def and (def.Id or (def.Ids :: { string })[1])
	if id == layer.id then
		return
	end
	local old = layer.sound
	if old then
		fade(old, 0, Sounds.MusicFade, true)
	end
	layer.sound, layer.id = nil, id
	if def then
		local s = Audio.make(def, group)
		s.SoundGroup = Audio.group(group)
		s.Looped = true
		s.Volume = 0
		s.Parent = SoundService
		s:Play()
		layer.sound, layer.base = s, def.Volume
		fade(s, def.Volume * scale, Sounds.MusicFade, false)
	end
end

local function refresh()
	local world = workspace:GetAttribute("World")
	if type(world) ~= "string" then
		return
	end
	local boss = workspace:GetAttribute("BossFight") and Sounds.BossMusic[world]
	set(music, boss or Sounds.Music[world], "Music", duck)
	set(ambience, Sounds.Ambience[world], "Ambience", 1)
end

local function setDuck(to: number)
	duck = to
	if music.sound then
		fade(music.sound, music.base * duck, 0.6, false)
	end
end

function AudioController.Init()
	for name, volume in Sounds.Groups do
		Audio.group(name).Volume = volume
	end
	workspace:GetAttributeChangedSignal("World"):Connect(refresh)
	workspace:GetAttributeChangedSignal("BossFight"):Connect(refresh)
	refresh()

	Net.event("Cutscene").OnClientEvent:Connect(function(id: string?)
		setDuck(if id then Sounds.CutsceneDuck else 1)
	end)
end

return AudioController
