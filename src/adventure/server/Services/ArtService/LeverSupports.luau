-- Grounds the levers (memory: nothing may float), in every world, after its own art pass:
--  * Miko's pull levers hang high (only her Pull reaches them): a wooden post runs from the static ground under the
--    lever's foot, capped with the iron plate it pivots on. No static ground close under it (a lever over a chasm or
--    over a lift that moves): a wooden arm runs out of the nearest wall/cliff face at foot height, with a brace;
--    no wall there either: a crane on the nearest ground top hangs the lever's plate on two chains.
--    Lifts and other movers never count as ground (a post would stand on a bridge that then rises through it).
--  * Heavy levers were tilted on their centre (base hovering, one edge in the air): stood upright on the floor.
local CollectionService = game:GetService("CollectionService")

local IRON = Color3.fromHex("#4A4A55")
local MAX_POST = 18 -- studs: a lever higher than this over the ground gets a wall arm instead of a stilt
local MAX_ARM = 40 -- studs to search for a wall to hang the arm from
local CRANE_CLEAR = 4 -- studs a crane boom clears the top of the lever it hangs
local MOVING = { "DuoGate", "Mover", "Crumble", "Pullable", "Dropper", "Freezable" }

local function hidden(name: string, size: Vector3, cf: CFrame, parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Parent = parent
	return p
end

local function ironPlate(name: string, size: Vector3, cf: CFrame, parent: Instance)
	local p = hidden(name, size, cf, parent)
	p.Transparency = 0
	p.Material = Enum.Material.Metal
	p.Color = IRON
	return p
end

local function isStatic(part: BasePart): boolean
	if not part.Anchored then
		return false
	end
	for _, tag in MOVING do
		if CollectionService:HasTag(part, tag) then
			return false
		end
	end
	return true
end

-- First static, colliding part along a ray (movers are stepped through).
local function cast(world: Instance, from: Vector3, dir: Vector3): RaycastResult?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { world }
	params.RespectCanCollide = true
	local skip: { Instance } = {}
	for _ = 1, 8 do
		local hit = workspace:Raycast(from, dir, params)
		if not hit or isStatic(hit.Instance) then
			return hit
		end
		table.insert(skip, hit.Instance)
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = skip
		params.RespectCanCollide = true
	end
	return nil
end

-- A wooden beam (the SignPost wood) between two points.
local function beam(name: string, a: Vector3, b: Vector3, thick: number, parent: Instance, apply)
	local length = (b - a).Magnitude
	if length < 0.2 then
		return
	end
	-- the part's Y axis runs along the beam (the post mesh is tall along Y)
	local dir = (b - a).Unit
	local cf = if math.abs(dir.Y) > 0.99
		then CFrame.new((a + b) / 2)
		else CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(math.rad(-90), 0, 0)
	apply(hidden(name, Vector3.new(thick, length, thick), cf, parent), "SignPost")
end

-- The skin's iron base is welded to the lever, so it sat tilted with it and swung when the lever was thrown (user,
-- Oct 11: "the levers bottom is not rooted in place"). Unweld it and stand it upright on the foot: only the shaft and
-- grip throw (InteractableService swings the lever about its foot).
local function rootBase(lever: BasePart, foot: Vector3)
	local base = lever:FindFirstChild("PP_Prop_PullLever_Base")
	if not (base and base:IsA("BasePart")) then
		return
	end
	for _, w in base:GetChildren() do
		if w:IsA("WeldConstraint") then
			w:Destroy()
		end
	end
	base.Anchored = true
	local look = lever.CFrame.RightVector:Cross(Vector3.yAxis)
	local at = foot + Vector3.new(0, base.Size.Y / 2, 0)
	base.CFrame = if look.Magnitude > 0.1 then CFrame.lookAt(at, at + look) else CFrame.new(at)
end

local function supportPull(world: Instance, lever: BasePart, apply)
	local foot = lever.CFrame * Vector3.new(0, -lever.Size.Y / 2, 0)
	local parent = lever.Parent :: Instance
	rootBase(lever, foot)
	local below = cast(world, foot - Vector3.new(0, 0.1, 0), Vector3.new(0, -60, 0))
	local h = below and foot.Y - 0.3 - below.Position.Y
	if below and h and h <= MAX_POST then
		if h > 0.5 then
			beam("LeverPost", below.Position, Vector3.new(foot.X, foot.Y - 0.3, foot.Z), 1.1, parent, apply)
			ironPlate("LeverCap", Vector3.new(2.2, 0.4, 2.2), CFrame.new(foot.X, foot.Y - 0.5, foot.Z), parent)
		else
			-- the foot sits just over the ground: an iron footing fills the gap
			local gap = math.max(foot.Y - below.Position.Y, 0) + 0.1
			ironPlate(
				"LeverCap",
				Vector3.new(2.2, gap, 2.2),
				CFrame.new(foot.X, below.Position.Y + gap / 2, foot.Z),
				parent
			)
		end
		return
	end
	-- over a chasm: an arm out of the nearest wall at foot height
	local at = foot - Vector3.new(0, 0.7, 0)
	local best: RaycastResult? = nil
	for i = 0, 7 do
		local a = i * math.pi / 4
		local hit = cast(world, at, Vector3.new(math.cos(a), 0, math.sin(a)) * MAX_ARM)
		if hit and math.abs(hit.Normal.Y) < 0.5 and (not best or hit.Distance < best.Distance) then
			best = hit
		end
	end
	if not best then
		-- no wall at that height either (cliffs lower than the lever): a gallows on the nearest ground top,
		-- a post up to foot height and an arm across, braced
		local ground: Vector3? = nil
		local groundDist = math.huge
		for i = 0, 7 do
			local a = i * math.pi / 4
			local dir = Vector3.new(math.cos(a), 0, math.sin(a))
			for d = 2, MAX_ARM, 2 do
				if d >= groundDist then
					break
				end
				local hit = cast(world, at + dir * d + Vector3.new(0, 0.5, 0), Vector3.new(0, -MAX_POST, 0))
				if hit and hit.Normal.Y > 0.7 then
					ground, groundDist = hit.Position + dir * 1.5, d + 1.5 -- a little in from the edge
					break
				end
			end
		end
		if not ground then
			warn("[ArtService] pull lever with nothing to stand on or hang from:", lever:GetFullName())
			return
		end
		-- the boom runs high over the gap (out of jump reach, so it never reads as a walkway) and the lever's plate
		-- hangs from it on two chains
		local boomY = foot.Y + lever.Size.Y + CRANE_CLEAR
		local top = Vector3.new(ground.X, boomY, ground.Z)
		local over = Vector3.new(foot.X, boomY, foot.Z)
		beam("LeverPost", ground, top + Vector3.new(0, 0.6, 0), 1.3, parent, apply)
		beam("LeverArm", top, over + (over - top).Unit * 0.8, 1.1, parent, apply)
		local drop = math.min(boomY - ground.Y, 6)
		beam("LeverBrace", top - Vector3.new(0, drop, 0), top:Lerp(over, 0.3), 0.8, parent, apply)
		local plate =
			ironPlate("LeverCap", Vector3.new(2.6, 0.4, 2.6), CFrame.new(foot.X, foot.Y - 0.5, foot.Z), parent)
		local across = (over - top).Unit:Cross(Vector3.yAxis).Unit
		for _, side in { -1, 1 } do
			local low = plate.Position + across * side * 1.1
			local high = Vector3.new(low.X, boomY - 0.5, low.Z)
			ironPlate("LeverChain", Vector3.new(0.25, high.Y - low.Y, 0.25), CFrame.new((low + high) / 2), parent)
		end
		return
	end
	local wall = best.Position - (best.Position - at).Unit * 0.3 -- into the face a little
	beam("LeverArm", wall, at, 1.1, parent, apply)
	-- brace: from lower down the wall to the arm's middle
	local drop = math.min(best.Distance * 0.5, 8)
	beam("LeverBrace", wall - Vector3.new(0, drop, 0), (wall + at) / 2, 0.8, parent, apply)
	ironPlate("LeverCap", Vector3.new(2.2, 0.4, 2.2), CFrame.new(foot.X, foot.Y - 0.5, foot.Z), parent)
end

local function supportHeavy(world: Instance, lever: BasePart)
	-- its one mesh includes the base: stand it upright on the floor under it (it never swings) so the base sits flat
	local hit = cast(world, lever.Position, Vector3.new(0, -(lever.Size.Y / 2 + 4), 0))
	if not hit then
		return
	end
	local old = lever.CFrame
	local look = old.RightVector:Cross(Vector3.yAxis)
	local foot = hit.Position
	local upright = (if look.Magnitude > 0.1 then CFrame.lookAt(foot, foot + look) else CFrame.new(foot))
		* CFrame.new(0, lever.Size.Y / 2, 0)
	lever.CFrame = upright
	for _, mesh in lever:GetChildren() do
		if mesh:IsA("BasePart") then
			mesh.CFrame = upright * old:ToObjectSpace(mesh.CFrame)
		end
	end
end

return function(world: Instance, apply)
	for _, d in world:GetDescendants() do
		if not d:IsA("BasePart") then
			continue
		end
		if d.Name == "PullLever" then
			supportPull(world, d, apply)
		elseif CollectionService:HasTag(d, "HeavyLever") then
			supportHeavy(world, d)
		end
	end
end
