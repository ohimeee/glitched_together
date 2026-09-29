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
local PipMeshes = require(script.Pip)
local Badges = require(script.Badges)

type WorldArt = { Skins: { [string]: MeshAssets.Skin }, Dressing: { [string]: string }, Decor: { { any } } }

local Worlds: { [string]: WorldArt } = {
	Prologue = require(script.Prologue),
	PixelPlains = require(script.PixelPlains),
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
	return not part.Anchored or CollectionService:HasTag(part, "Mover") or CollectionService:HasTag(part, "Pullable")
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
		p.CFrame = part.CFrame * CFrame.new(info.Offset * k)
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
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = emblem
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

-- Init ---------------------------------------------------------------------------------------------

function ArtService.Init()
	task.spawn(function()
		local templates = MeshAssets.Load(PipMeshes, "Pip")
		if not templates then
			return
		end
		local model = Instance.new("Model")
		model.Name = "PipModel"
		for name, info in PipMeshes do
			local p = templates[name]
			p.CFrame = CFrame.new(info.Offset)
			p.CastShadow = false
			p.Parent = model
		end
		model.PrimaryPart = templates.Pip_Body
		local glow = Instance.new("PointLight") -- keeps Pip readable in dark worlds; PipController recolors it
		glow.Color = Palette.Duo
		glow.Range = 8
		glow.Brightness = 1.2
		glow.Parent = templates.Pip_Body
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
