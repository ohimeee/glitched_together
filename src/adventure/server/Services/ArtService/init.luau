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
}

local Skins: { [string]: MeshAssets.Skin } = {}
for _, art in Worlds do
	for name, skin in art.Skins do
		Skins[name] = skin
	end
end

local ArtService = {}

local loaded: { [string]: { [string]: MeshPart } | false } = {} -- skin name → templates, false = failed / not imported

local function templatesFor(skinName: string): { [string]: MeshPart }?
	local cached = loaded[skinName]
	if cached == nil then
		cached = MeshAssets.Load(Skins[skinName].Meshes, skinName) or false
		loaded[skinName] = cached
	end
	return if cached then cached else nil
end

local function moves(part: BasePart): boolean
	return not part.Anchored
		or CollectionService:HasTag(part, "Mover")
		or CollectionService:HasTag(part, "Pullable")
		or CollectionService:HasTag(part, "Enemy") -- CombatService moves enemies by CFrame
end

-- Puts a skin over one grey-box part. Returns false (part untouched) if the meshes aren't available.
function ArtService.Apply(part: BasePart, skinName: string): boolean
	local skin = Skins[skinName]
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

-- Dresses a freshly built grey-box world. Runs in the background: shells pop in once the meshes load.
function ArtService.Dress(world: Instance, worldName: string)
	local art = Worlds[worldName]
	if not art then
		return
	end
	task.spawn(function()
		for _, d in world:GetDescendants() do
			local skinName = art.Dressing[d.Name]
			if skinName and d:IsA("BasePart") then
				ArtService.Apply(d, skinName)
			end
		end
		for _, item in art.Decor do
			if world.Parent then
				placeDecor(world, item[1], item[2], item[3] or 1)
			end
		end
		if art.Extras and world.Parent then
			art.Extras(world, ArtService.Apply)
		end
	end)
	-- parts spawned later (dropper blocks) get their skin too
	world.DescendantAdded:Connect(function(d)
		local skinName = art.Dressing[d.Name]
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
