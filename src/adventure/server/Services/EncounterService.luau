-- Castle room fights (user, Oct 11: enemies stood waiting at the entrance; later rooms were too easy).
-- Greybox `encounter()` builds an invisible `EncounterZone` (attr Encounter) and the room's enemies with
-- Encounter / Wave / Dormant. Here a dormant enemy is parked deep under its spot (Home attr = its real CFrame), so
-- it is never seen and CombatService skips it. When a standing player steps into the zone, wave 1 rises: a glitch
-- rift opens on the floor (Tuning.Encounters.Telegraph), the enemy climbs out and hunts at once. Each later wave
-- comes when the room is down to NextWaveAt enemies. A world reload rebuilds everything fresh.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)
local DuoService = require(script.Parent.DuoService)
local CombatFx = require(script.Parent.CombatFx)

local T = Tuning.Encounters

type Encounter = { zone: BasePart, wave: number, waves: number, busy: boolean, readyAt: number }

local EncounterService = {}
local encounters: { [string]: Encounter } = {}

local function park(part: BasePart)
	if part:GetAttribute("Home") or not part:GetAttribute("Dormant") then
		return -- already parked, or a split slime's half (a clone of a fighting one)
	end
	part:SetAttribute("Home", part.CFrame)
	part.CFrame = part.CFrame - Vector3.new(0, T.ParkDepth, 0)
end

local function members(name: string): { BasePart }
	local out = {}
	for _, inst in CollectionService:GetTagged("Enemy") do
		if inst:GetAttribute("Encounter") == name and inst:IsA("BasePart") and inst:IsDescendantOf(workspace) then
			table.insert(out, inst)
		end
	end
	return out
end

local function alive(name: string): number
	local n = 0
	for _, part in members(name) do
		if not part:GetAttribute("Dormant") and (part:GetAttribute("HP") or 1) > 0 then
			n += 1
		end
	end
	return n
end

local function rise(part: BasePart)
	local home = part:GetAttribute("Home") :: CFrame?
	if not home or not part.Parent then
		return
	end
	local floorPos = home.Position - Vector3.new(0, part.Size.Y / 2 - 0.15, 0)
	local rift = CombatFx.AreaMarker(floorPos, math.max(part.Size.X, part.Size.Z) * 0.75 + 1, Palette.Danger)
	CombatFx.Burst(floorPos, { { "Stars", 10, 1.2, Palette.Glitch } }, Palette.Glitch, 10)
	Audio.play("GlitchStatic", floorPos)
	task.wait(T.Telegraph)
	if not part.Parent then
		rift:Destroy()
		return
	end
	part.CFrame = home - Vector3.new(0, part.Size.Y + 0.5, 0) -- just under the floor
	local tween = TweenService:Create(part, TweenInfo.new(T.Rise, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		CFrame = home,
	})
	tween:Play()
	CombatFx.Burst(floorPos, { { "Stars", 14, 1.4, Palette.Glitch }, { "Smoke", 5, 1.4, Color3.fromRGB(70, 60, 90) } })
	Audio.play("Teleport", floorPos)
	tween.Completed:Wait()
	rift:Destroy()
	part:SetAttribute("Hunting", true) -- a room fight: it comes for the duo straight away
	part:SetAttribute("Dormant", nil)
end

local function startWave(name: string, e: Encounter)
	e.wave += 1
	e.busy = true
	local list = {}
	for _, part in members(name) do
		if part:GetAttribute("Wave") == e.wave and part:GetAttribute("Dormant") then
			table.insert(list, part)
		end
	end
	task.spawn(function()
		for i, part in list do
			task.spawn(rise, part)
			if i < #list then
				task.wait(T.Stagger)
			end
		end
		task.wait(T.Telegraph + T.Rise + 0.1)
		e.busy = false
	end)
end

local function playerInside(zone: BasePart): boolean
	for _, p in DuoService.Players() do
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root and not p:GetAttribute("Downed") then
			local lp = zone.CFrame:PointToObjectSpace(root.Position)
			local half = zone.Size / 2
			if math.abs(lp.X) <= half.X and math.abs(lp.Y) <= half.Y and math.abs(lp.Z) <= half.Z then
				return true
			end
		end
	end
	return false
end

local function step()
	local now = os.clock()
	for name, e in encounters do
		if not e.zone:IsDescendantOf(workspace) then
			encounters[name] = nil
		elseif e.busy then
			continue
		elseif e.wave == 0 then
			if playerInside(e.zone) then
				startWave(name, e)
			end
		elseif e.wave < e.waves then
			if alive(name) <= T.NextWaveAt then
				if e.readyAt == 0 then
					e.readyAt = now + T.WaveGap
				elseif now >= e.readyAt then
					e.readyAt = 0
					startWave(name, e)
				end
			end
		end
	end
end

function EncounterService.Init()
	Tags.each("Enemy", function(inst)
		if inst:IsA("BasePart") and inst:GetAttribute("Encounter") then
			park(inst)
		end
	end)
	Tags.each("EncounterZone", function(inst)
		local name = inst:GetAttribute("Encounter")
		if not (inst:IsA("BasePart") and name) then
			return
		end
		task.defer(function() -- the room's enemies are parented with the same world model
			local waves = 0
			for _, part in members(name) do
				waves = math.max(waves, part:GetAttribute("Wave") or 1)
			end
			encounters[name] = { zone = inst, wave = 0, waves = waves, busy = false, readyAt = 0 }
		end)
	end, function(inst)
		local name = inst:GetAttribute("Encounter")
		if name and encounters[name] and encounters[name].zone == inst then
			encounters[name] = nil
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.2)
			step()
		end
	end)
end

return EncounterService
