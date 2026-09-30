-- Castle leveling (mechanics.md §4 World 2 "Leveling"): enemies drop XP orbs that fly to the nearest player;
-- every pickup gives full XP to BOTH players. At each threshold both get a 2-choice upgrade picker and the game
-- pauses for the duo (Picking attribute: blocks tools, MenuContext on the client, CombatService freezes AI)
-- until each has picked. Upgrades are player attributes `Up_<Name>` read by the tool modules.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)
local Net = require(ReplicatedStorage.Shared.Net)
local DuoService = require(script.Parent.DuoService)

local XpService = {}

-- Options per role per level (mechanics.md table). Names become `Up_<Name>` attributes.
XpService.Options = {
	Kai = { [2] = { "BiggerFireball", "FasterCast" }, [3] = { "DoubleFlameWall", "EmberTrail" } },
	Miko = { [2] = { "WiderBlock", "LongerCharge" }, [3] = { "ReflectBoost", "SecondWind" } },
}

type Orb = { part: BasePart, amount: number, born: number }
local orbs: { Orb } = {}
local folder: Folder
local levelUpEvent = Net.event("LevelUp")
local pending: { [Player]: { string } } = {} -- players still choosing → their two options
local upgradeApplied = Instance.new("BindableEvent")
XpService.UpgradeApplied = upgradeApplied.Event -- (player, name)

local function rootOf(p: Player): BasePart?
	return p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function levelFor(xp: number): number
	local level = 1
	for i, need in Tuning.XpLevels do
		if xp >= need then
			level = i + 1
		end
	end
	return level
end

local function finishPick(p: Player, choice: string)
	pending[p] = nil
	p:SetAttribute(`Up_{choice}`, true)
	upgradeApplied:Fire(p, choice)
	if next(pending) == nil then
		for _, q in DuoService.Players() do
			q:SetAttribute("Picking", nil)
		end
	end
end

local function startPick(level: number)
	for _, p in DuoService.Players() do
		local role = p:GetAttribute("Role")
		local options = role and (XpService.Options :: any)[role] and (XpService.Options :: any)[role][level]
		if options then
			pending[p] = options
			p:SetAttribute("Picking", true)
			levelUpEvent:FireClient(p, level, options)
			-- never soft-lock the duo: auto-pick the first option after 30 s
			task.delay(30, function()
				if pending[p] == options then
					finishPick(p, options[1])
				end
			end)
		end
	end
end

function XpService.Give(amount: number)
	local before, after = 0, 0
	for _, p in DuoService.Players() do
		local xp = (p:GetAttribute("XP") or 0) :: number
		before = math.max(before, levelFor(xp))
		p:SetAttribute("XP", xp + amount)
		p:SetAttribute("Level", levelFor(xp + amount))
		after = math.max(after, levelFor(xp + amount))
	end
	for level = before + 1, after do
		startPick(level)
	end
end

function XpService.Drop(pos: Vector3, amount: number)
	local part = Instance.new("Part")
	part.Name = "XPOrb"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.one * 1.2
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(60, 255, 120)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CFrame = CFrame.new(pos + Vector3.new(0, 1, 0))
	part.Parent = folder
	table.insert(orbs, { part = part, amount = amount, born = os.clock() })
end

-- Entering the castle starts leveling fresh (a new run of the world).
function XpService.Reset()
	for _, p in DuoService.Players() do
		p:SetAttribute("XP", 0)
		p:SetAttribute("Level", 1)
		p:SetAttribute("Picking", nil)
		p:SetAttribute("BonusHP", nil)
		for _, byLevel in XpService.Options do
			for _, options in byLevel do
				for _, name in options do
					p:SetAttribute(`Up_{name}`, nil)
				end
			end
		end
	end
	table.clear(pending)
	for _, orb in orbs do
		orb.part:Destroy()
	end
	table.clear(orbs)
end

function XpService.Init()
	folder = Instance.new("Folder")
	folder.Name = "XPOrbs"
	folder.Parent = workspace

	Net.event("LevelPick").OnServerEvent:Connect(function(p: Player, choice: any)
		local options = pending[p]
		if options and type(choice) == "string" and table.find(options, choice) then
			finishPick(p, choice)
		end
	end)

	Players.PlayerRemoving:Connect(function(p)
		if pending[p] then
			finishPick(p, pending[p][1])
		end
	end)

	RunService.Heartbeat:Connect(function(dt)
		for i = #orbs, 1, -1 do
			local orb = orbs[i]
			if os.clock() - orb.born < 0.5 then
				continue -- let it pop out before it homes in
			end
			local best: BasePart?, bestD = nil, math.huge
			for _, p in DuoService.Players() do
				local r = rootOf(p)
				if r and not p:GetAttribute("Downed") then
					local d = (r.Position - orb.part.Position).Magnitude
					if d < bestD then
						best, bestD = r, d
					end
				end
			end
			if best then
				if bestD <= Tuning.Combat.OrbPickup then
					Audio.play("XpPickup", best)
					orb.part:Destroy()
					table.remove(orbs, i)
					XpService.Give(orb.amount)
				else
					local step = math.min(bestD, Tuning.Combat.OrbSpeed * dt)
					orb.part.CFrame = CFrame.new(orb.part.Position + (best.Position - orb.part.Position).Unit * step)
				end
			end
		end
	end)
end

return XpService
