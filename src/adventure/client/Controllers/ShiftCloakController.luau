-- Layer Shift seen from the real world (user request, Oct 1): when Miko shifts into the Code Layer she leaves the
-- real world, so everyone else stops seeing her. A teal scan line sweeps up her body and hides it part by part,
-- with a few glitch flickers at the line and teal pixels shedding off it; only a faint teal outline stays. Shifting
-- back plays it in reverse (the line sweeps down and rebuilds her). Runs on every client except her own: the
-- `Shifted` attribute replicates. Her own view is CodeLayerController's job.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local ToolFx = require(ReplicatedStorage.Shared.Config.ToolFx)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)

local player = Players.LocalPlayer
local T = Tuning.ToolFx

local ShiftCloakController = {}

local rng = Random.new()
-- per player: whether they're hidden now, and a token so a new animation cancels the running one
local hidden: { [Player]: boolean } = {}
local token: { [Player]: number } = {}

local function isShifted(p: Player): boolean
	return p:GetAttribute("Shifted") == true
end

-- Everything that draws on the character: body parts, accessories, held items, the face decal.
local function visuals(character: Model): { BasePart | Decal }
	local list = {}
	for _, d in character:GetDescendants() do
		if d:IsA("BasePart") or d:IsA("Decal") then
			table.insert(list, d)
		end
	end
	return list
end

local function heightOf(v: BasePart | Decal): number?
	if v:IsA("BasePart") then
		return v.Position.Y
	end
	local parent = v.Parent
	return if parent and parent:IsA("BasePart") then parent.Position.Y else nil
end

-- The faint hint left behind: the role outline (PartnerController) fades instead of vanishing, the name tag goes.
local function setHint(character: Model, on: boolean)
	local outline = character:FindFirstChild("RoleOutline") :: Highlight?
	if outline then
		outline.OutlineTransparency = if on then T.CloakOutline else 0
	end
	local head = character:FindFirstChild("Head")
	local tag = head and head:FindFirstChild("RoleTag") :: BillboardGui?
	if tag then
		tag.Enabled = not on
	end
end

local function setAll(character: Model, hide: boolean)
	for _, v in visuals(character) do
		v.LocalTransparencyModifier = if hide then 1 else 0
	end
	setHint(character, hide)
end

local function makeRing(): Part
	local ring = Instance.new("Part")
	ring.Name = "ShiftCloakRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Material = Enum.Material.Neon
	ring.Color = Palette.Glow.Miko
	ring.Size = Vector3.new(0.12, T.CloakRingSize, T.CloakRingSize)
	ring.Transparency = 0.25
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.CastShadow = false
	local pixels = Instance.new("ParticleEmitter")
	pixels.Texture = ToolFx.Textures.PixelSpark
	pixels.Color = ColorSequence.new(Palette.Miko)
	pixels.LightEmission = 0.8
	pixels.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	pixels.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	pixels.Lifetime = NumberRange.new(0.4, 0.8)
	pixels.Speed = NumberRange.new(2, 5)
	pixels.SpreadAngle = Vector2.new(180, 180)
	pixels.Drag = 3
	pixels.Rotation = NumberRange.new(0, 0) -- pixels stay square-on
	pixels.Rate = 0
	pixels.Parent = ring
	return ring
end

-- hide = true: the line sweeps up and hides everything below it. hide = false: it sweeps down and shows
-- everything above it (the same animation played backwards).
local function play(p: Player, hide: boolean)
	local character = p.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (character and root) then
		return
	end
	hidden[p] = hide
	token[p] = (token[p] or 0) + 1
	local mine = token[p]
	local parts = visuals(character)
	local lo, hi = math.huge, -math.huge
	for _, v in parts do
		local y = heightOf(v)
		if y then
			lo, hi = math.min(lo, y - root.Position.Y), math.max(hi, y - root.Position.Y)
		end
	end
	lo, hi = lo - 0.6, hi + 0.6
	if not hide then
		setHint(character, false)
	end
	Audio.play(if hide then "ShiftOut" else "ShiftIn", root)

	local ring = makeRing()
	ring.Parent = workspace
	local pixels = ring:FindFirstChildOfClass("ParticleEmitter") :: ParticleEmitter
	pixels.Acceleration = Vector3.new(0, if hide then 6 else -6, 0)
	local start = os.clock()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local alive = token[p] == mine and character.Parent and root.Parent
		local t = math.clamp((os.clock() - start) / T.CloakTime, 0, 1)
		if not alive or t >= 1 then
			conn:Disconnect()
			ring:Destroy()
			if alive then
				setAll(character, hide)
			end
			return
		end
		local eased = t * t * (3 - 2 * t)
		local rel = if hide then lo + (hi - lo) * eased else hi - (hi - lo) * eased
		local lineY = root.Position.Y + rel
		for _, v in parts do
			local y = heightOf(v)
			if not y then
				continue
			end
			local gone = if hide then y < lineY else y <= lineY
			-- glitch flicker: parts right at the line stutter between shown and hidden
			if math.abs(y - lineY) < T.CloakFlickerBand and rng:NextNumber() < 0.5 then
				gone = not gone
			end
			v.LocalTransparencyModifier = if gone then 1 else 0
		end
		local pos = root.Position
		ring.CFrame = CFrame.new(pos.X + rng:NextNumber(-0.06, 0.06), lineY, pos.Z) * CFrame.Angles(0, 0, math.pi / 2)
		ring.Transparency = 0.25 + 0.6 * math.abs(t * 2 - 1) ^ 3 -- fades in and out at the ends
		pixels:Emit(T.CloakPixels)
	end)
end

local function watch(p: Player)
	if p == player then
		return
	end
	p:GetAttributeChangedSignal("Shifted"):Connect(function()
		local now = isShifted(p)
		if hidden[p] ~= now then
			play(p, now)
		end
	end)
	local function onCharacter(character: Model)
		hidden[p] = isShifted(p)
		token[p] = (token[p] or 0) + 1
		character:WaitForChild("HumanoidRootPart", 5)
		setAll(character, hidden[p] == true)
		-- parts added later (held items, accessories, the outline) follow the current state
		character.DescendantAdded:Connect(function(d)
			if hidden[p] and (d:IsA("BasePart") or d:IsA("Decal")) then
				d.LocalTransparencyModifier = 1
			elseif hidden[p] and (d.Name == "RoleOutline" or d.Name == "RoleTag") then
				task.defer(setHint, character, true)
			end
		end)
	end
	if p.Character then
		task.spawn(onCharacter, p.Character)
	end
	p.CharacterAdded:Connect(onCharacter)
end

function ShiftCloakController.Init()
	for _, p in Players:GetPlayers() do
		watch(p)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(function(p)
		hidden[p] = nil
		token[p] = nil
	end)
end

-- Is this player shifted out of the real world (hidden from this client)?
function ShiftCloakController.Hidden(p: Player): boolean
	return hidden[p] == true
end

return ShiftCloakController
