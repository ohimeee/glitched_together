-- Plays the move animations (Config/MoveAnims.luau) on the local character for MovementController.
-- Tracks run on the character's Animator, so the partner sees them too (uploaded ids only: a Studio temporary id
-- from KeyframeSequenceProvider only exists on this client). One-shots (Play) cut each other; loops (Set) follow
-- MovementController's state every frame.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local MoveAnims = require(ReplicatedStorage.Shared.Config.MoveAnims)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)

local player = Players.LocalPlayer

local MoveAnimController = {}

local studioIds: { [string]: string } = {} -- temporary ids, made once per session
local tracks: { [string]: AnimationTrack } = {}
local oneShot: AnimationTrack? = nil

local function idFor(name: string): string?
	local id = MoveAnims.Ids[name]
	if id then
		return id
	end
	if not RunService:IsStudio() then
		return nil
	end
	if not studioIds[name] then
		local ok, temp = pcall(function()
			return KeyframeSequenceProvider:RegisterKeyframeSequence(MoveAnims.build(name))
		end)
		if not ok then
			warn("[MoveAnim] couldn't register", name, temp)
			return nil
		end
		studioIds[name] = temp
	end
	return studioIds[name]
end

local function onCharacter(character: Model)
	tracks = {}
	oneShot = nil
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	if humanoid.RigType ~= Enum.HumanoidRigType.R15 then
		return -- the clips are R15 poses
	end
	local animator = humanoid:WaitForChild("Animator") :: Animator
	for name in MoveAnims.Clips do
		local id = idFor(name)
		if id then
			local animation = Instance.new("Animation")
			animation.Name = name -- the track's name (debugging: Animator:GetPlayingAnimationTracks())
			animation.AnimationId = id
			local ok, track = pcall(function()
				return animator:LoadAnimation(animation)
			end)
			if ok then
				tracks[name] = track
			end
		end
	end
end

-- Has a playable track (false outside Studio until the clip is uploaded).
function MoveAnimController.Has(name: string): boolean
	return tracks[name] ~= nil
end

-- One-shot: stops the one-shot before it.
function MoveAnimController.Play(name: string, speed: number?)
	local track = tracks[name]
	if not track then
		return
	end
	if oneShot and oneShot ~= track then
		oneShot:Stop(Tuning.MoveAnim.Fade)
	end
	oneShot = track
	track:Play(0.03, 1, speed or 1)
end

-- Loop on/off (only acts on a change), optionally at a playback speed.
function MoveAnimController.Set(name: string, on: boolean, speed: number?)
	local track = tracks[name]
	if not track then
		return
	end
	if on then
		if not track.IsPlaying then
			track:Play(Tuning.MoveAnim.Fade, 1, speed or 1)
		elseif speed then
			track:AdjustSpeed(speed)
		end
	elseif track.IsPlaying then
		track:Stop(Tuning.MoveAnim.Fade)
	end
end

function MoveAnimController.StopAll()
	for _, track in tracks do
		if track.IsPlaying then
			track:Stop(Tuning.MoveAnim.Fade)
		end
	end
	oneShot = nil
end

function MoveAnimController.Init()
	if player.Character then
		task.spawn(onCharacter, player.Character)
	end
	player.CharacterAdded:Connect(onCharacter)
end

return MoveAnimController
