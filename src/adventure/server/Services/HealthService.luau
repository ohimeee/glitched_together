-- Hearts / HP, Downed ghosts, partner revive, kill zones and safe-ground respawn (implementation.md §9).
-- Roblox's normal death never happens: nothing sets Humanoid.Health to 0.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Net = require(ReplicatedStorage.Shared.Net)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local DuoService = require(script.Parent.DuoService)
local CheckpointService = require(script.Parent.CheckpointService)

local HealthService = {}

type State = {
	lastHit: number,
	invulnUntil: number,
	respawnLeft: number,
	falling: boolean,
	safe: CFrame?,
}

local states: { [Player]: State } = {}
local useHP = false -- castle uses an HP bar instead of hearts
local gameOverRunning = false

local gameOverEvent = Net.event("GameOver")
local mashEvent = Net.event("RespawnMash")

local function state(p: Player): State
	local s = states[p]
	if not s then
		s = { lastHit = 0, invulnUntil = 0, respawnLeft = 0, falling = false, safe = nil }
		states[p] = s
	end
	return s
end

local function maxHealth(p: Player): number
	if useHP then
		local base = (Tuning.CastleHP :: any)[p:GetAttribute("Role") or "Kai"] or 100
		return base + (p:GetAttribute("BonusHP") or 0) -- Second Wind upgrade
	end
	return Tuning.Hearts
end

local function humanoidOf(p: Player): Humanoid?
	return p.Character and p.Character:FindFirstChildOfClass("Humanoid")
end

local function rootOf(p: Player): BasePart?
	return p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function setGhost(p: Player, ghost: boolean)
	local character = p.Character
	if not character then
		return
	end
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			if ghost then
				if d:GetAttribute("OrigT") == nil then
					d:SetAttribute("OrigT", d.Transparency)
				end
				d.Transparency = math.max(d.Transparency, if d.Name == "HumanoidRootPart" then 1 else 0.6)
			else
				local orig = d:GetAttribute("OrigT")
				if orig ~= nil then
					d.Transparency = orig
					d:SetAttribute("OrigT", nil)
				end
			end
		end
	end
	local humanoid = humanoidOf(p)
	if humanoid then
		humanoid.WalkSpeed = if ghost then Tuning.GhostSpeed else Tuning.WalkSpeed
	end

	local root = rootOf(p)
	local prompt = root and root:FindFirstChild("RevivePrompt") :: ProximityPrompt?
	if ghost and root and not prompt then
		local newPrompt = Instance.new("ProximityPrompt")
		newPrompt.Name = "RevivePrompt"
		newPrompt.ActionText = "Revive"
		newPrompt.ObjectText = p.DisplayName
		newPrompt.HoldDuration = Tuning.ReviveHold
		newPrompt.MaxActivationDistance = Tuning.ReviveRange
		newPrompt.RequiresLineOfSight = false
		newPrompt.KeyboardKeyCode = Enum.KeyCode.E
		newPrompt.GamepadKeyCode = Enum.KeyCode.ButtonX
		newPrompt.Parent = root -- the Downed player's own client hides it (HUDController)
		newPrompt.Triggered:Connect(function(by: Player)
			if by ~= p and DuoService.PartnerOf(by) == p and not by:GetAttribute("Downed") then
				HealthService.Revive(p, true)
			end
		end)
	elseif not ghost and prompt then
		prompt:Destroy()
	end
end

local function place(p: Player, cf: CFrame)
	local character = p.Character
	if not character then
		return
	end
	pcall(function()
		p:RequestStreamAroundAsync(cf.Position, 3)
	end)
	character:PivotTo(cf)
	local root = rootOf(p)
	if root then
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

function HealthService.SetMode(worldName: string)
	useHP = worldName == "StarfallCastle"
	for _, p in DuoService.Players() do
		HealthService.Restore(p, maxHealth(p))
	end
end

function HealthService.Restore(p: Player, amount: number)
	p:SetAttribute("MaxHealth", maxHealth(p))
	p:SetAttribute("Health", math.min(amount, maxHealth(p)))
	p:SetAttribute("HealthKind", if useHP then "HP" else "Hearts")
end

function HealthService.Revive(p: Player, onTheSpot: boolean)
	if not p:GetAttribute("Downed") then
		return
	end
	p:SetAttribute("Downed", nil)
	p:SetAttribute("RespawnAt", nil)
	setGhost(p, false)
	HealthService.Restore(p, if useHP then Tuning.ReviveHP else 1)
	state(p).invulnUntil = os.clock() + Tuning.HitInvuln * 2
	if not onTheSpot then
		-- Auto-respawn: next to the partner's last safe spot if they're up, else at the checkpoint.
		local partner = DuoService.PartnerOf(p)
		local ps = partner and states[partner]
		if partner and ps and ps.safe and not partner:GetAttribute("Downed") then
			place(p, ps.safe * CFrame.new(3, 1, 0))
		else
			place(p, CheckpointService.SpawnCFrame(p))
		end
	end
end

local function bothDown()
	if gameOverRunning then
		return
	end
	gameOverRunning = true
	gameOverEvent:FireAllClients()
	task.wait(1.6)
	for _, p in DuoService.Players() do
		p:SetAttribute("Downed", nil)
		p:SetAttribute("RespawnAt", nil)
		setGhost(p, false)
		HealthService.Restore(p, maxHealth(p))
		place(p, CheckpointService.SpawnCFrame(p))
	end
	gameOverRunning = false
end

function HealthService.Down(p: Player)
	if p:GetAttribute("Downed") then
		return
	end
	p:SetAttribute("Health", 0)
	p:SetAttribute("Downed", true)
	setGhost(p, true)

	local partner = DuoService.PartnerOf(p)
	if not partner or partner:GetAttribute("Downed") then
		task.spawn(bothDown)
		return
	end

	local s = state(p)
	s.respawnLeft = if workspace:GetAttribute("BossFight") then Tuning.DownedRespawnBoss else Tuning.DownedRespawn
	task.spawn(function()
		while p.Parent and p:GetAttribute("Downed") and s.respawnLeft > 0 do
			p:SetAttribute("RespawnAt", workspace:GetServerTimeNow() + s.respawnLeft)
			local dt = task.wait(0.1)
			s.respawnLeft -= dt
		end
		if p.Parent and p:GetAttribute("Downed") and not gameOverRunning then
			HealthService.Revive(p, false)
		end
	end)
end

function HealthService.Damage(p: Player, amount: number)
	if p:GetAttribute("Downed") or p:GetAttribute("InCutscene") or gameOverRunning then
		return
	end
	local s = state(p)
	local now = os.clock()
	if now < s.invulnUntil then
		return
	end
	s.invulnUntil = now + (if useHP then 0.15 else Tuning.HitInvuln)
	s.lastHit = now

	local health = (p:GetAttribute("Health") or maxHealth(p)) - amount
	p:SetAttribute("Health", math.max(0, health))
	if health <= 0 then
		HealthService.Down(p)
	end
end

-- Fell into a kill zone (or off the world): back to the last safe ground after 1.5 s. No damage.
function HealthService.Fall(p: Player)
	local s = state(p)
	if s.falling or p:GetAttribute("Downed") then
		return
	end
	s.falling = true
	p:SetAttribute("Falling", true)
	task.delay(Tuning.KillZoneRespawnDelay, function()
		s.falling = false
		p:SetAttribute("Falling", nil)
		if p.Parent then
			place(p, s.safe or CheckpointService.SpawnCFrame(p))
		end
	end)
end

function HealthService.ResetSafe()
	for _, s in states do
		s.safe = nil
	end
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local UNSAFE = { "Mover", "KillZone", "Freezable", "Pullable", "Hazard", "Pasted", "CrackedFloor" }

local function trackSafeGround()
	while true do
		task.wait(Tuning.SafePosEvery)
		local killY = workspace:GetAttribute("KillY") or -150
		for _, p in DuoService.Players() do
			local root = rootOf(p)
			local humanoid = humanoidOf(p)
			if not (root and humanoid) or p:GetAttribute("Downed") then
				continue
			end
			if root.Position.Y < killY then
				HealthService.Fall(p)
				continue
			end
			if humanoid.FloorMaterial == Enum.Material.Air or state(p).falling then
				continue
			end
			rayParams.FilterDescendantsInstances = { p.Character :: Model }
			local hit = workspace:Raycast(root.Position, Vector3.new(0, -6, 0), rayParams)
			if hit and hit.Instance.Anchored then
				local unsafe = false
				for _, tag in UNSAFE do
					if Tags.find(hit.Instance, tag) then
						unsafe = true
						break
					end
				end
				if not unsafe then
					state(p).safe = CFrame.new(root.Position + Vector3.new(0, 1, 0)) * root.CFrame.Rotation
				end
			end
		end
	end
end

local function regenLoop()
	while true do
		task.wait(1)
		if useHP then
			continue
		end
		local now = os.clock()
		for _, p in DuoService.Players() do
			local s = state(p)
			local health = p:GetAttribute("Health") or 0
			if
				not p:GetAttribute("Downed")
				and health < Tuning.Hearts
				and now - s.lastHit >= Tuning.HeartRegenEvery
			then
				p:SetAttribute("Health", health + 1)
				s.lastHit = now -- next heart needs another 5 s
			end
		end
	end
end

local function touchedBy(part: BasePart, fn: (Player) -> ())
	part.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local p = character and Players:GetPlayerFromCharacter(character)
		if p then
			fn(p)
		end
	end)
end

function HealthService.Init()
	local function hook(p: Player)
		p.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid") :: Humanoid
			humanoid.BreakJointsOnDeath = false
			HealthService.Restore(p, maxHealth(p))
			p:SetAttribute("Downed", nil)
			p:SetAttribute("RespawnAt", nil)
		end)
	end
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)
	Players.PlayerRemoving:Connect(function(p)
		states[p] = nil
	end)

	Tags.each("KillZone", function(inst)
		if inst:IsA("BasePart") then
			touchedBy(inst, HealthService.Fall)
		end
	end)
	Tags.each("Hazard", function(inst)
		if inst:IsA("BasePart") then
			touchedBy(inst, function(p)
				HealthService.Damage(p, inst:GetAttribute("Damage") or 1)
			end)
		end
	end)

	-- Boss fights: each Jump press while Downed takes 0.15 s off the timer.
	mashEvent.OnServerEvent:Connect(function(p: Player)
		local s = states[p]
		if s and p:GetAttribute("Downed") and workspace:GetAttribute("BossFight") then
			s.respawnLeft -= Tuning.MashStep
		end
	end)

	task.spawn(trackSafeGround)
	task.spawn(regenLoop)
end

return HealthService
