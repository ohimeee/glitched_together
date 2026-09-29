-- Adventure place entry point: Init services in dependency order, then load the duo's save.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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
		"LevelUp",
		"LevelPick",
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
local RelayService = require(Services.RelayService)
local HintService = require(Services.HintService)
local CutsceneService = require(Services.CutsceneService)
local AbilityService = require(Services.AbilityService)
local EnemyService = require(Services.EnemyService)
local XpService = require(Services.XpService)
local CombatService = require(Services.CombatService)
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
RelayService.Init()
HintService.Init()
CutsceneService.Init()
AbilityService.Init()
EnemyService.Init()
XpService.Init()
CombatService.Init()
BossService.Init()
ArtService.Init()

-- Hints reset on any progress.
InteractableService.Progress:Connect(HintService.Progress)
CheckpointService.Reached:Connect(HintService.Progress)
WorldService.Loaded:Connect(function(worldName: string)
	HintService.Progress()
	HealthService.SetMode(worldName)
	HealthService.ResetSafe()
	CombatService.Clear()
	for _, p in DuoService.Players() do
		p:SetAttribute("Ultimate", 0)
	end
	if worldName == "StarfallCastle" then
		XpService.Reset() -- leveling starts fresh each time the castle loads
	end
end)

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

-- Studio only: jump worlds from the command bar with workspace:SetAttribute("DebugWorld", "PixelPlains").
if game:GetService("RunService"):IsStudio() then
	workspace:GetAttributeChangedSignal("DebugWorld"):Connect(function()
		local target = workspace:GetAttribute("DebugWorld")
		if type(target) == "string" then
			WorldService.Load(target, 0)
		end
	end)
end
