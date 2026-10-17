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
local CombatFx = require(script.Parent.CombatFx)

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
	elseif active or Tags.has(inst, "LeverPull") then
		Audio.play("Lever", at, if active then 1 else 0.8)
	end
	if inst:IsA("BasePart") and not Tags.has(inst, "LeverPull") then
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

-- Someone standing on (or just above) any part of this gate?
local function ridden(gate: Instance): boolean
	for _, part in partsOf(gate) do
		for _, p in Players:GetPlayers() do
			local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local lp = part.CFrame:PointToObjectSpace(root.Position)
				local h = part.Size / 2
				if math.abs(lp.X) <= h.X + 1 and math.abs(lp.Z) <= h.Z + 1 and lp.Y >= h.Y - 1 and lp.Y <= h.Y + 8 then
					return true
				end
			end
		end
	end
	return false
end

local function setGateOpen(gate: Instance, open: boolean)
	if (gate:GetAttribute("Open") == true) == open then
		return
	end
	-- a lift or bridge never drops out from under someone: it waits until they step off (playtest Oct 1)
	if not open and gate:GetAttribute("OpenOffset") and ridden(gate) then
		task.delay(0.5, function()
			InteractableService.Evaluate()
		end)
		return
	end
	gate:SetAttribute("Open", open)
	local parts = partsOf(gate)
	-- castle portcullis (ArtService marks it): a clank and a shudder, then it grinds down into the floor with the
	-- winch and chains, dust puffing at its foot (2P playtest Oct 11: "door animation + sound")
	local portcullis = gate:GetAttribute("Portcullis") == true
	if parts[1] then
		if portcullis then
			Audio.play("PortcullisRattle", parts[1])
			Audio.play("PortcullisOpen", parts[1])
		else
			Audio.play("GateMove", parts[1])
		end
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
		if portcullis then
			local P = Tuning.Portcullis
			info = TweenInfo.new(P.Move, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
			local shudder = TweenService:Create(
				part,
				TweenInfo.new(P.Shudder / 4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 1, true),
				{ CFrame = part.CFrame * CFrame.new(0, P.ShudderLift, 0) }
			)
			shudder:Play()
			local foot = (closed * CFrame.new(0, -part.Size.Y / 2, 0)).Position
			CombatFx.Burst(foot, { { "Smoke", 10, 2.2, Color3.fromRGB(150, 136, 124) } })
			task.delay(P.Shudder, function()
				TweenService:Create(part, info, { CFrame = target }):Play()
			end)
		else
			TweenService:Create(part, info, {
				CFrame = target,
			}):Play()
		end
		-- `HideClosed`: a bridge waiting far below is invisible until it rises, so it never reads as a platform down
		-- there (Memory Lane); it fades out again as it sinks
		if gate:GetAttribute("HideClosed") then
			if part:GetAttribute("ShownTransparency") == nil then
				part:SetAttribute("ShownTransparency", part.Transparency)
			end
			local shown = part:GetAttribute("ShownTransparency") :: number
			TweenService:Create(part, TweenInfo.new(if open then 0.3 else info.Time), {
				Transparency = if open then shown else 1,
			}):Play()
			for _, gui in part:GetChildren() do
				if gui:IsA("SurfaceGui") then
					gui.Enabled = open
				end
			end
		end
	end
	if open then
		progress:Fire("GateOpened", gate)
	end
end

-- Switch blocks (obstacles.md "Switch Blocks"): retro ON/OFF blocks. `Phase = true` blocks are solid while their
-- Group is active (the lever thrown), `Phase = false` blocks while it isn't; the other set is a see-through ghost.
local function setSwitchBlock(block: BasePart, solid: boolean)
	if block:GetAttribute("SwitchSolid") == solid then
		return
	end
	block:SetAttribute("SwitchSolid", solid)
	block.CanCollide = solid
	local look = if solid then 0 else Tuning.SwitchGhost
	if block:GetAttribute("Skinned") then -- the art shell ghosts instead; the grey-box part stays hidden
		for _, shell in block:GetChildren() do
			if shell:IsA("MeshPart") then
				shell.Transparency = look
			end
		end
	else
		block.Transparency = look
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
	for _, block in CollectionService:GetTagged("SwitchBlock") do
		local group = block:GetAttribute("Group")
		if block:IsA("BasePart") and group then
			setSwitchBlock(block, (block:GetAttribute("Phase") == true) == (groups[group] == true))
		end
	end
	for _, gate in CollectionService:GetTagged("DuoGate") do
		-- `AnyOf` ("A,B"): the gate opens while ANY of those groups is active (two ways to hold one door)
		local anyOf = gate:GetAttribute("AnyOf")
		if type(anyOf) == "string" then
			local known, active = false, false
			for _, g in string.split(anyOf, ",") do
				if groups[g] ~= nil then
					known = true
					active = active or groups[g]
				end
			end
			if known then
				if active then
					setGateOpen(gate, true)
				elseif gate:GetAttribute("Latch") == false then
					setGateOpen(gate, false)
				end
			end
			continue
		end
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

-- `PastedOnly` plates (Glitched Core sockets) only count Kai's pastes, not players or crates.
-- `PlayersOnly` plates ignore crates and pastes (a door you have to hold yourself). `HeavyOnly` plates (steel rim,
-- Pixel Plains crate puzzles) only feel a crate or a paste: a player standing on one isn't heavy enough (user, Oct 17). A plate still in the Code Layer
-- isn't there for anyone until Miko pulls it out.
local function platePressed(plate: BasePart): boolean
	if Tags.has(plate, "CodeLayer") and not plate:GetAttribute("PulledOut") then
		return false
	end
	plateOverlap.FilterDescendantsInstances = { plate }
	local cf = plate.CFrame * CFrame.new(0, plate.Size.Y / 2 + 1.5, 0)
	local pastedOnly = plate:GetAttribute("PastedOnly") == true
	local playersOnly = plate:GetAttribute("PlayersOnly") == true
	local heavyOnly = plate:GetAttribute("HeavyOnly") == true
	for _, part in workspace:GetPartBoundsInBox(cf, Vector3.new(plate.Size.X, 3, plate.Size.Z), plateOverlap) do
		local model = part:FindFirstAncestorOfClass("Model")
		if pastedOnly then
			if Tags.find(part, "Pasted") then
				return true
			end
		elseif heavyOnly then
			-- the crate has to sit on it: its middle over the plate, not a corner leaning on the edge
			local heavy = Tags.find(part, "Pullable") or Tags.find(part, "Pasted")
			local at = if heavy then plate.CFrame:PointToObjectSpace(Tags.position(heavy)) else nil
			if at and math.abs(at.X) <= plate.Size.X / 2 + 0.5 and math.abs(at.Z) <= plate.Size.Z / 2 + 0.5 then
				return true
			end
		elseif model and Players:GetPlayerFromCharacter(model) then
			local p = Players:GetPlayerFromCharacter(model) :: Player
			if not p:GetAttribute("Downed") then
				return true
			end
		elseif not playersOnly and (Tags.find(part, "Pullable") or Tags.find(part, "Pasted")) then
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

-- A pounded pad visibly reacts (user, Oct 17: "it must show that the pad springed"): the part's skin + inlay (its
-- anchored children) run through `steps` = { {y offset, seconds, easing?} } and settle home. The collider stays put.
local function bump(part: BasePart, steps: { { any } })
	if part:GetAttribute("Bumping") then
		return
	end
	local pieces: { [BasePart]: CFrame } = {}
	for _, d in part:GetDescendants() do
		if d:IsA("BasePart") and d.Anchored then
			pieces[d] = d.CFrame
		end
	end
	part:SetAttribute("Bumping", true)
	task.spawn(function()
		for _, step in steps do
			local info = TweenInfo.new(step[2], step[3] or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			for piece, home in pieces do
				if piece.Parent then
					TweenService:Create(piece, info, { CFrame = home + Vector3.new(0, step[1], 0) }):Play()
				end
			end
			task.wait(step[2])
		end
		for piece, home in pieces do
			piece.CFrame = home
		end
		part:SetAttribute("Bumping", nil)
	end)
end

local SPRING = { { -0.4, 0.06 }, { 0.9, 0.09 }, { 0, 0.4, Enum.EasingStyle.Bounce } } -- squash, spring, wobble home
local PRESS = { { -0.35, 0.07 }, { 0, 0.25, Enum.EasingStyle.Back } } -- push button: in, then back out

local poundTimes: { [Instance]: { [Player]: number } } = {}
-- Warp pipes (obstacles.md "Warp Pipe Swap"): two `WarpPipe` parts with the same Group, one each side of a wall;
-- both players ground-pound their own pipe within DuoPoundWindow and they swap places.
local warpPounds: { [string]: { [Player]: { at: number, pipe: BasePart } } } = {}

local function warpTo(p: Player, pipe: BasePart)
	local character = p.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (character and root) then
		return
	end
	local cf = pipe.CFrame * CFrame.new(0, pipe.Size.Y / 2 + 3.5, 0)
	pcall(function()
		p:RequestStreamAroundAsync(cf.Position, 2)
	end)
	character:PivotTo(CFrame.new(cf.Position) * root.CFrame.Rotation)
	root.AssemblyLinearVelocity = Vector3.zero
	Audio.play("Teleport", pipe)
end

local function onGroundPound(p: Player, pos: Vector3)
	if typeof(pos) ~= "Vector3" or p:GetAttribute("Downed") then
		return
	end
	local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	-- the server's copy of the character trails a 110 studs/s pound fall, so it can still be well up in the air when
	-- the landing arrives (a flat 12-stud check threw away high pounds: user, Oct 17 "the item doesn't activate")
	if not root then
		return
	end
	local offset = root.Position - pos
	if Vector3.new(offset.X, 0, offset.Z).Magnitude > 12 or offset.Y < -6 or offset.Y > 60 then
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

	for _, pipe in CollectionService:GetTagged("WarpPipe") do
		local group = pipe:GetAttribute("Group")
		if pipe:IsA("BasePart") and pipe:IsDescendantOf(workspace) and group and onTop(pipe, pos, 2) then
			local pounds = warpPounds[group] or {}
			warpPounds[group] = pounds
			pounds[p] = { at = os.clock(), pipe = pipe }
			local partner = DuoService.PartnerOf(p)
			local other = partner and pounds[partner]
			if
				partner
				and other
				and other.pipe ~= pipe
				and math.abs(os.clock() - other.at) <= Tuning.DuoPoundWindow
			then
				table.clear(pounds)
				warpTo(p, other.pipe)
				warpTo(partner, pipe)
				progress:Fire("Warped", pipe)
			end
		end
	end

	-- Bounce Pad: launches the OTHER player standing on it.
	for _, pad in CollectionService:GetTagged("BouncePad") do
		if pad:IsA("BasePart") and pad:IsDescendantOf(workspace) and onTop(pad, pos, 1) then
			bump(pad, SPRING)
			Audio.play("BouncePad", pad, 0.8)
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
				local dir = -((vent:GetAttribute("Direction") or 1) :: number)
				vent:SetAttribute("Direction", dir)
				button:SetAttribute("Active", dir > 0) -- its inlay: green while the fan blows up
				bump(button, PRESS)
				Audio.play("PlateDown", button)
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
	Tags.each("SwitchBlock", function(block)
		if block:IsA("BasePart") then -- levers start off: the Phase = false set starts solid
			setSwitchBlock(block, block:GetAttribute("Phase") ~= true)
		end
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

-- Light a trigger for `seconds`, then let it go dark again (castle crystals with a Window).
function InteractableService.Pulse(inst: Instance, seconds: number)
	local stamp = os.clock()
	inst:SetAttribute("PulsedAt", stamp)
	setActive(inst, true)
	evaluateGroups()
	task.delay(seconds, function()
		if inst:GetAttribute("PulsedAt") == stamp then
			setActive(inst, false)
			evaluateGroups()
		end
	end)
end

-- A pulled lever throws over on its base: rest angle ↔ thrown angle (Tuning.LeverThrow), a quick springy swing.
local function swingLever(lever: BasePart, on: boolean)
	local rest = lever:GetAttribute("RestCFrame") :: CFrame?
	if not rest then
		rest = lever.CFrame
		lever:SetAttribute("RestCFrame", rest)
	end
	local half = lever.Size.Y / 2
	local pivot = (rest :: CFrame) * CFrame.new(0, -half, 0) -- the foot of the lever
	local angle = Instance.new("NumberValue")
	angle.Value = if on then 0 else -math.rad(Tuning.LeverThrow)
	angle.Changed:Connect(function(a: number)
		if lever.Parent then
			lever.CFrame = pivot * CFrame.Angles(a, 0, 0) * CFrame.new(0, half, 0)
		end
	end)
	local tween = TweenService:Create(
		angle,
		TweenInfo.new(Tuning.LeverSwingTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Value = if on then -math.rad(Tuning.LeverThrow) else 0 }
	)
	tween.Completed:Once(function()
		angle:Destroy()
	end)
	tween:Play()
end

-- Pull levers toggle: pull to throw it (on), pull again to throw it back (off). Gates in its group that don't
-- latch (lever lifts and bridges) follow it back down.
function InteractableService.Toggle(inst: Instance)
	local on = not isActive(inst)
	setActive(inst, on)
	if inst:IsA("BasePart") then
		swingLever(inst, on)
	end
	evaluateGroups()
end

return InteractableService
