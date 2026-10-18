-- Lobby music + room ambience (Config/Sounds Lobby entries), faded in on join, the toy train's whistle now and
-- then, and UI sounds for every lobby button (hover + click) and [E] prompt. Other one-shots (bed squeak, capsule
-- clicks) are played where they happen: BedBounce, Capsules.
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Sounds = require(ReplicatedStorage.Shared.Config.Sounds)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)

local WHISTLE_GAP = NumberRange.new(12, 25) -- seconds between train whistles

Audio.UseSettings() -- group volumes × the player's sliders

local function loop(def: Sounds.Def?, group: string)
	if not def then
		return
	end
	local s = Audio.make(def, "Lobby" .. group)
	s.SoundGroup = Audio.group(group) -- Music / Ambience (defs carry no Group: it fell into SFX, so its slider missed it)
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
	Audio.play("TrainRoll", train) -- looped, lives on the train
	local rng = Random.new()
	task.wait(3) -- first toot soon after joining
	Audio.play("TrainWhistle", train)
	while train.Parent do
		task.wait(rng:NextNumber(WHISTLE_GAP.Min, WHISTLE_GAP.Max))
		Audio.play("TrainWhistle", train)
	end
end)

-- every button in any lobby screen (HUD, save-file menu, tip jar), now and later
-- (not the movement buttons: Roblox's touch jump / thumbstick (TouchGui) and our DASH (LobbyMoves) are controls, a
-- click on every jump was noise; user, Oct 19)
local function hookButton(b: Instance)
	if not b:IsA("GuiButton") then
		return
	end
	local screen = b:FindFirstAncestorWhichIsA("ScreenGui")
	if screen and (screen.Name == "TouchGui" or screen.Name == "LobbyMoves") then
		return
	end
	b.MouseEnter:Connect(function()
		Audio.play("Hover")
	end)
	b.Activated:Connect(function()
		Audio.play("Click")
	end)
end

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
for _, d in playerGui:GetDescendants() do
	hookButton(d)
end
playerGui.DescendantAdded:Connect(hookButton)

-- supporter slips, the tip jar
ProximityPromptService.PromptShown:Connect(function()
	Audio.play("Hover")
end)
ProximityPromptService.PromptTriggered:Connect(function()
	Audio.play("Select")
end)
