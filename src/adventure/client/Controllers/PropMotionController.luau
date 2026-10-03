-- Slow idle motion for big set-dressing props (tag "PropMotion" on a skin holder part; its mesh children follow).
-- Attributes on the holder: `Spin` (radians/s about the holder's own front axis, e.g. the Prologue settings gear),
-- `Bob` (studs up and down) + `BobRate` (cycles/s). Purely visual and local, like FanController; the holder never
-- collides, so moving it client-side changes nothing for gameplay.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tags = require(ReplicatedStorage.Shared.Util.Tags)

local PropMotionController = {}

type Prop = { home: CFrame, parts: { [BasePart]: CFrame }, phase: number, conns: { RBXScriptConnection } }
local props: { [BasePart]: Prop } = {}

local function track(holder: BasePart)
	local parts = {}
	-- the holder never moves, so a child's offset from it is its server placement. With StreamingEnabled the mesh
	-- children can stream in after the holder (or be replaced when they stream back in), so follow them as they come
	local function add(p: Instance)
		if p:IsA("BasePart") then
			parts[p] = holder.CFrame:ToObjectSpace(p.CFrame)
		end
	end
	for _, p in holder:GetChildren() do
		add(p)
	end
	-- a phase from the position, so neighbouring props don't bob in step
	props[holder] = {
		home = holder.CFrame,
		parts = parts,
		phase = (holder.Position.X + holder.Position.Z) * 0.05,
		conns = {
			holder.ChildAdded:Connect(add),
			holder.ChildRemoved:Connect(function(p)
				parts[p :: BasePart] = nil
			end),
		},
	}
end

local function untrack(holder: BasePart)
	local prop = props[holder]
	if prop then
		for _, c in prop.conns do
			c:Disconnect()
		end
		props[holder] = nil
	end
end

function PropMotionController.Init()
	Tags.each("PropMotion", function(inst)
		if inst:IsA("BasePart") then
			track(inst)
		end
	end, function(inst)
		untrack(inst :: BasePart)
	end)

	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for holder, prop in props do
			local spin = (holder:GetAttribute("Spin") or 0) :: number
			local bob = (holder:GetAttribute("Bob") or 0) :: number
			local rate = (holder:GetAttribute("BobRate") or 0.12) :: number
			local cf = prop.home
				* CFrame.new(0, bob * math.sin((t * rate + prop.phase) * math.pi * 2), 0)
				* CFrame.Angles(0, 0, spin * t)
			for p, offset in prop.parts do
				if p.Parent then
					p.CFrame = cf * offset
				end
			end
		end
	end)
end

return PropMotionController
