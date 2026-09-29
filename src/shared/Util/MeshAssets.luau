-- Turns uploaded mesh ids (from Studio's 3D importer) into MeshParts at runtime, so Blender art can live in
-- code/Rojo without hand-saved .rbxm files. Server only: parts made here replicate like any other part.
-- Pattern: keep a data table of { Id, Offset, Size, Material, Color?, Transparency?, Collision? } per mesh,
-- Load() it once, then Clone() the templates (see BLENDER_PLAYBOOK.md §6).
local AssetService = game:GetService("AssetService")

export type MeshInfo = {
	Id: string,
	Offset: Vector3, -- studs, from the owning object's origin (see each data module)
	Size: Vector3, -- studs
	Material: Enum.Material,
	Color: Color3?, -- nil = caller colors it
	Transparency: number?,
	Collision: Enum.CollisionFidelity?, -- nil = CanCollide false
}

local MeshAssets = {}

local cache: { [string]: MeshPart } = {} -- id → loaded template (collision fidelity is part of the key)

local function create(id: string, collision: Enum.CollisionFidelity): MeshPart
	local options = { CollisionFidelity = collision, RenderFidelity = Enum.RenderFidelity.Precise }
	local ok, result = pcall(function()
		return AssetService:CreateMeshPartAsync(Content.fromUri(id), options)
	end)
	if ok then
		return result
	end
	return AssetService:CreateMeshPartAsync(id :: any, options) -- older signature took the id string
end

-- One configured template MeshPart (not parented). Errors if the mesh can't load.
function MeshAssets.Template(name: string, info: MeshInfo): MeshPart
	local collision = info.Collision or Enum.CollisionFidelity.Box
	local key = `{info.Id}|{collision.Name}`
	local base = cache[key]
	if not base then
		base = create(info.Id, collision)
		cache[key] = base
	end
	local p = base:Clone()
	p.Name = name
	p.Size = info.Size
	p.Anchored = true
	p.Material = info.Material
	p.Color = info.Color or Color3.new(1, 1, 1)
	p.Transparency = info.Transparency or 0
	p.CanCollide = info.Collision ~= nil
	p.CanQuery = info.Collision ~= nil
	p.CanTouch = false
	p.CastShadow = info.Material ~= Enum.Material.Neon and info.Material ~= Enum.Material.Glass
	return p
end

-- Loads every mesh of a data table in parallel. Returns nil (and warns) if any fails, so callers can fall back
-- to grey-box parts; an empty id counts as "not imported yet" and also returns nil, quietly.
function MeshAssets.Load(meshes: { [string]: MeshInfo }, label: string): { [string]: MeshPart }?
	for _, info in meshes do
		if info.Id == "" then
			return nil
		end
	end
	local templates: { [string]: MeshPart } = {}
	local pending, failed = 0, false
	for name, info in meshes do
		pending += 1
		task.spawn(function()
			local ok, result = pcall(MeshAssets.Template, name, info)
			if ok then
				templates[name] = result
			else
				warn(`[MeshAssets] {label}: couldn't load {name} ({result}); using grey-box parts`)
				failed = true
			end
			pending -= 1
		end)
	end
	while pending > 0 do
		task.wait()
	end
	return if failed then nil else templates
end

return MeshAssets
