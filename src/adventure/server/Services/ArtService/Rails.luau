-- Grind rails: every rail runs over open air (nothing solid for hundreds of studs below), so it becomes a polished
-- pipe on bolted saddle clamps, each on a short pole and a flange plate over a box-truss pylon that runs down into the
-- void and fades out (the Prologue stage set's pylons, tools/piece_kit + tools/prologue_kit). Visual only: the grey-box
-- rail stays the grind surface, every art part is CanCollide/CanQuery false.
local STYLE = {
	-- truss/clamp color, pipe color, how far below the rail the pylons fade out
	Prologue = { Steel = Color3.fromRGB(196, 200, 210), Pipe = Color3.fromRGB(228, 232, 240), Depth = 140 },
	PixelPlains = { Steel = Color3.fromRGB(232, 226, 210), Pipe = Color3.fromRGB(222, 226, 234), Depth = 110 },
}
local DEFAULT = { Steel = Color3.fromRGB(150, 152, 160), Pipe = Color3.fromRGB(222, 226, 234), Depth = 110 }
local SPACING = 22 -- studs of rail per pylon
local TRUSS_SCALE = 0.5 -- the stage truss at half size: 1.5 studs across, 6-stud segments
local FADE = { 0.25, 0.5, 0.72, 0.9 } -- last segments (deepest last)
local POLE = 1.6 -- flange top → clamp collar

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

local function tint(h: Instance, color: Color3, fade: number?)
	for _, m in h:GetChildren() do
		if m:IsA("MeshPart") then
			if m.Name ~= "Bolt" then
				m.Color = color
			end
			if fade then
				m.Transparency = fade
			end
		end
	end
end

return function(rail: BasePart, worldName: string, skins: { [string]: any }, apply: (BasePart, string) -> boolean)
	local style = STYLE[worldName] or DEFAULT
	local folder = Instance.new("Folder")
	folder.Name = "RailArt"
	folder.Parent = rail.Parent
	-- the pipe: a cylinder (axis X) along the rail
	local pipe = Instance.new("Part")
	pipe.Name = "RailPipe"
	pipe.Shape = Enum.PartType.Cylinder
	pipe.Size = Vector3.new(rail.Size.Z, 1, 1)
	pipe.CFrame = rail.CFrame * CFrame.Angles(0, math.rad(90), 0)
	pipe.Material = Enum.Material.Metal
	pipe.Color = style.Pipe
	pipe.Anchored = true
	pipe.CanCollide = false
	pipe.CanQuery = false
	pipe.CanTouch = false
	pipe.Parent = folder
	rail.Transparency = 1
	rail:SetAttribute("Skinned", "Rail")

	local look = rail.CFrame.LookVector
	local yaw = math.atan2(-look.X, -look.Z)
	local flat = CFrame.Angles(0, yaw, 0)
	local n = math.max(2, math.round(rail.Size.Z / SPACING))
	local trussDesign = skins.PR_Truss.Design * TRUSS_SCALE
	for i = 1, n do
		local t = (i - 0.5) / n - 0.5
		local centre = rail.Position + look * (t * rail.Size.Z)
		-- saddle clamp: cradle centre = pipe centre, tilted with the rail so the pipe sits in it
		local clamp = skins.RailClamp.Design
		-- (mesh spans 0 → 1.11 up from the collar bottom; the cradle centre sits 1.0 up, so the holder centre is 0.445 below)
		local c =
			holder("RailClamp", clamp, CFrame.new(centre) * rail.CFrame.Rotation * CFrame.new(0, -0.445, 0), folder)
		if not apply(c, "RailClamp") then
			folder:Destroy()
			rail.Transparency = 0
			rail:SetAttribute("Skinned", nil)
			return
		end
		tint(c, style.Steel)
		local collar = centre.Y - 1.0 -- clamp collar bottom (cradle centre is 1 stud above it)
		local pole = holder(
			"RailPole",
			Vector3.new(0.76, POLE, 0.76),
			CFrame.new(centre.X, collar - POLE / 2 + 0.05, centre.Z) * flat,
			folder
		)
		apply(pole, "RailPole")
		tint(pole, style.Steel)
		local flangeTop = collar - POLE
		local base = skins.RailBase.Design
		local b = holder("RailBase", base, CFrame.new(centre.X, flangeTop - base.Y / 2, centre.Z) * flat, folder)
		apply(b, "RailBase")
		tint(b, style.Steel)
		-- truss pylon from under the flange down into the void
		local top = flangeTop - base.Y + 0.1
		local count = math.max(1, math.ceil(style.Depth / trussDesign.Y))
		for k = 1, count do
			local y = top - trussDesign.Y / 2 - (k - 1) * trussDesign.Y
			local seg = holder("RailTruss", trussDesign, CFrame.new(centre.X, y, centre.Z) * flat, folder)
			if not apply(seg, "PR_Truss") then
				seg:Destroy()
				break
			end
			tint(seg, style.Steel, FADE[k - (count - #FADE)])
		end
	end
end
