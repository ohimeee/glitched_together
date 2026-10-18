-- Plays a named sound from Config/Sounds. Works on both sides: a sound the server plays replicates to every
-- client (castle combat, contraptions, checkpoints); a sound a client plays is heard by that player only
-- (moveset, UI, and the tool FX every client already draws from ToolResult broadcasts).
--   Audio.play("Dash", root)              3D, parented to a part / attachment (follows it)
--   Audio.play("MeteorImpact", position)  3D at a point (a temporary attachment on Terrain)
--   Audio.play("Click")                   2D
-- One-shots clean themselves up; a Looped def returns the Sound and the caller destroys it.
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sounds = require(ReplicatedStorage.Shared.Config.Sounds)

local Audio = {}

local rng = Random.new()

-- SoundGroups live in SoundService (declared in the Rojo project). The server makes any that are missing (they
-- replicate); a client waits for the server's copy so it never splits a group in two.
local groups: { [string]: SoundGroup } = {}

function Audio.group(name: string): SoundGroup
	local cached = groups[name]
	if cached and cached.Parent then
		return cached
	end
	local g = SoundService:FindFirstChild(name)
	if not g and RunService:IsClient() then
		g = SoundService:WaitForChild(name, 5)
	end
	if not (g and g:IsA("SoundGroup")) then
		local made = Instance.new("SoundGroup")
		made.Name = name
		made.Volume = Sounds.Groups[name] or 1
		made.Parent = SoundService
		g = made
	end
	groups[name] = g :: SoundGroup
	return g :: SoundGroup
end

-- Client: sets each SoundGroup to its Config/Sounds volume × the player's settings slider, now and on every change
-- (only this client hears it: a group volume set on a client doesn't replicate).
local SETTING_FOR = { Music = "MusicVolume", SFX = "SfxVolume", Ambience = "AmbienceVolume", UI = "UiVolume" }
function Audio.UseSettings()
	local Settings = require(ReplicatedStorage.Shared.Util.Settings)
	local function apply(name: string)
		local key = SETTING_FOR[name]
		Audio.group(name).Volume = (Sounds.Groups[name] or 1) * (if key then Settings.Get(key) else 1)
	end
	for name in Sounds.Groups do
		apply(name)
	end
	Settings.Changed:Connect(function(key)
		for name, k in SETTING_FOR do
			if k == key then
				apply(name)
			end
		end
	end)
end

-- A Sound for a def, not yet parented or playing (music/ambience use this for fades).
function Audio.make(def: Sounds.Def, name: string?): Sound
	local s = Instance.new("Sound")
	s.Name = name or "Sound"
	local ids = def.Ids
	s.SoundId = if ids then ids[rng:NextInteger(1, #ids)] else def.Id :: string
	s.Volume = def.Volume
	local var = def.PitchVar or 0
	s.PlaybackSpeed = (def.Pitch or 1) + (if var > 0 then rng:NextNumber(-var, var) else 0)
	s.Looped = def.Looped == true
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 10
	s.RollOffMaxDistance = def.Range or Sounds.Range
	s.SoundGroup = Audio.group(def.Group or "SFX")
	return s
end

function Audio.play(name: string, at: (Instance | Vector3)?, volumeScale: number?): Sound?
	local def = Sounds.Sfx[name]
	if not def then
		warn("[Audio] no sound named", name)
		return nil
	end
	local s = Audio.make(def, name)
	if volumeScale then
		s.Volume *= volumeScale
	end
	local holder: Instance? = nil
	if typeof(at) == "Vector3" then
		local a = Instance.new("Attachment")
		a.Name = "SoundAt"
		a.Position = at -- Terrain sits at the origin, so local = world
		a.Parent = workspace.Terrain
		holder = a
		s.Parent = a
	elseif typeof(at) == "Instance" and at.Parent then
		s.Parent = at
	else
		s.Parent = SoundService -- 2D
	end
	s:Play()
	if holder then
		s.Destroying:Once(function()
			-- skip when the holder is what's being destroyed ("Parent property ... is locked")
			if holder.Parent then
				holder:Destroy()
			end
		end)
	end
	if not s.Looped then
		local target: Instance = holder or s
		s.Ended:Once(function()
			target:Destroy()
		end)
		Debris:AddItem(target, 15) -- in case Ended never fires (unloaded asset, parent streamed out)
	end
	return s
end

if RunService:IsServer() then
	for name in Sounds.Groups do
		Audio.group(name)
	end
end

return Audio
