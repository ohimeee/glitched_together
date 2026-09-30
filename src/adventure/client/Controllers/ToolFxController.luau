-- Tool effects every client draws from the server's ToolResult broadcasts (art-direction.md §12: wind-up → effect
-- → impact). Pixel Plains: the Pause Beam fires a blue-white beam from Kai's ray gun, then a shockwave ring and ⏸
-- pixels pop off the target; the Grapple Line shoots a braided rope from Miko's launcher and keeps it taut while
-- she swings or pulls. Purely visual: gameplay never waits on these.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage.Shared.Net)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local ToolFx = require(ReplicatedStorage.Shared.Config.ToolFx)

local T = Tuning.ToolFx
local TEX = ToolFx.Textures
local ICE = ToolFx.Ice
local WHITE = Color3.new(1, 1, 1)

local ToolFxController = {}

local ropes: { [Player]: { Instance } } = {}

local function partOf(target: Instance?): BasePart?
	if not target then
		return nil
	end
	if target:IsA("BasePart") then
		return target
	end
	if target:IsA("Model") then
		return target.PrimaryPart or target:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

-- where the effect leaves the player's hand: the held item's muzzle, else the hand itself
local function muzzleOf(p: Player): Attachment?
	local character = p.Character
	if not character then
		return nil
	end
	local held = character:FindFirstChild("HeldTool")
	local muzzle = held and held:FindFirstChild("Muzzle")
	if muzzle and muzzle:IsA("Attachment") then
		return muzzle
	end
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not hand then
		return nil
	end
	local a = hand:FindFirstChild("FxHand") :: Attachment?
	if not a then
		a = Instance.new("Attachment")
		a.Name = "FxHand"
		a.Parent = hand
	end
	return a
end

-- a temporary attachment on the target, at its center (removed with `life`)
local function pin(part: BasePart, life: number): Attachment
	local a = Instance.new("Attachment")
	a.Name = "FxPin"
	a.Parent = part
	Debris:AddItem(a, life)
	return a
end

local function burst(
	at: Attachment,
	texture: string,
	color: Color3,
	count: number,
	props: {
		size: NumberSequence,
		life: number,
		speed: number,
		spread: number?,
		zOffset: number?,
		flat: boolean?,
	}
)
	local e = Instance.new("ParticleEmitter")
	e.Texture = texture
	e.Color = ColorSequence.new(color)
	e.LightEmission = 0.6
	e.LightInfluence = 0
	e.Size = props.size
	e.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	e.Lifetime = NumberRange.new(props.life * 0.8, props.life)
	e.Speed = NumberRange.new(props.speed * 0.6, props.speed)
	e.SpreadAngle = Vector2.new(props.spread or 180, props.spread or 180)
	e.Rotation = NumberRange.new(0, 0)
	e.Drag = 3
	e.Enabled = false
	e.ZOffset = props.zOffset or 0
	if props.flat then -- a horizontal shockwave lying around the object instead of facing the camera
		e.LightEmission = 0 -- additive rings vanish against the bright Pixel Plains sky
		e.LockedToPart = true -- rides along if the object moves again
		e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		e.EmissionDirection = Enum.NormalId.Top
		e.SpreadAngle = Vector2.zero
		e.Speed = NumberRange.new(0.01)
		e.Drag = 0
	end
	e.Parent = at
	e:Emit(count)
	Debris:AddItem(e, props.life + 0.2)
end

local function grow(size: number): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.15), NumberSequenceKeypoint.new(1, size) })
end

local function shrink(size: number): NumberSequence
	return NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
end

-- Pause Beam ----------------------------------------------------------------------------------------

local function freezeFx(p: Player, target: Instance, released: boolean)
	local part = partOf(target)
	local muzzle = muzzleOf(p)
	if not part then
		return
	end
	local at = pin(part, 1.5)
	-- wider than the object so the ring shows around it (it lies flat, through the object's middle)
	local size = math.clamp(math.max(part.Size.X, part.Size.Z) * 1.7, T.RingSize * 0.6, T.RingSize * 2.5)
	if released then
		-- release: a smaller ring and a puff of pixels, the object snaps back into motion
		burst(at, TEX.FreezeRing, ICE, 1, { size = grow(size * 0.7), life = T.RingTime * 0.8, speed = 0, flat = true })
		burst(at, TEX.PixelSpark, ICE, 8, { size = shrink(0.8), life = 0.5, speed = 14 })
		return
	end
	if muzzle then
		-- wind-up at the lens, then the beam
		burst(muzzle, TEX.PixelSpark, ICE, 6, { size = shrink(0.6), life = 0.25, speed = 6, spread = 40 })
		local beam = Instance.new("Beam")
		beam.Attachment0 = muzzle
		beam.Attachment1 = at
		beam.Texture = TEX.PauseBeam
		beam.TextureMode = Enum.TextureMode.Wrap
		beam.TextureLength = 6
		beam.TextureSpeed = 4
		beam.LightEmission = 0.8
		beam.LightInfluence = 0
		beam.FaceCamera = true
		beam.Color = ColorSequence.new(WHITE, ICE)
		beam.Width0 = 0.5
		beam.Width1 = 1.1
		beam.Parent = at
		local started = os.clock()
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local k = (os.clock() - started) / T.BeamTime
			if k >= 1 or not beam.Parent then
				conn:Disconnect()
				beam:Destroy()
				return
			end
			beam.Transparency = NumberSequence.new(k * k)
			beam.Width0 = 0.5 * (1 - k)
			beam.Width1 = 1.1 * (1 - k * 0.5)
		end)
	end
	-- impact: shockwave ring, ⏸ pixels popping off, a sparkle
	burst(
		at,
		TEX.FreezeRing,
		WHITE,
		1,
		{ size = grow(size), life = T.RingTime, speed = 0, zOffset = part.Size.Magnitude * 0.5 }
	)
	burst(at, TEX.PauseGlyph, WHITE, 5, { size = shrink(2.2), life = 0.7, speed = 10, zOffset = 2 })
	burst(at, TEX.PixelSpark, ICE, 12, { size = shrink(0.7), life = 0.45, speed = 18 })
end

-- Grapple Line --------------------------------------------------------------------------------------

local function clearRope(p: Player)
	for _, inst in ropes[p] or {} do
		inst:Destroy()
	end
	ropes[p] = nil
end

-- A taut rope from the launcher to the target. It shoots out over ~0.1 s (a moving tip) before it locks on.
local function rope(p: Player, target: Instance, life: number?)
	clearRope(p)
	local part = partOf(target)
	local muzzle = muzzleOf(p)
	if not (part and muzzle) then
		return
	end
	local anchor = Instance.new("Attachment")
	anchor.Name = "FxRopeEnd"
	anchor.Parent = part
	local tip = Instance.new("Attachment")
	tip.Name = "FxRopeTip"
	tip.Parent = workspace.Terrain
	local beam = Instance.new("Beam")
	beam.Attachment0 = muzzle
	beam.Attachment1 = tip
	beam.Texture = TEX.Rope
	beam.TextureMode = Enum.TextureMode.Static
	beam.TextureLength = 2
	beam.Width0 = T.RopeWidth
	beam.Width1 = T.RopeWidth
	beam.FaceCamera = true
	beam.LightInfluence = 1
	beam.Segments = 1
	beam.Parent = muzzle
	ropes[p] = { beam, anchor, tip }

	burst(muzzle, TEX.PixelSpark, WHITE, 5, { size = shrink(0.5), life = 0.25, speed = 6, spread = 30 })
	local started = os.clock()
	local SHOOT = 0.1
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not (beam.Parent and anchor.Parent) then
			conn:Disconnect()
			return
		end
		local k = math.min((os.clock() - started) / SHOOT, 1)
		tip.WorldPosition = muzzle.WorldPosition:Lerp(anchor.WorldPosition, k)
		if k >= 1 then
			conn:Disconnect()
			beam.Attachment1 = anchor
			tip:Destroy()
			burst(anchor, TEX.PixelSpark, WHITE, 10, { size = shrink(0.6), life = 0.35, speed = 12 })
		end
	end)
	if life then
		task.delay(life, function()
			if ropes[p] and ropes[p][1] == beam then
				clearRope(p)
			end
		end)
	end
end

-- Copy / Paste ---------------------------------------------------------------------------------------

local function boxOf(inst: Instance): (CFrame?, Vector3?)
	if inst:IsA("BasePart") then
		return inst.CFrame, inst.Size
	elseif inst:IsA("Model") then
		return inst:GetBoundingBox()
	end
	return nil, nil
end

-- Copy: a white scan line sweeps down the object while a thin beam links it to Kai's copier
local function copyScan(p: Player, source: Instance)
	local cf, size = boxOf(source)
	local part = partOf(source)
	if not (cf and size and part) then
		return
	end
	local scan = Instance.new("Part")
	scan.Name = "FxScan"
	scan.Anchored = true
	scan.CanCollide = false
	scan.CanQuery = false
	scan.CanTouch = false
	scan.CastShadow = false
	scan.Material = Enum.Material.Neon
	scan.Color = WHITE
	scan.Transparency = 0.2
	scan.Size = Vector3.new(size.X + 0.6, 0.15, size.Z + 0.6)
	scan.Parent = workspace
	local outline = Instance.new("Highlight")
	outline.FillColor = WHITE
	outline.OutlineColor = WHITE
	outline.FillTransparency = 0.7
	outline.Adornee = source
	outline.Parent = scan
	local at = pin(part, T.ScanTime + 0.2)
	local muzzle = muzzleOf(p)
	if muzzle then
		local beam = Instance.new("Beam")
		beam.Attachment0 = muzzle
		beam.Attachment1 = at
		beam.Texture = TEX.PauseBeam
		beam.LightEmission = 0.8
		beam.LightInfluence = 0
		beam.FaceCamera = true
		beam.Width0 = 0.15
		beam.Width1 = 0.6
		beam.Color = ColorSequence.new(WHITE)
		beam.Parent = scan
	end
	local started = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local k = (os.clock() - started) / T.ScanTime
		if k >= 1 then
			conn:Disconnect()
			scan:Destroy()
			burst(at, TEX.PixelSpark, WHITE, 10, { size = shrink(0.6), life = 0.4, speed = 10 })
			return
		end
		scan.CFrame = cf * CFrame.new(0, size.Y * (0.5 - k), 0)
		outline.FillTransparency = 0.7 + 0.3 * k
	end)
end

-- Paste: the ghost outline snaps solid with a ring and sparks at its base
local function pasteSnap(paste: Instance)
	local cf, size = boxOf(paste)
	local part = partOf(paste)
	if not (cf and size and part) then
		return
	end
	local hl = Instance.new("Highlight")
	hl.Name = "FxPasteSnap"
	hl.FillColor = WHITE
	hl.OutlineColor = WHITE
	hl.FillTransparency = 0
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Parent = paste
	TweenService:Create(
		hl,
		TweenInfo.new(T.PasteSnapTime, Enum.EasingStyle.Quad),
		{ FillTransparency = 1, OutlineTransparency = 1 }
	):Play()
	Debris:AddItem(hl, T.PasteSnapTime + 0.1)
	local base = Instance.new("Attachment")
	base.Parent = part
	base.WorldPosition = cf.Position - Vector3.new(0, size.Y / 2 - 0.2, 0)
	Debris:AddItem(base, 1)
	burst(base, TEX.FreezeRing, WHITE, 1, {
		size = grow(math.max(size.X, size.Z) * 1.6),
		life = T.RingTime,
		speed = 0,
		flat = true,
	})
	burst(base, TEX.PixelSpark, WHITE, 14, { size = shrink(0.7), life = 0.45, speed = 14 })
end

-- Frozen objects keep shedding a few ⏸ pixels while the pause holds -----------------------------------

local function frozenGlow(inst: Instance, part: BasePart)
	local function refresh()
		local frozen = inst:GetAttribute("Frozen") == true
		local e = part:FindFirstChild("FxFrozenGlyphs") :: ParticleEmitter?
		if frozen and not e then
			local emitter = Instance.new("ParticleEmitter")
			emitter.Name = "FxFrozenGlyphs"
			emitter.Texture = TEX.PauseGlyph
			emitter.Color = ColorSequence.new(WHITE)
			emitter.LightEmission = 0.4
			emitter.LightInfluence = 0
			emitter.Size = shrink(0.9)
			emitter.Transparency = NumberSequence.new(0.2, 1)
			emitter.Lifetime = NumberRange.new(0.8, 1.2)
			emitter.Speed = NumberRange.new(1.5, 3)
			emitter.SpreadAngle = Vector2.new(60, 60)
			emitter.EmissionDirection = Enum.NormalId.Top
			emitter.Shape = Enum.ParticleEmitterShape.Box
			emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
			emitter.Rate = math.clamp(part.Size.Magnitude * 0.3, 2, 8)
			emitter.Parent = part
		elseif not frozen and e then
			e:Destroy()
		end
	end
	inst:GetAttributeChangedSignal("Frozen"):Connect(refresh)
	refresh()
end

function ToolFxController.Init()
	local toolResult = Net.event("ToolResult")
	toolResult.OnClientEvent:Connect(function(kind: string, p: Player?, target: Instance?)
		if typeof(p) ~= "Instance" or not p:IsA("Player") then
			return
		end
		if kind == "Froze" and target then
			freezeFx(p, target, false)
		elseif kind == "Released" and target then
			freezeFx(p, target, true)
		elseif kind == "GrappleStart" and target then
			rope(p, target)
		elseif kind == "GrappleEnd" then
			clearRope(p)
		elseif kind == "PullStart" and target then
			rope(p, target, Tuning.GrappleLine.PullTime + 0.1)
		elseif kind == "CopyScan" and target then
			copyScan(p, target)
		elseif kind == "Pasted" and target then
			pasteSnap(target)
		end
	end)

	local CollectionService = game:GetService("CollectionService")
	local function watch(inst: Instance)
		local part = partOf(inst)
		if part then
			frozenGlow(inst, part)
		end
	end
	for _, inst in CollectionService:GetTagged("Freezable") do
		watch(inst)
	end
	CollectionService:GetInstanceAddedSignal("Freezable"):Connect(watch)

	game:GetService("Players").PlayerRemoving:Connect(clearRope)
end

return ToolFxController
