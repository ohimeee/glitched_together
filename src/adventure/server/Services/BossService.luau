-- Runs phase-based bosses (implementation.md §12). A boss module (ServerStorage.Bosses.<Name>) returns
-- { Phases = { { Name, Enter(self), Update(self, dt), IsDone(self): boolean, Exit(self) }, … } }.
-- Each phase start is a checkpoint, so a wipe never restarts the whole fight.
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local SaveService = require(script.Parent.SaveService)

local BossService = {}

export type Phase = {
	Name: string,
	Enter: (self: any) -> (),
	Update: (self: any, dt: number) -> (),
	IsDone: (self: any) -> boolean,
	Exit: (self: any) -> (),
}

local finished = Instance.new("BindableEvent")
BossService.Finished = finished.Event -- (bossName)

local running: { name: string, phases: { Phase }, index: number, state: any, conn: RBXScriptConnection }? = nil

local function enter(index: number)
	local r = running
	if not r then
		return
	end
	r.index = index
	workspace:SetAttribute("BossPhase", index)
	SaveService.Set({ bossPhase = index })
	task.spawn(SaveService.Flush)
	r.phases[index].Enter(r.state)
end

function BossService.Start(name: string, startPhase: number?)
	if running then
		return
	end
	local folder = ServerStorage:FindFirstChild("Bosses")
	local module = folder and folder:FindFirstChild(name)
	if not (module and module:IsA("ModuleScript")) then
		warn(`[BossService] No boss module ServerStorage.Bosses.{name}`)
		return
	end
	local boss = require(module) :: any
	local state = setmetatable({}, { __index = boss })
	workspace:SetAttribute("BossFight", true)

	local r = { name = name, phases = boss.Phases, index = 0, state = state, conn = nil :: any }
	running = r
	r.conn = RunService.Heartbeat:Connect(function(dt)
		local phase = r.phases[r.index]
		if not phase then
			return
		end
		phase.Update(r.state, dt)
		if phase.IsDone(r.state) then
			phase.Exit(r.state)
			if r.index >= #r.phases then
				BossService.Stop()
				finished:Fire(name)
			else
				enter(r.index + 1)
			end
		end
	end)
	enter(startPhase or 1)
end

function BossService.Stop()
	local r = running
	if not r then
		return
	end
	r.conn:Disconnect()
	running = nil
	workspace:SetAttribute("BossFight", nil)
	workspace:SetAttribute("BossPhase", nil)
end

function BossService.Init() end

return BossService
