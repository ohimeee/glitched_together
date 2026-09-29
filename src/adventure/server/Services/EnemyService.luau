-- Enemies (mechanics.md §4). For now: contact damage, freeze/stun awareness and a simple patrol so
-- World 1 grey-boxes have threats. Full state machines (Idle → Chase → Attack → Recover, Stunned) are M3/M4.
--
-- Tag a Model (with PrimaryPart) or a BasePart `Enemy`. Attributes: Type ("GlitchBlob" | "StaticBat" | …),
-- Damage (default 1), PatrolDistance (studs, default 0 = stand still), Speed (default 6).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local HealthService = require(script.Parent.HealthService)
local InteractableService = require(script.Parent.InteractableService)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)

local EnemyService = {}

type Enemy = { inst: Instance, root: BasePart, origin: CFrame, t: number }
local enemies: { [Instance]: Enemy } = {}

local function rootOf(inst: Instance): BasePart?
	if inst:IsA("BasePart") then
		return inst
	elseif inst:IsA("Model") then
		return inst.PrimaryPart
	end
	return nil
end

local function disabled(inst: Instance): boolean
	return inst:GetAttribute("Frozen") == true or (inst:GetAttribute("StunnedUntil") or 0) > os.clock()
end

function EnemyService.Stun(pos: Vector3, radius: number, duration: number)
	for inst, e in enemies do
		if (e.root.Position - pos).Magnitude <= radius then
			inst:SetAttribute("StunnedUntil", os.clock() + duration)
		end
	end
end

local function register(inst: Instance)
	local root = rootOf(inst)
	if not root then
		return
	end
	root.Anchored = true
	enemies[inst] = { inst = inst, root = root, origin = root.CFrame, t = 0 }
	for _, part in (if inst:IsA("Model") then inst:GetDescendants() else { root }) :: { Instance } do
		if part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				if disabled(inst) then
					return
				end
				local character = hit:FindFirstAncestorOfClass("Model")
				local p = character and Players:GetPlayerFromCharacter(character)
				if p then
					HealthService.Damage(p, inst:GetAttribute("Damage") or 1)
				end
			end)
		end
	end
end

function EnemyService.Init()
	Tags.each("Enemy", register, function(inst)
		enemies[inst] = nil
	end)

	-- Ground pound stuns small enemies in a 5-stud radius (mechanics.md §2).
	InteractableService.Pounded:Connect(function(_p, pos: Vector3)
		EnemyService.Stun(pos, Tuning.PoundStunRadius, 1.5)
	end)

	RunService.Heartbeat:Connect(function(dt)
		for inst, e in enemies do
			if not e.root.Parent then
				enemies[inst] = nil
				continue
			end
			local distance = inst:GetAttribute("PatrolDistance") or 0
			if distance <= 0 or disabled(inst) then
				continue
			end
			local speed = inst:GetAttribute("Speed") or 6
			e.t += dt * speed / math.max(distance, 1)
			local offset = math.sin(e.t) * distance / 2
			local cf = e.origin * CFrame.new(offset, 0, 0)
			if inst:IsA("Model") then
				inst:PivotTo(cf * e.root.CFrame:ToObjectSpace(inst:GetPivot()))
			else
				e.root.CFrame = cf
			end
		end
	end)
end

return EnemyService
