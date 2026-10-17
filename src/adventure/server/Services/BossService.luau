-- Runs phase-based bosses (implementation.md §12). A boss module (server/Bosses/<Name>) returns
-- { Setup(self, world), Cleanup(self), Phases = { { Name, Enter(self), Update(self, dt), IsDone(self): boolean,
-- Exit(self) }, … } }. Each phase start is saved, so a game over (the world reloads at the arena checkpoint)
-- restarts the fight at that phase, never from the top.
--
-- A fight starts when the whole duo stands inside a part tagged `BossTrigger` (attribute `Boss` = module name).
-- The HUD reads workspace BossName / BossHealth (0..1) / BossPhaseName.
local RunService = game:GetService("RunService")

local Tags = require(game:GetService("ReplicatedStorage").Shared.Util.Tags)
local SaveService = require(script.Parent.SaveService)
local DuoService = require(script.Parent.DuoService)

local Bosses = script.Parent.Parent.Bosses

local BossService = {}

export type Phase = {
	Name: string,
	Enter: (self: any) -> (),
	Update: (self: any, dt: number) -> (),
	IsDone: (self: any) -> boolean,
	Exit: (self: any) -> (),
}

local DISPLAY = { CrusherKing = "THE CRUSHER KING", HollowDragon = "THE HOLLOW DRAGON", Unfinished = "THE UNFINISHED" }

local finished = Instance.new("BindableEvent")
BossService.Finished = finished.Event -- (bossName)

local running: {
	name: string,
	phases: { Phase },
	index: number,
	state: any,
	world: Instance,
	conn: RBXScriptConnection,
}? =
	nil

local function enter(index: number)
	local r = running
	if not r then
		return
	end
	r.index = index
	local phase = r.phases[index]
	workspace:SetAttribute("BossPhase", index)
	workspace:SetAttribute("BossPhaseName", phase.Name)
	SaveService.Set({ boss = r.name, bossPhase = index })
	task.spawn(SaveService.Flush)
	phase.Enter(r.state)
end

function BossService.Start(name: string, startPhase: number?)
	if running then
		return
	end
	local module = Bosses:FindFirstChild(name)
	local world = workspace:FindFirstChild("World")
	if not (module and module:IsA("ModuleScript") and world) then
		warn(`[BossService] No boss module Bosses.{name}`)
		return
	end
	local boss = require(module) :: any
	local state = setmetatable({}, { __index = boss })
	if boss.Setup then
		boss.Setup(state, world)
	end
	workspace:SetAttribute("BossFight", true)
	-- the boss track: unlike BossFight it stays through a game-over reload (user, Oct 4: respawning brought back
	-- the world's music) and only ends when he's beaten or the duo leaves the world
	workspace:SetAttribute("BossMusic", true)
	workspace:SetAttribute("BossName", DISPLAY[name] or name)

	local r = { name = name, phases = boss.Phases, index = 0, state = state, world = world, conn = nil :: any }
	running = r
	r.conn = RunService.Heartbeat:Connect(function(dt)
		if not r.world:IsDescendantOf(workspace) then
			BossService.Stop() -- the world was rebuilt under the fight (game over, debug jump)
			return
		end
		if workspace:GetAttribute("Paused") then
			return
		end
		local phase = r.phases[r.index]
		if not phase then
			return
		end
		phase.Update(r.state, dt)
		if phase.IsDone(r.state) then
			phase.Exit(r.state)
			if r.index >= #r.phases then
				BossService.Stop()
				workspace:SetAttribute("BossMusic", nil)
				SaveService.Set({ boss = false, bossPhase = false })
				task.spawn(SaveService.Flush)
				for _, trigger in Tags.list("BossTrigger") do
					if trigger:GetAttribute("Boss") == name then
						trigger:SetAttribute("Played", true) -- beaten: walking back in doesn't start it again
					end
				end
				finished:Fire(name)
			else
				enter(r.index + 1)
			end
		end
	end)
	enter(math.clamp(startPhase or 1, 1, #boss.Phases))
end

function BossService.Stop()
	local r = running
	if not r then
		return
	end
	r.conn:Disconnect()
	running = nil
	local boss = getmetatable(r.state).__index
	if boss.Cleanup then
		boss.Cleanup(r.state)
	end
	for _, attr in { "BossFight", "BossPhase", "BossPhaseName", "BossName", "BossHealth" } do
		workspace:SetAttribute(attr, nil)
	end
end

function BossService.Running(): string?
	return running and running.name
end

function BossService.Init()
	workspace:GetAttributeChangedSignal("World"):Connect(function()
		workspace:SetAttribute("BossMusic", nil) -- a different world: its own music
	end)
	-- workspace:SetAttribute("DebugBossPhase", n) (Studio, or the admin /phase command) jumps the running fight to
	-- phase n (solo tests of phases that need both players); a number past the last phase finishes the fight.
	do
		workspace:GetAttributeChangedSignal("DebugBossPhase"):Connect(function()
			local n = workspace:GetAttribute("DebugBossPhase")
			local r = running
			if not (r and type(n) == "number") then
				return
			end
			local phase = r.phases[r.index]
			if phase then
				phase.Exit(r.state)
			end
			if n > #r.phases then
				local name = r.name
				BossService.Stop()
				workspace:SetAttribute("BossMusic", nil)
				finished:Fire(name)
			else
				enter(n)
			end
		end)
	end
	-- Boss triggers: the whole duo inside starts the fight (at the saved phase after a game over).
	task.spawn(function()
		while true do
			task.wait(0.25)
			local duo = DuoService.Players()
			if running or #duo == 0 then
				continue
			end
			for _, trigger in Tags.list("BossTrigger") do
				if
					not trigger:IsA("BasePart")
					or not trigger:IsDescendantOf(workspace)
					or trigger:GetAttribute("Played")
				then
					continue
				end
				local all = true
				for _, p in duo do
					local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					local lp = root and trigger.CFrame:PointToObjectSpace(root.Position)
					local h = trigger.Size / 2
					if not (lp and math.abs(lp.X) <= h.X and math.abs(lp.Y) <= h.Y and math.abs(lp.Z) <= h.Z) then
						all = false
						break
					end
				end
				if all then
					local name = trigger:GetAttribute("Boss") :: string
					local save = SaveService.Get() :: any
					local phase = if save.boss == name and type(save.bossPhase) == "number" then save.bossPhase else 1
					local ok, err = pcall(BossService.Start, name, phase)
					if not ok then
						warn("[BossService]", err)
						trigger:SetAttribute("Played", true)
					end
					break
				end
			end
		end
	end)
end

-- A boss's intro cutscene (W<n>_BossIntro; CutsceneService.OnStart): the boss track starts with the drone flight
-- (user, Oct 12: "the boss sound is not playing in the drone shot"; BossMusic keeps it through the fight), and a boss
-- module with `Intro(world, shots)` comes alive for it (it returns a stop function that puts the boss back exactly as
-- built, so the fight's Setup measures the same pose).
function BossService.Intro(id: string, shots: { any }?): (() -> ())?
	if not string.match(id, "^W%d_BossIntro$") then
		return nil
	end
	local world = workspace:FindFirstChild("World")
	local name: string? = nil
	for _, trigger in Tags.list("BossTrigger") do
		if world and trigger:IsDescendantOf(world) then
			name = trigger:GetAttribute("Boss") :: string
		end
	end
	workspace:SetAttribute("BossMusic", true)
	local module = name and Bosses:FindFirstChild(name)
	local stopBoss: (() -> ())? = nil
	if module and module:IsA("ModuleScript") then
		local boss = require(module) :: any
		if boss.Intro and world then
			stopBoss = boss.Intro(world, shots or {})
		end
	end
	return function()
		if stopBoss then
			stopBoss()
		end
	end
end

return BossService
