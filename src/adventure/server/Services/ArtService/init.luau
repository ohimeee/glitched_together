-- Blender art on top of the grey-box worlds (BLENDER_PLAYBOOK.md §6, art-direction.md).
-- Skins: a grey-box part keeps its collision, tags and SurfaceGuis but turns invisible; non-colliding MeshParts
--        scaled to part.Size / Design sit in its place (welded + massless when the part moves). Gameplay never
--        depends on the art loading. Per-world data: child modules returning { Skins, Dressing, Decor }.
-- Decor: meshes placed with a world that have no gameplay part (clouds, coin blocks).
-- Pip:   a model template published to ReplicatedStorage.PipModel for the client PipController.
-- Badges: Kai's ▲ / Miko's ● back badge, given to each character as an Accessory.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local ToolFx = require(ReplicatedStorage.Shared.Config.ToolFx)
local PipMeshes = require(script.Pip)
local Badges = require(script.Badges)

type WorldArt = {
	Skins: { [string]: MeshAssets.Skin },
	Dressing: { [string]: string },
	Decor: { { any } },
	Extras: ((world: Instance, apply: (BasePart, string) -> boolean) -> ())?, -- runs once skins + decor are in
}

local Worlds: { [string]: WorldArt } = {
	Prologue = require(script.Prologue),
	PixelPlains = require(script.PixelPlains),
	StarfallCastle = require(script.StarfallCastle),
	GlitchedCore = require(script.GlitchedCore),
	Epilogue = require(script.Epilogue),
}

local StateInlay = require(script.StateInlay)
local VentFan = require(script.VentFan)
local LeverSupports = require(script.LeverSupports)
local Rails = require(script.Rails)

-- Pieces every world shares (Oct 2): realism-first generations (generate_mesh)
local SHARED: { [string]: MeshAssets.Skin } = {
	ExitArch = { -- weathered marble arch with brass stars around each world's exit portal
		Design = Vector3.new(11.39, 12.27, 4),
		Meshes = {
			Body = {
				Id = "rbxassetid://128798624249939",
				TextureId = "rbxassetid://137527623890235",
				Offset = Vector3.zero,
				Size = Vector3.new(11.39, 12.27, 4),
				Material = Enum.Material.SmoothPlastic,
			},
		},
	},
	DuoButton = { -- a big white two-hands push button in a steel box (white = both players)
		Design = Vector3.new(12, 1, 8),
		Meshes = {
			Body = {
				Id = "rbxassetid://136391215703584",
				TextureId = "rbxassetid://90355549126238",
				Offset = Vector3.new(0, 0.1, 0),
				Size = Vector3.new(12, 1.6, 8),
				Material = Enum.Material.SmoothPlastic,
			},
		},
	},
	HeavyLeverSkin = { -- a steel lever with a white grip on a bolted iron base
		Design = Vector3.new(1, 5, 1),
		Meshes = {
			Body = {
				Id = "rbxassetid://100071213028508",
				TextureId = "rbxassetid://116749620177938",
				Offset = Vector3.zero,
				Size = Vector3.new(2.6, 5, 2.6),
				Material = Enum.Material.SmoothPlastic,
			},
		},
	},
	-- grind rail stanchion (tools/piece_kit/kit.py, PieceKit.fbx): saddle clamp, pole (stretched), flange plate.
	-- Rails.luau stacks them over a box-truss pylon and tints the steel per world
	RailClamp = {
		Design = Vector3.new(1.55, 1.11, 0.92),
		Meshes = {
			Steel = {
				Id = "rbxassetid://132967066000423",
				Offset = Vector3.new(-0.01, -0.055, 0),
				Size = Vector3.new(1.38, 1, 0.92),
				Material = Enum.Material.Metal,
			},
			Bolt = {
				Id = "rbxassetid://85537550491701",
				Offset = Vector3.new(0, 0.445, 0),
				Size = Vector3.new(1.55, 0.22, 0.5),
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(90, 92, 98),
			},
		},
	},
	-- Pixel Plains voxel mine track (PieceKitPP.fbx): 4-stud track piece (two square iron rails, tops level with the
	-- grind collider's top, on oak sleepers), a 6-stud trestle piece (stacked voxel log legs + plank ties), its cap beam
	PPTrack = {
		Design = Vector3.new(3, 0.82, 4),
		Meshes = {
			Iron = {
				Id = "rbxassetid://76664065252292",
				Offset = Vector3.new(0, 0.21, 0),
				Size = Vector3.new(2.1, 0.4, 4),
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(72, 74, 82),
			},
			Plank = {
				Id = "rbxassetid://104108864430782",
				Offset = Vector3.new(0, -0.19, 0),
				Size = Vector3.new(3, 0.44, 2.8),
				Material = Enum.Material.SmoothPlastic,
				Variant = "PixelPlastic",
				Color = Color3.fromRGB(176, 128, 80),
			},
		},
	},
	-- v2 after the user's It Takes Two refs (PieceKitPP2.fbx): one iron rail on a wooden ladder (stringers + rungs),
	-- a chain (4 studs, tiled), and a side arm (beam + knee brace + hook) that hangs a rail piece off a tower
	PPTrack2 = {
		Design = Vector3.new(2.44, 1.175, 4),
		Meshes = {
			Iron = {
				Id = "rbxassetid://113848660521582",
				Offset = Vector3.new(0, 0.3325, 0),
				Size = Vector3.new(0.8, 0.51, 4),
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(72, 74, 82),
			},
			Plank = {
				Id = "rbxassetid://81061613901671",
				Offset = Vector3.new(0, -0.0675, 0),
				Size = Vector3.new(2.4, 0.3, 3.21),
				Material = Enum.Material.SmoothPlastic,
				Variant = "PixelPlastic",
				Color = Color3.fromRGB(176, 128, 80),
			},
			Log = {
				Id = "rbxassetid://85435764289027",
				Offset = Vector3.new(0, -0.3375, 0),
				Size = Vector3.new(2.44, 0.5, 4),
				Material = Enum.Material.SmoothPlastic,
				Variant = "PixelPlastic",
				Color = Color3.fromRGB(107, 74, 43),
			},
		},
	},
	PPChain = {
		Design = Vector3.new(0.35, 3.95, 0.35),
		Meshes = {
			Iron = {
				Id = "rbxassetid://133977897771817",
				Offset = Vector3.zero,
				Size = Vector3.new(0.35, 3.95, 0.35),
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(72, 74, 82),
			},
		},
	},
	PPArm = { -- root at local +X end (x 2.8), hook under the -X tip (x -2.3, 0.9 below the beam centre)
		Design = Vector3.new(5.6, 3.12, 1),
		Meshes = {
			Log = {
				Id = "rbxassetid://91279585092876",
				Offset = Vector3.new(0, 1.11, 0),
				Size = Vector3.new(5.6, 0.9, 1),
				Material = Enum.Material.SmoothPlastic,
				Variant = "PixelPlastic",
				Color = Color3.fromRGB(107, 74, 43),
			},
			Plank = {
				Id = "rbxassetid://81926937182953",
				Offset = Vector3.new(1, -0.19, 0),
				Size = Vector3.new(3.28, 2.74, 0.5),
				Material = Enum.Material.SmoothPlastic,
				Variant = "PixelPlastic",
				Color = Color3.fromRGB(176, 128, 80),
			},
			Iron = {
				Id = "rbxassetid://114792282640277",
				Offset = Vector3.new(-2.3, 0.45, 0),
				Size = Vector3.new(0.5, 0.47, 0.5),
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(72, 74, 82),
			},
		},
	},
	PPTrestle = {
		Design = Vector3.new(4.4, 6, 1.8),
		Meshes = {
			Log = {
				Id = "rbxassetid://98085318436899",
				Offset = Vector3.zero,
				Size = Vector3.new(4.4, 5.98, 1.2),
				Material = Enum.Material.SmoothPlastic,
				Variant = "PixelPlastic",
				Color = Color3.fromRGB(107, 74, 43),
			},
			Plank = {
				Id = "rbxassetid://73018591774373",
				Offset = Vector3.new(0, -0.4, 0),
				Size = Vector3.new(4.4, 2.6, 1.8),
				Material = Enum.Material.SmoothPlastic,
				Variant = "PixelPlastic",
				Color = Color3.fromRGB(176, 128, 80),
			},
		},
	},
	PPTrestleCap = {
		Design = Vector3.new(5, 0.9, 1.3),
		Meshes = {
			Plank = {
				Id = "rbxassetid://75915912958974",
				Offset = Vector3.zero,
				Size = Vector3.new(5, 0.9, 1.3),
				Material = Enum.Material.SmoothPlastic,
				Variant = "PixelPlastic",
				Color = Color3.fromRGB(176, 128, 80),
			},
		},
	},
	RailPole = {
		Design = Vector3.new(0.76, 1, 0.76),
		Meshes = {
			Steel = {
				Id = "rbxassetid://104308332982927",
				Offset = Vector3.zero,
				Size = Vector3.new(0.76, 1, 0.76),
				Material = Enum.Material.Metal,
			},
		},
	},
	RailBase = {
		Design = Vector3.new(2.17, 0.8, 2.17),
		Meshes = {
			Steel = {
				Id = "rbxassetid://114860702714975",
				Offset = Vector3.zero,
				Size = Vector3.new(2.17, 0.8, 2.17),
				Material = Enum.Material.Metal,
			},
			Bolt = {
				Id = "rbxassetid://85284635354607",
				Offset = Vector3.new(0, -0.03, 0),
				Size = Vector3.new(1.33, 0.14, 1.36),
				Material = Enum.Material.Metal,
				Color = Color3.fromRGB(90, 92, 98),
			},
		},
	},
}

local Skins: { [string]: MeshAssets.Skin } = table.clone(SHARED)
for _, art in Worlds do
	for name, skin in art.Skins do
		Skins[name] = skin
	end
end

local ArtService = {}

local loaded: { [string]: { [string]: MeshPart } | false } = {} -- skin name → templates, false = failed / not imported
local inflight: { [string]: boolean } = {} -- skins being downloaded right now (a second caller waits for the first)

local function templatesFor(skinName: string): { [string]: MeshPart }?
	while inflight[skinName] do
		task.wait()
	end
	local cached = loaded[skinName]
	if cached == nil then
		inflight[skinName] = true
		cached = MeshAssets.Load(Skins[skinName].Meshes, skinName) or false
		loaded[skinName] = cached
		inflight[skinName] = nil
	end
	return if cached then cached else nil
end

local function moves(part: BasePart): boolean
	return not part.Anchored
		or CollectionService:HasTag(part, "Mover")
		or CollectionService:HasTag(part, "Pullable")
		or CollectionService:HasTag(part, "Freezable") -- e.g. coin steps sink by CFrame
		or CollectionService:HasTag(part, "Copyable") -- pastes are clones moved by CFrame
		or CollectionService:HasTag(part, "Enemy") -- CombatService moves enemies by CFrame
		or CollectionService:HasTag(part, "Station") -- StationService turns cranks by CFrame
		or CollectionService:HasTag(part, "DuoGate") -- InteractableService tweens gates and lifts
		or CollectionService:HasTag(part, "Crumble") -- boss floor tiles shake and fall
		or part:GetAttribute("Weld") == true -- anything else a script moves later (the Crusher King's body)
end

-- Puts a skin over one grey-box part. Returns false (part untouched) if the meshes aren't available.
function ArtService.Apply(part: BasePart, skinName: string): boolean
	local skin = Skins[skinName]
	if skin and skin.Build then
		if not part.Parent then
			return false
		end
		skin.Build(part, moves(part))
		part:SetAttribute("Skinned", skinName)
		return true
	end
	local templates = skin and templatesFor(skinName)
	if not (skin and templates) or not part.Parent then
		return false
	end
	local k = part.Size / skin.Design
	local weld = moves(part)
	for name, info in skin.Meshes do
		local p = templates[name]:Clone()
		p.Size = info.Size * k
		p.CFrame = part.CFrame * CFrame.new(info.Offset * k) * CFrame.Angles(0, math.rad(info.Yaw or 0), 0)
		if weld then
			p.Anchored = false
			p.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0 = part
			w.Part1 = p
			w.Parent = p
		end
		p.Parent = part
	end
	part.Transparency = 1
	part:SetAttribute("Skinned", skinName)
	return true
end

local function placeDecor(world: Instance, skinName: string, cf: CFrame, scale: number)
	local skin = Skins[skinName]
	if not skin then
		return
	end
	local holder = Instance.new("Part")
	holder.Name = "Decor_" .. skinName
	holder.Size = skin.Design * scale
	holder.CFrame = cf
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Parent = world
	if not ArtService.Apply(holder, skinName) then
		holder:Destroy()
	end
end

-- An exit's arch (+ its sign lifted over the crown). Locked exits (behind a boss) get theirs when they unlock.
local EXIT_ARCH_SCALE = 2.6 -- the arch's opening must clear the 12×12 portal field
local function dressExit(part: BasePart)
	local design = SHARED.ExitArch.Design * EXIT_ARCH_SCALE
	local arch = Instance.new("Part")
	arch.Name = "ExitArch"
	arch.Size = design
	arch.CFrame = part.CFrame * CFrame.new(0, -part.Size.Y / 2 + design.Y / 2, 0)
	arch.Anchored = true
	arch.CanCollide = false
	arch.CanQuery = false
	arch.CanTouch = false
	arch.Transparency = 1
	arch.Parent = part.Parent
	if not ArtService.Apply(arch, "ExitArch") then
		arch:Destroy()
	else
		-- the exit's sign hung inside the portal field and ended up buried in the (much bigger) arch: lift it
		-- just over the arch's crown so it still reads from far away
		local top = arch.Position.Y + design.Y / 2
		for _, s in (part.Parent :: Instance):GetChildren() do
			local flat = s:IsA("BasePart") and (s.Position - part.Position) * Vector3.new(1, 0, 1)
			if
				flat
				and s.Name == "Sign"
				and flat.Magnitude < 3
				and s.Position.Y > part.Position.Y
				and s.Position.Y < top
			then
				s.CFrame += Vector3.new(0, top + s.Size.Y / 2 + 0.5 - s.Position.Y, 0)
			end
		end
	end
end

-- Shared pieces in every world: exit arches, Duo Pound buttons and Heavy Levers (their state shows on an inlay,
-- since the grey-box part that turned green is hidden under the skin)
local function dressShared(world: Instance, worldName: string)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { world }
	params.RespectCanCollide = true
	for _, part in world:GetDescendants() do
		if
			not part:IsA("BasePart")
			or part:GetAttribute("Skinned")
			or CollectionService:HasTag(part, "CodeLayer") -- Code Layer pieces keep their teal code look
			or CollectionService:HasTag(part, "CodeVisual")
		then
			continue
		end
		if CollectionService:HasTag(part, "WorldExit") then
			if not part:GetAttribute("Locked") then
				dressExit(part)
			end
		elseif CollectionService:HasTag(part, "JumpVent") then
			VentFan(part, params)
		elseif CollectionService:HasTag(part, "GrindRail") and not part:FindFirstChild("Prev") then
			-- a rail is a chain of segments (Next links); dress it from its first segment
			local chain = { part }
			local link = part:FindFirstChild("Next") :: ObjectValue?
			while link and link.Value and link.Value:IsA("BasePart") and #chain < 400 do
				table.insert(chain, link.Value)
				link = link.Value:FindFirstChild("Next") :: ObjectValue?
			end
			Rails(chain, worldName, Skins, ArtService.Apply)
		elseif CollectionService:HasTag(part, "VentButton") and ArtService.Apply(part, "ButtonPad") then
			StateInlay(part) -- pound it to flip the vent: the same toy push button as a plate
		elseif CollectionService:HasTag(part, "PressurePlate") and ArtService.Apply(part, "ButtonPad") then
			StateInlay(part) -- any plate a world didn't dress itself: the toy push button (Pixel Plains kit)
		elseif CollectionService:HasTag(part, "DuoPound") and ArtService.Apply(part, "DuoButton") then
			StateInlay(part, Palette.Glow.Duo, nil, CFrame.new(0, part.Size.Y / 2 + 0.75, 0))
		elseif CollectionService:HasTag(part, "HeavyLever") and ArtService.Apply(part, "HeavyLeverSkin") then
			StateInlay(part, Palette.Glow.Duo, Vector3.new(1.6, 0.06, 1.6), CFrame.new(0, -part.Size.Y / 2 + 0.9, 0))
		end
	end
end

-- Every mesh skin a world can use (its own, plus the shared ones its parts name), downloaded in parallel. Done ahead
-- of time for the next world (WorldService), so dressing it later is near-instant; returns when all are in.
function ArtService.Preload(worldName: string, onProgress: ((number) -> ())?)
	local art = Worlds[worldName]
	if not art then
		return
	end
	local names: { [string]: boolean } = {}
	for name, skin in art.Skins do
		if skin.Meshes and not skin.Build then
			names[name] = true
		end
	end
	for _, name in art.Dressing do
		names[name] = true
	end
	for _, item in art.Decor do
		names[item[1]] = true
	end
	local list = {}
	for name in names do
		local skin = Skins[name]
		if skin and skin.Meshes and not skin.Build then
			table.insert(list, name)
		end
	end
	local pending = #list
	for _, name in list do
		task.spawn(function()
			templatesFor(name)
			pending -= 1
			if onProgress then
				onProgress(1 - pending / math.max(#list, 1))
			end
		end)
	end
	while pending > 0 do
		task.wait()
	end
end

-- Dresses a freshly built grey-box world in the background: every skin downloads first (in parallel), then the
-- parts nearest `focus` (the spawn) are dressed first, then decor and extras. Progress 0..1 goes to `onProgress`;
-- the world gets the attribute `Dressed` = true when it's all done (WorldService holds a loading screen till then).
function ArtService.Dress(world: Instance, worldName: string, focus: Vector3?, onProgress: ((number) -> ())?)
	workspace.Terrain:Clear() -- terrain belongs to one world at a time (the castle's mountain)
	local art = Worlds[worldName]
	local function progress(k: number)
		if onProgress then
			onProgress(k)
		end
	end
	if not art then
		world:SetAttribute("Dressed", true)
		return
	end
	task.spawn(function()
		ArtService.Preload(worldName, function(k)
			progress(k * 0.5)
		end)
		local todo: { { part: BasePart, skin: string } } = {}
		for _, d in world:GetDescendants() do
			local skinName = d:GetAttribute("Skin") or art.Dressing[d.Name] -- a level part's own `Skin` wins
			if skinName and d:IsA("BasePart") then
				table.insert(todo, { part = d, skin = skinName })
			end
		end
		if focus then
			table.sort(todo, function(x, y)
				return (x.part.Position - focus).Magnitude < (y.part.Position - focus).Magnitude
			end)
		end
		for i, job in todo do
			if not world.Parent then
				return
			end
			ArtService.Apply(job.part, job.skin)
			if i % 25 == 0 then
				progress(0.5 + 0.4 * i / #todo)
			end
		end
		progress(0.9)
		for _, item in art.Decor do
			if world.Parent then
				-- item[4]: the Greybox section it belongs to (decor moves with that section's Shift)
				local section = item[4] and world:FindFirstChild(item[4])
				local shift = (section and section:GetAttribute("Shift") or Vector3.zero) :: Vector3
				placeDecor(world, item[1], CFrame.new(shift) * item[2], item[3] or 1)
			end
		end
		if art.Extras and world.Parent then
			art.Extras(world, ArtService.Apply)
		end
		if world.Parent then
			dressShared(world, worldName)
			LeverSupports(world, ArtService.Apply) -- posts / wall arms / footings: no lever floats
		end
		progress(1)
		world:SetAttribute("Dressed", true)
	end)
	-- parts spawned later (dropper blocks) get their skin too
	world.DescendantAdded:Connect(function(d)
		local skinName = d:GetAttribute("Skin") or art.Dressing[d.Name]
		if skinName and d:IsA("BasePart") and not d:GetAttribute("Skinned") then
			task.defer(ArtService.Apply, d, skinName)
		end
	end)
end

-- Badges ------------------------------------------------------------------------------------------

local badgeTemplates: { [string]: MeshPart }? = nil

local function giveBadge(p: Player)
	local character = p.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local emblemName = (Badges.Emblem :: any)[p:GetAttribute("Role") or ""]
	if not (character and humanoid and badgeTemplates) then
		return
	end
	local old = character:FindFirstChild("RoleBadge")
	if old then
		old:Destroy()
	end
	if not emblemName then
		return
	end
	local templates = badgeTemplates :: { [string]: MeshPart }
	local s = Badges.Scale
	local accessory = Instance.new("Accessory")
	accessory.Name = "RoleBadge"
	local handle = templates.SH_Prop_Badge_Plate:Clone()
	handle.Name = "Handle"
	handle.Size *= s
	handle.Anchored = false
	handle.Massless = true
	handle.CanCollide = false
	handle.CanQuery = false
	handle.Parent = accessory
	-- The badge's front (-Z) must face away from the body: turn it around and push it behind the attachment.
	local attach = Instance.new("Attachment")
	attach.Name = "BodyBackAttachment"
	attach.CFrame = CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 0, -Badges.BackOffset)
	attach.Parent = handle
	local info = Badges.Meshes[emblemName]
	local emblem = templates[emblemName]:Clone()
	emblem.Size *= s
	emblem.Anchored = false
	emblem.Massless = true
	emblem.CanCollide = false
	emblem.CanQuery = false
	emblem.CFrame = handle.CFrame * CFrame.new(info.Offset * s)
	-- a Weld with a fixed C0 (a WeldConstraint records its offset when it activates, which can be after
	-- AddAccessory has already moved the plate, leaving the emblem behind)
	local weld = Instance.new("Weld")
	weld.Part0 = handle
	weld.Part1 = emblem
	weld.C0 = CFrame.new(info.Offset * s)
	weld.Parent = emblem
	emblem.Parent = handle
	humanoid:AddAccessory(accessory)
end

local function watchBadges(p: Player)
	p.CharacterAdded:Connect(function(character)
		character:WaitForChild("Humanoid")
		character:WaitForChild("UpperTorso", 5)
		giveBadge(p)
	end)
	p:GetAttributeChangedSignal("Role"):Connect(function()
		giveBadge(p)
	end)
	if p.Character then
		task.spawn(giveBadge, p)
	end
end

-- Held tools ---------------------------------------------------------------------------------------
-- The items in each player's hands follow their Kit attribute (ToolFx.Held), welded so everyone sees them. The
-- item with a muzzle is named "HeldTool" (effects start there); the rest are "HeldItem".

local heldTemplates: { [string]: MeshPart | false } = {}

local function heldTemplate(item: ToolFx.HeldItem): MeshPart?
	local cached = heldTemplates[item.Id]
	if cached == nil then
		local ok, result = pcall(MeshAssets.Template, "HeldTool", {
			Id = item.Id,
			TextureId = item.TextureId,
			Offset = Vector3.zero,
			Size = item.Size,
			Material = Enum.Material.SmoothPlastic,
		})
		if not ok then
			warn(`[ArtService] held item {item.Id}: {result}`)
		end
		cached = if ok then result else false
		heldTemplates[item.Id] = cached
	end
	return if cached then cached else nil
end

local function giveHeld(p: Player)
	local character = p.Character
	if not character then
		return
	end
	for _, d in character:GetChildren() do
		if d:GetAttribute("Held") then
			d:Destroy()
		end
	end
	local kit = p:GetAttribute("Kit") :: string?
	for _, item in (kit and ToolFx.Held[kit]) or {} do
		local hand = character:FindFirstChild(item.Hand)
		local template = heldTemplate(item)
		if
			not (hand and hand:IsA("BasePart") and template)
			or p.Character ~= character
			or p:GetAttribute("Kit") ~= kit
		then
			continue
		end
		local handle = template:Clone()
		handle.Name = if item.Muzzle then "HeldTool" else "HeldItem"
		handle:SetAttribute("Held", true)
		handle.Anchored = false
		handle.Massless = true
		handle.CanCollide = false
		handle.CanQuery = false
		handle.CanTouch = false
		handle.CFrame = hand.CFrame * item.Grip
		if item.Muzzle then
			local muzzle = Instance.new("Attachment")
			muzzle.Name = "Muzzle"
			muzzle.Position = item.Muzzle
			muzzle.Parent = handle
		end
		local weld = Instance.new("Weld")
		weld.Part0 = hand
		weld.Part1 = handle
		weld.C0 = item.Grip
		weld.Parent = handle
		handle.Parent = character
		if item.GlowWhile then
			local attr = item.GlowWhile
			local function glow()
				local h = handle:FindFirstChild("Glow")
				if p:GetAttribute(attr) and not h then
					local hl = Instance.new("Highlight")
					hl.Name = "Glow"
					hl.FillColor = Palette.Miko
					hl.FillTransparency = 0.8
					hl.OutlineColor = Palette.Glow.Miko
					hl.OutlineTransparency = 0.1
					hl.DepthMode = Enum.HighlightDepthMode.Occluded
					hl.Parent = handle
				elseif not p:GetAttribute(attr) and h then
					h:Destroy()
				end
			end
			local conn = p:GetAttributeChangedSignal(attr):Connect(glow)
			handle.Destroying:Once(function()
				conn:Disconnect()
			end)
			glow()
		end
		if item.ShiftedGrip then
			local function place()
				weld.C0 = if p:GetAttribute("Shifted") then item.ShiftedGrip :: CFrame else item.Grip
			end
			local conn = p:GetAttributeChangedSignal("Shifted"):Connect(place)
			handle.Destroying:Once(function()
				conn:Disconnect()
			end)
			place()
		end
	end
end

local function watchHeld(p: Player)
	p.CharacterAdded:Connect(function(character)
		character:WaitForChild("RightHand", 5)
		giveHeld(p)
	end)
	p:GetAttributeChangedSignal("Kit"):Connect(function()
		giveHeld(p)
	end)
	if p.Character then
		task.spawn(giveHeld, p)
	end
end

-- Init ---------------------------------------------------------------------------------------------

ArtService.DressExit = dressExit

function ArtService.Init()
	for _, p in Players:GetPlayers() do
		watchHeld(p)
	end
	Players.PlayerAdded:Connect(watchHeld)

	task.spawn(function()
		local templates = MeshAssets.Load(PipMeshes, "Pip")
		if not templates then
			return
		end
		local model = Instance.new("Model")
		model.Name = "PipModel"
		for name, info in PipMeshes do
			local p = templates[name]
			p.CFrame = CFrame.new(info.Offset) * CFrame.Angles(0, math.rad(info.Yaw or 0), 0)
			p.CastShadow = false
			p.Parent = model
		end
		model.PrimaryPart = templates.Body
		-- keeps Pip readable in dark worlds; PipController recolors it. Sits in front of the face (the mesh's +Z):
		-- a light inside the body would leave Pip's own surface dark.
		local lamp = Instance.new("Attachment")
		lamp.Name = "Glow"
		lamp.Position = Vector3.new(0, 0.2, 1.8)
		lamp.Parent = templates.Body
		local glow = Instance.new("PointLight")
		glow.Color = Palette.Duo
		glow.Range = 10
		glow.Brightness = 1.6
		glow.Parent = lamp
		model.Parent = ReplicatedStorage
	end)

	task.spawn(function()
		badgeTemplates = MeshAssets.Load(Badges.Meshes, "Badges")
		if not badgeTemplates then
			return
		end
		for _, p in Players:GetPlayers() do
			watchBadges(p)
		end
		Players.PlayerAdded:Connect(watchBadges)
	end)
end

return ArtService
