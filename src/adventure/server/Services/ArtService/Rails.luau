-- Grind rails run over open air (nothing solid for hundreds of studs below), so each rail is dressed as a structure
-- whose supports run down into the void and fade out. A rail is a chain of straight segments (Greybox `railPath`,
-- linked by `Next`), dressed along its whole length; supports go every few studs of arc length.
--   Pixel Plains (user pick, Oct 3): a voxel mine track, iron rails on oak sleepers, on stacked log trestles with a
--     cap beam, grass vines hanging off some caps (tools/piece_kit build_pp, PieceKitPP.fbx).
--   Everywhere else (Prologue stage set): a polished pipe on saddle clamps, pole + flange, over box-truss pylons
--     (tools/piece_kit, PieceKit.fbx + the Prologue truss).
-- Visual only: the grey-box segments stay the grind surface; every art part is CanCollide/CanQuery false.
local PIPE_STYLE = {
	Prologue = { Steel = Color3.fromRGB(196, 200, 210), Pipe = Color3.fromRGB(228, 232, 240) },
}
local PIPE_DEFAULT = { Steel = Color3.fromRGB(150, 152, 160), Pipe = Color3.fromRGB(222, 226, 234) }
local FADE = { 0.25, 0.5, 0.72, 0.9 } -- last support segments (deepest last)
local VINE = Color3.fromHex("#3FA34D") -- the islands' grass vines
local rng = Random.new(2024)

local function holder(name: string, size: Vector3, cf: CFrame, parent: Instance): Part
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

local function tint(h: Instance, color: Color3?, fade: number?)
	for _, m in h:GetChildren() do
		if m:IsA("MeshPart") then
			if color and m.Name ~= "Bolt" then
				m.Color = color
			end
			if fade then
				m.Transparency = fade
			end
		end
	end
end

-- support points every `spacing` studs of arc length: { position on the rail centre line, the segment there }
local function supports(chain: { BasePart }, spacing: number): { { pos: Vector3, seg: BasePart } }
	local total = 0
	for _, seg in chain do
		total += seg.Size.Z
	end
	local n = math.max(2, math.round(total / spacing))
	local out = {}
	local i, acc = 1, 0
	for k = 1, n do
		local target = (k - 0.5) / n * total
		while i < #chain and acc + chain[i].Size.Z < target do
			acc += chain[i].Size.Z
			i += 1
		end
		local seg = chain[i]
		local along = math.clamp(target - acc, 0, seg.Size.Z)
		-- segment local +Z is its start (lookAt points -Z at the end)
		table.insert(out, { pos = (seg.CFrame * CFrame.new(0, 0, seg.Size.Z / 2 - along)).Position, seg = seg })
	end
	return out
end

-- a column of `skin` segments from `top` down `depth` studs, the last ones fading
local function column(
	apply,
	folder: Instance,
	skin: string,
	design: Vector3,
	x: number,
	top: number,
	z: number,
	flat: CFrame,
	depth: number,
	color: Color3?
)
	local count = math.max(1, math.ceil(depth / design.Y))
	for k = 1, count do
		local y = top - design.Y / 2 - (k - 1) * design.Y
		local seg = holder(skin, design, CFrame.new(x, y, z) * flat, folder)
		if not apply(seg, skin) then
			seg:Destroy()
			return
		end
		tint(seg, color, FADE[k - (count - #FADE)])
	end
end

local function flatOf(seg: BasePart): CFrame
	local look = seg.CFrame.LookVector
	return CFrame.Angles(0, math.atan2(-look.X, -look.Z), 0)
end

-- Pixel Plains: one iron rail on a wooden ladder (It Takes Two refs). Pieces alternate how they're held up: on log
-- trestles right under the rail, or hung by two chains from side arms on trestle towers (`hang`)
local HANG_OFF = 2.5 -- chains hang this far either side of the rail, clear of a grinding player
local TOWER_OFF = HANG_OFF + 5.1 -- the arm's hook sits 5.1 from its root on the tower
local function voxelTrack(chain: { BasePart }, folder: Instance, skins, apply, hang: boolean): boolean
	for _, seg in chain do
		local h = holder("Track", Vector3.new(2.44, 1.175, seg.Size.Z), seg.CFrame * CFrame.new(0, -0.0825, 0), folder)
		if not apply(h, "PPTrack2") then
			return false
		end
	end
	local trestle = skins.PPTrestle.Design
	local cap = skins.PPTrestleCap.Design
	local chainDesign = skins.PPChain.Design
	local arm = skins.PPArm.Design
	local flip = 1
	for _, sp in supports(chain, if hang then 16 else 18) do
		local flat = flatOf(sp.seg)
		local capTop = sp.pos.Y - 0.67 -- under the ladder's stringers
		local capCf = CFrame.new(sp.pos.X, capTop - cap.Y / 2, sp.pos.Z) * flat
		local c = holder("TrestleCap", cap, capCf, folder)
		apply(c, "PPTrestleCap")
		if hang then
			-- a tower beside the rail (sides alternate), an arm out over the cap end, a chain down to the cap
			flip = -flip
			local right = (flat * CFrame.new(flip, 0, 0)).Position
			local armY = sp.pos.Y + 6
			local towerAt = sp.pos + right * TOWER_OFF
			-- the arm's local +X points back at its tower
			local armCf = CFrame.fromMatrix(Vector3.new(towerAt.X, armY, towerAt.Z), right, Vector3.yAxis)
				* CFrame.new(-2.8, -1.11, 0)
			local a = holder("RailArm", arm, armCf, folder)
			apply(a, "PPArm")
			column(apply, folder, "PPTrestle", trestle, towerAt.X, armY + 0.45, towerAt.Z, flat, 96, nil)
			local hookY = armY - 0.9
			local chainTop = sp.pos + right * HANG_OFF
			local len = hookY - capTop
			local n = math.max(1, math.round(len / chainDesign.Y))
			for k = 1, n do
				local piece = len / n
				local y = hookY - piece * (k - 0.5)
				local ch = holder(
					"Chain",
					Vector3.new(0.35, piece, 0.35),
					CFrame.new(chainTop.X, y, chainTop.Z) * flat,
					folder
				)
				apply(ch, "PPChain")
			end
		else
			column(apply, folder, "PPTrestle", trestle, sp.pos.X, capTop - cap.Y + 0.05, sp.pos.Z, flat, 90, nil)
		end
		-- now and then a grass vine hangs off a cap end (like the islands' undersides)
		if rng:NextNumber() < 0.45 then
			local side = if rng:NextNumber() < 0.5 then -1 else 1
			local len = rng:NextNumber(3, 9)
			local vine =
				holder("Vine", Vector3.new(0.9, len, 0.9), capCf * CFrame.new(side * 2.2, -len / 2, 0.75), folder)
			vine.Transparency = 0
			vine.Material = Enum.Material.SmoothPlastic
			vine.MaterialVariant = "PixelPlastic"
			vine.Color = VINE
		end
	end
	return true
end

local function pipeTrack(chain: { BasePart }, folder: Instance, skins, apply, worldName: string): boolean
	local style = PIPE_STYLE[worldName] or PIPE_DEFAULT
	for _, seg in chain do
		local pipe = Instance.new("Part")
		pipe.Name = "RailPipe"
		pipe.Shape = Enum.PartType.Cylinder
		pipe.Size = Vector3.new(seg.Size.Z, 1, 1)
		pipe.CFrame = seg.CFrame * CFrame.Angles(0, math.rad(90), 0)
		pipe.Material = Enum.Material.Metal
		pipe.Color = style.Pipe
		pipe.Anchored = true
		pipe.CanCollide = false
		pipe.CanQuery = false
		pipe.CanTouch = false
		pipe.Parent = folder
	end
	local truss = skins.PR_Truss.Design * 0.5 -- the stage truss at half size: 1.5 across, 6-stud segments
	local base = skins.RailBase.Design
	local POLE = 1.6
	for _, sp in supports(chain, 22) do
		local flat = flatOf(sp.seg)
		-- clamp mesh spans 0 → 1.11 up from the collar; the cradle centre (= pipe centre) is 1.0 up
		local c = holder(
			"RailClamp",
			skins.RailClamp.Design,
			CFrame.new(sp.pos) * sp.seg.CFrame.Rotation * CFrame.new(0, -0.445, 0),
			folder
		)
		if not apply(c, "RailClamp") then
			return false
		end
		tint(c, style.Steel)
		local collar = sp.pos.Y - 1.0
		local pole = holder(
			"RailPole",
			Vector3.new(0.76, POLE, 0.76),
			CFrame.new(sp.pos.X, collar - POLE / 2 + 0.05, sp.pos.Z) * flat,
			folder
		)
		apply(pole, "RailPole")
		tint(pole, style.Steel)
		local flangeTop = collar - POLE
		local b = holder("RailBase", base, CFrame.new(sp.pos.X, flangeTop - base.Y / 2, sp.pos.Z) * flat, folder)
		apply(b, "RailBase")
		tint(b, style.Steel)
		column(apply, folder, "PR_Truss", truss, sp.pos.X, flangeTop - base.Y + 0.1, sp.pos.Z, flat, 140, style.Steel)
	end
	return true
end

return function(chain: { BasePart }, worldName: string, skins: { [string]: any }, apply: (BasePart, string) -> boolean)
	local folder = Instance.new("Folder")
	folder.Name = "RailArt"
	folder.Parent = chain[1].Parent
	local ok = if worldName == "PixelPlains"
		then voxelTrack(chain, folder, skins, apply, chain[1]:GetAttribute("Hang") == true)
		else pipeTrack(chain, folder, skins, apply, worldName)
	if not ok then
		folder:Destroy() -- meshes didn't load: keep the grey-box rail visible
		return
	end
	for _, seg in chain do
		seg.Transparency = 1
		seg:SetAttribute("Skinned", "Rail")
	end
end
