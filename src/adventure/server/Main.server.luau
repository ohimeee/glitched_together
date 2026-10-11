-- Adventure place entry point: Init services in dependency order, then load the duo's save.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Services = script.Parent.Services
local Net = require(ReplicatedStorage.Shared.Net)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)

-- Create every remote up front so clients never wait on a missing one.
for _, name in
	{
		"ToolUse",
		"ToolResult",
		"GroundPound",
		"Ping",
		"Cutscene",
		"SkipVote",
		"CutsceneDone",
		"Hint",
		"Launch",
		"GameOver",
		"RespawnMash",
		"CameraShake",
		"LevelUp",
		"LevelPick",
		"StationInput",
		"Credits",
		"ContinueYes",
	}
do
	Net.event(name)
end
Net.event("CamSync", true)

local CollisionService = require(Services.CollisionService)
local DuoService = require(Services.DuoService)
local SaveService = require(Services.SaveService)
local CheckpointService = require(Services.CheckpointService)
local WorldService = require(Services.WorldService)
local HealthService = require(Services.HealthService)
local InteractableService = require(Services.InteractableService)
local MoverService = require(Services.MoverService)
local ContraptionService = require(Services.ContraptionService)
local StationService = require(Services.StationService)
local RelayService = require(Services.RelayService)
local HintService = require(Services.HintService)
local CutsceneService = require(Services.CutsceneService)
local AbilityService = require(Services.AbilityService)
local EnemyService = require(Services.EnemyService)
local XpService = require(Services.XpService)
local CombatService = require(Services.CombatService)
local EncounterService = require(Services.EncounterService)
local BossService = require(Services.BossService)
local ArtService = require(Services.ArtService)

Players.CharacterAutoLoads = true

CollisionService.Init()
DuoService.Init()
SaveService.Init()
CheckpointService.Init()
WorldService.Init()
HealthService.Init()
InteractableService.Init()
MoverService.Init()
ContraptionService.Init()
StationService.Init()
RelayService.Init()
HintService.Init()
CutsceneService.Init()
AbilityService.Init()
EnemyService.Init()
XpService.Init()
CombatService.Init()
EncounterService.Init()
BossService.Init()
ArtService.Init()

-- Hints reset on any progress.
InteractableService.Progress:Connect(HintService.Progress)
CheckpointService.Reached:Connect(HintService.Progress)
WorldService.Loaded:Connect(function(worldName: string, restart: boolean?)
	HintService.Progress()
	HealthService.SetMode(worldName)
	HealthService.ResetSafe()
	CombatService.Clear()
	if restart then
		return -- a game over keeps castle levels and ultimate charge; only the rooms reset
	end
	for _, p in DuoService.Players() do
		p:SetAttribute("Ultimate", 0)
	end
	if worldName == "StarfallCastle" then
		XpService.Reset() -- leveling starts fresh each time the castle loads
	end
end)

-- A boss falls (story triggers W1_BossDefeated / W2_BossDefeated): memory cutscene, end-of-world scene, then the
-- exit portal opens.
local BOSS_CUTSCENES = {
	CrusherKing = { "W1_Memory1", "W1_End" },
	HollowDragon = { "W2_Memory2", "W2_End" },
	Unfinished = { "Final_Save" }, -- then the exit opens onto the Epilogue
}
local function unlockExit(exit: BasePart)
	exit:SetAttribute("Locked", nil)
	exit.Transparency = 0.65
	ArtService.DressExit(exit)
end

BossService.Finished:Connect(function(name: string)
	task.wait(2.5) -- let him come apart first
	for _, id in BOSS_CUTSCENES[name] or {} do
		CutsceneService.Play(id)
	end
	for _, exit in CollectionService:GetTagged("WorldExit") do
		if exit:GetAttribute("Locked") and not exit:GetAttribute("AfterYes") then
			unlockExit(exit)
		end
	end
end)

-- Epilogue (Story Line "Continue"): once Pip's hilltop goodbye (GoodbyeTrigger, Epilogue_Goodbye) has played, the
-- real-world ending plays, the save is marked 100% complete and every client rolls the credits.
WorldService.Loaded:Connect(function(worldName: string)
	if worldName ~= "Epilogue" then
		return
	end
	local world = workspace:FindFirstChild("World")
	local trigger = world and world:FindFirstChild("GoodbyeTrigger", true)
	if not trigger then
		return
	end
	task.spawn(function()
		while trigger.Parent and not trigger:GetAttribute("Played") do
			task.wait(0.5)
		end
		if not trigger.Parent then
			return -- the world was rebuilt
		end
		repeat -- the goodbye itself (CutsceneService flags everyone InCutscene while it runs)
			task.wait(0.5)
			local busy = false
			for _, p in DuoService.Players() do
				busy = busy or p:GetAttribute("InCutscene") == true
			end
		until not busy
		task.wait(1.5)
		CutsceneService.Play("Epilogue_End")
		SaveService.Set({ complete = true })
		task.spawn(SaveService.Flush)
		Net.event("Credits"):FireAllClients()
	end)
end)

-- CONTINUE? YES (CreditsController): the way home appears on the hilltop ledge, a BACK TO LOBBY exit. The duo can
-- stay under the stars as long as they like; both inside the exit = teleport to the lobby (WorldService.Advance).
Net.event("ContinueYes").OnServerEvent:Connect(function()
	local world = workspace:FindFirstChild("World")
	if WorldService.Current ~= "Epilogue" or not world then
		return
	end
	for _, part in world:GetDescendants() do
		if not (part:IsA("BasePart") and part:GetAttribute("AfterYes")) then
			continue
		end
		part:SetAttribute("AfterYes", nil)
		if CollectionService:HasTag(part, "WorldExit") then
			unlockExit(part)
		else
			part.Transparency = 0
			for _, gui in part:GetChildren() do
				if gui:IsA("SurfaceGui") then
					gui.Enabled = true
				end
			end
		end
	end
end)

-- Game over (both Downed): rebuild the world and restart at the checkpoint, so every room past it resets
-- (golem pillars, enemies, gates), like reloading a checkpoint.
HealthService.OnRestart = function()
	WorldService.Load(WorldService.Current, CheckpointService.Current(), true)
end

-- Second Wind (Miko, castle level 3): +40 max HP right away.
XpService.UpgradeApplied:Connect(function(p: Player, name: string)
	if name == "SecondWind" then
		local bonus = Tuning.Combat.SecondWind.HP
		p:SetAttribute("BonusHP", bonus)
		HealthService.Restore(p, ((p:GetAttribute("Health") or 0) :: number) + bonus)
	end
end)

-- Wait for the duo (in Studio, a solo tester starts after 3 s), then load their save.
DuoService.WaitForDuo(if game.PrivateServerId == "" then 3 else 30)
local save = SaveService.Load(DuoService.Ids())
WorldService.Load(save.world, save.checkpoint)

if save.world == "Prologue" and save.checkpoint == 0 then
	task.delay(1, CutsceneService.Play, "Intro_Continue")
end

-- Studio only: jump worlds from the command bar with workspace:SetAttribute("DebugWorld", "PixelPlains");
-- set workspace "DebugCheckpoint" (a number) first to start at that checkpoint.
if game:GetService("RunService"):IsStudio() then
	local function debugJump()
		local target = workspace:GetAttribute("DebugWorld")
		if type(target) == "string" then
			local cp = workspace:GetAttribute("DebugCheckpoint")
			WorldService.Load(target, if type(cp) == "number" then cp else 0)
		end
	end
	workspace:GetAttributeChangedSignal("DebugWorld"):Connect(debugJump)
	debugJump() -- set before the first world finished loading
end
