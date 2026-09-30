-- Two-player level pieces (mechanics.md §2): Pressure Plates, Duo Gates, Duo Pound buttons, Heavy Levers,
-- plus ground-pound reactions (Bounce Pads, Jump Vent buttons, cracked floors).
--
-- Groups: every trigger (plate, pound button, lever, pulled lever) carries a `Group` attribute.
-- A DuoGate opens when every trigger in its Group is active. Gates latch open unless `Latch = false`.
-- `OpenOffset` (Vector3) + `Solid` turn a gate into a lift or a bridge that moves into place when its group is active.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Net = require(ReplicatedStorage.Shared.Net)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)
local DuoService = require(script.Parent.DuoService)

local InteractableService = {}

local progress = Instance.new("BindableEvent")
InteractableService.Progress = progress.Event -- (what: string, inst: Instance) for hints and bosses
local pounded = Instance.new("BindableEvent")
InteractableService.Pounded = pounded.Event -- (player, position)

local launchEvent = Net.event("Launch")
local poundEvent = Net.event("GroundPound")

local TRIGGER_TAGS = { "PressurePlate", "DuoPound", "HeavyLever", "LeverPull", "FireSwitch" } -- FireSwitch: hit by a fireball (CombatService)

local function isActive(inst: Instance): boolean
	return inst:GetAttribute("Active") == true
end

local function setActive(inst: Instance, active: boolean)
	if isActive(inst) == active then
		return
	end
	inst:SetAttribute("Active", active)
	local at = if inst:IsA("BasePart") then inst else inst:FindFirstChildWhichIsA("BasePart", true)
	if Tags.has(inst, "PressurePlate") or Tags.has(inst, "DuoPound") then
		Audio.play(if active then "PlateDown" else "PlateUp", at)
	elseif active then
		Audio.play("Lever", at)
	end
	if inst:IsA("BasePart") then
		if inst:GetAttribute("OrigColor") == nil then
			inst:SetAttribute("OrigColor", inst.Color)
		end
		inst.Color = if active then Color3.fromRGB(90, 255, 140) else inst:GetAttribute("OrigColor") :: Color3
		inst.Material = if active then Enum.Material.Neon else Enum.Material.SmoothPlastic
	end
	if active then
		progress:Fire("Trigger", inst)
	end
end

local function partsOf(inst: Instance): { BasePart }
	if inst:IsA("BasePart") then
		return { inst }
	end
	local list = {}
	for _, d in inst:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

local function setGateOpen(gate: Instance, open: boolean)
	if (gate:GetAttribute("Open") == true) == open then
		return
	end
	gate:SetAttribute("Open", open)
	local parts = partsOf(gate)
	if parts[1] then
		Audio.play("GateMove", parts[1])
	end
	for _, part in parts do
		if part:GetAttribute("ClosedCFrame") == nil then
			part:SetAttribute("ClosedCFrame", part.CFrame)
		end
		local closed = part:GetAttribute("ClosedCFrame") :: CFrame
		-- default: sink into the floor. OpenOffset (world studs) moves it instead, e.g. a lift or a bridge that
		-- rises into place; Solid keeps it collidable once open.
		local offset = gate:GetAttribute("OpenOffset") :: Vector3?
		local sunk = closed * CFrame.new(0, -part.Size.Y + 0.2, 0)
		local target = if not open then closed elseif offset then closed + offset else sunk
		part.CanCollide = not open or gate:GetAttribute("Solid") == true
		local openTime = gate:GetAttribute("OpenTime") :: number? -- lifts move slowly and evenly so riders stay on
		local info = if openTime
			then TweenInfo.new(openTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			else TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		TweenService:Create(part, info, {
			CFrame = target,
		}):Play()
	end
	if open then
		progress:Fire("GateOpened", gate)
	end
end

local function evaluateGroups()
	local groups: { [string]: boolean } = {}
	for _, tag in TRIGGER_TAGS do
		for _, inst in CollectionService:GetTagged(tag) do
			if inst:IsDescendantOf(workspace) then
				local group = inst:GetAttribute("Group")
				if group then
					groups[group] = (groups[group] ~= false) and isActive(inst)
				end
			end
		end
	end
	for _, gate in CollectionService:GetTagged("DuoGate") do
		local group = gate:GetAttribute("Group")
		if group and groups[group] ~= nil then
			local latch = gate:GetAttribute("Latch") ~= false
			if groups[group] then
				setGateOpen(gate, true)
			elseif not latch then
				setGateOpen(gate, false)
			end
		end
	end
end
InteractableService.Evaluate = evaluateGroups

-- Pressure plates: pressed while a character or a Pullable crate sits on top.
local plateOverlap = OverlapParams.new()
plateOverlap.FilterType = Enum.RaycastFilterType.Exclude

local function platePressed(plate: BasePart): boolean
	plateOverlap.FilterDescendantsInstances = { plate }
	local cf = plate.CFrame * CFrame.new(0, plate.Size.Y / 2 + 1.5, 0)
	for _, part in workspace:GetPartBoundsInBox(cf, Vector3.new(plate.Size.X, 3, plate.Size.Z), plateOverlap) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and Players:GetPlayerFromCharacter(model) then
			local p = Players:GetPlayerFromCharacter(model) :: Player
			if not p:GetAttribute("Downed") then
				return true
			end
		elseif Tags.find(part, "Pullable") or Tags.find(part, "Pasted") then
			return true
		end
	end
	return false
end

-- Is a world position standing on top of this part (within slack)?
local function onTop(part: BasePart, pos: Vector3, slack: number): boolean
	local localPos = part.CFrame:PointToObjectSpace(pos)
	local half = part.Size / 2
	return math.abs(localPos.X) <= half.X + slack
		and math.abs(localPos.Z) <= half.Z + slack
		and localPos.Y >= half.Y - 1
		and localPos.Y <= half.Y + 6
end

local poundTimes: { [Instance]: { [Player]: number } } = {}

local function onGroundPound(p: Player, pos: Vector3)
	if typeof(pos) ~= "Vector3" or p:GetAttribute("Downed") then
		return
	end
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or (root.Position - pos).Magnitude > 12 then
		return
	end
	pounded:Fire(p, pos)

	-- Duo Pound: both players pound within 0.5 s of each other.
	for _, button in CollectionService:GetTagged("DuoPound") do
		if button:IsA("BasePart") and button:IsDescendantOf(workspace) and onTop(button, pos, 2) then
			local times = poundTimes[button] or {}
			poundTimes[button] = times
			times[p] = os.clock()
			local partner = DuoService.PartnerOf(p)
			local other = partner and times[partner]
			if other and math.abs(os.clock() - other) <= Tuning.DuoPoundWindow then
				setActive(button, true)
				evaluateGroups()
			end
		end
	end

	-- Bounce Pad: launches the OTHER player standing on it.
	for _, pad in CollectionService:GetTagged("BouncePad") do
		if pad:IsA("BasePart") and pad:IsDescendantOf(workspace) and onTop(pad, pos, 1) then
			for _, other in DuoService.Players() do
				local otherRoot = other ~= p and other.Character and other.Character:FindFirstChild("HumanoidRootPart")
				if otherRoot and onTop(pad, (otherRoot :: BasePart).Position, 1) then
					launchEvent:FireClient(other, Vector3.new(0, Tuning.BounceLaunchVelocity, 0))
				end
			end
		end
	end

	-- Jump Vent buttons flip their vent's direction.
	for _, button in CollectionService:GetTagged("VentButton") do
		if button:IsA("BasePart") and button:IsDescendantOf(workspace) and onTop(button, pos, 1.5) then
			local link = button:FindFirstChild("Vent") :: ObjectValue?
			local vent = link and link.Value
			if vent then
				vent:SetAttribute("Direction", -((vent:GetAttribute("Direction") or 1) :: number))
				progress:Fire("VentFlipped", vent)
			end
		end
	end

	-- Cracked floors break.
	for _, floor in CollectionService:GetTagged("CrackedFloor") do
		if floor:IsA("BasePart") and floor:IsDescendantOf(workspace) and onTop(floor, pos, 0.5) then
			floor.CanCollide = false
			Audio.play("PoundDebris", floor.Position, 1.5)
			TweenService:Create(floor, TweenInfo.new(0.3), { Transparency = 1 }):Play()
			task.delay(0.35, floor.Destroy, floor)
			progress:Fire("FloorBroken", floor)
		end
	end
end

local function setupLever(lever: Instance)
	local part = if lever:IsA("BasePart") then lever else lever:FindFirstChildWhichIsA("BasePart", true)
	if not part then
		return
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "LeverPrompt"
	prompt.ActionText = "Pull together"
	prompt.ObjectText = "Heavy Lever"
	prompt.HoldDuration = Tuning.HeavyLeverHold
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 10
	prompt.Parent = part

	local pulledAt: { [Player]: number } = {}
	prompt.Triggered:Connect(function(p: Player)
		if isActive(lever) then
			return
		end
		pulledAt[p] = os.clock()
		local partner = DuoService.PartnerOf(p)
		local other = partner and pulledAt[partner]
		if other and os.clock() - other <= Tuning.HeavyLeverWindow then
			setActive(lever, true)
			prompt.Enabled = false
			evaluateGroups()
		else
			lever:SetAttribute("Waiting", p.Name)
		end
	end)
end

function InteractableService.Init()
	poundEvent.OnServerEvent:Connect(onGroundPound)
	Tags.each("HeavyLever", setupLever)
	Tags.each("DuoGate", function(gate)
		gate:SetAttribute("Open", false)
	end)

	task.spawn(function()
		while true do
			task.wait(0.1)
			local changed = false
			for _, plate in CollectionService:GetTagged("PressurePlate") do
				if plate:IsA("BasePart") and plate:IsDescendantOf(workspace) then
					local pressed = platePressed(plate)
					if pressed ~= isActive(plate) then
						setActive(plate, pressed)
						changed = true
					end
				end
			end
			if changed then
				evaluateGroups()
			end
		end
	end)
end

-- Used by tools (e.g. Grapple Line pulling a lever tagged LeverPull).
function InteractableService.Activate(inst: Instance)
	setActive(inst, true)
	evaluateGroups()
end

return InteractableService
