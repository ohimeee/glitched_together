-- The lobby's Supporter Wall (user, Oct 18): a big corkboard on the bedroom's left wall, above the toy chest, with
-- the polaroid podium of everyone who supported the game (Util/Supporters; the same list as the Epilogue board and
-- the credits). Three paper slips pinned at its foot are the cosmetic passes' controls (Config/Supporters): reachable
-- from the toy-chest lid; not owned = Roblox's buy prompt, owned = cycle the tag color / title or turn the aura off.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshAssets = require(ReplicatedStorage.Shared.Util.MeshAssets)
local Supporters = require(ReplicatedStorage.Shared.Util.Supporters)
local TipJar = require(ReplicatedStorage.Shared.Util.TipJar)

local X0 = -160 -- the left wall (LobbyRoom)
local CENTER = Vector3.new(X0 + 1, 24, -20) -- raised 12 (user, Oct 18: higher)
local W, H = 72, 46 -- studs (the bedroom is doll scale: ~1 m wide)
local rgb = Color3.fromRGB

Supporters.Init({ TagHeight = 4.4 }) -- over the lobby's KAI / MIKO role tag
TipJar.Init()

local folder = Instance.new("Folder")
folder.Name = "SupporterBoard"

-- facing +X, into the room: a part's Front face points along its LookVector
local facing = CFrame.lookAt(CENTER, CENTER + Vector3.xAxis)

local function part(name: string, size: Vector3, cf: CFrame, props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = folder
	return p
end

-- the cork + oak frame are the door wall's corkboard meshes (LobbyKit Cork_Cork / CorkFrame_Oak, front = +Z), turned
-- to face the room; the box parts stay as the fallback and the cork box carries the SurfaceGui
local cork = part("Cork", Vector3.new(W, H, 1.2), facing, {
	Material = Enum.Material.Fabric,
	MaterialVariant = "LobbyCork",
	Color = rgb(226, 200, 170),
	CanCollide = false,
})
local OAK =
	{ Material = Enum.Material.Wood, MaterialVariant = "LobbyDesk", Color = rgb(214, 172, 128), CanCollide = false }
local frames = {}
for _, s in { -1, 1 } do
	table.insert(frames, part("Frame", Vector3.new(W + 6, 3, 2.4), facing * CFrame.new(0, s * (H / 2 + 1.5), 0), OAK))
	table.insert(frames, part("Frame", Vector3.new(3, H, 2.4), facing * CFrame.new(s * (W / 2 + 1.5), 0, 0), OAK))
end
task.spawn(function()
	local turned = CFrame.new(CENTER) * CFrame.Angles(0, math.rad(90), 0) -- mesh +Z (its front) → +X
	local ok, meshes = pcall(function()
		return {
			MeshAssets.Template("CorkMesh", {
				Id = "rbxassetid://86890298415414",
				Offset = Vector3.zero,
				Size = Vector3.new(W, H, 1.2),
				Material = Enum.Material.Fabric,
				Variant = "LobbyCork",
				Color = rgb(226, 200, 170),
			}),
			MeshAssets.Template("FrameMesh", {
				Id = "rbxassetid://98412143460946",
				Offset = Vector3.zero,
				Size = Vector3.new(W + 6, H + 6, 2.4),
				Material = Enum.Material.Wood,
				Variant = "LobbyDesk",
				Color = rgb(214, 172, 128),
			}),
		}
	end)
	if not ok then
		warn("[SupporterBoard] corkboard meshes didn't load, keeping the boxes:", meshes)
		return
	end
	meshes[1].CFrame = turned -- same face as the cork box, which keeps the SurfaceGui
	meshes[2].CFrame = turned
	for _, m in meshes do
		m.Parent = folder
	end
	cork.Transparency = 1
	for _, f in frames do
		f:Destroy()
	end
end)
Supporters.Wall(cork, Enum.NormalId.Front, { PixelsPerStud = 14, TitleGlow = 0.6 })

-- the pass slips: small paper notes pinned along the bottom edge
local SLIPS = {
	{ "Color", "Tag color", "★ NAME TAG\ncolor" },
	{ "Title", "Tag title", "★ NAME TAG\ntitle" },
	{ "Aura", "Glowing aura", "✦ GLOWING\nAURA" },
}
for i, s in SLIPS do
	local slip = part(
		"PassSlip",
		Vector3.new(9, 6, 0.1),
		facing * CFrame.new((i - 2) * 12, -H / 2 + 1, -0.7) * CFrame.Angles(0, 0, math.rad((i - 2) * 4)),
		{ Color = rgb(246, 240, 226), Material = Enum.Material.Fabric, CanCollide = false }
	)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 20
	gui.LightInfluence = 1
	gui.Parent = slip
	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.PermanentMarker
	text.TextScaled = true
	text.TextColor3 = rgb(60, 46, 36)
	text.Text = s[3]
	text.Parent = gui
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = s[2]
	prompt.ObjectText = "Supporter Wall"
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 34 -- from the toy-chest lid up to the raised board
	prompt.Parent = slip
	prompt.Triggered:Connect(function(player)
		Supporters.Cycle(player, s[1] :: any)
	end)
end

folder.Parent = workspace:WaitForChild("Lobby", 30) or workspace

-- the tip jar (user, Oct 18: tips in the lobby too): a glass jar of gold coins with a paper label, on the desk right
-- beside the GLITCHED TOGETHER chalkboard sign (user, Oct 18; sign: x 0, z -14.7, 20 wide), label toward the spawn;
-- [E] opens the tip panel (client TipJar.client, Util/TipPanel)
local JAR = Vector3.new(15, 0, -16) -- desk top is y 0 (sign collider ends at x 10, the capsule ring starts at x 35)
local jar =
	part("TipJar", Vector3.new(7, 6, 6), CFrame.new(JAR + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), {
		Shape = Enum.PartType.Cylinder,
		Material = Enum.Material.Glass,
		Transparency = 0.55,
		Color = rgb(220, 236, 240),
		CanCollide = true,
	})
part("JarLid", Vector3.new(1, 6.4, 6.4), CFrame.new(JAR + Vector3.new(0, 7.4, 0)) * CFrame.Angles(0, 0, math.rad(90)), {
	Shape = Enum.PartType.Cylinder,
	Material = Enum.Material.Fabric,
	MaterialVariant = "LobbyCork",
	Color = rgb(226, 200, 170),
	CanCollide = false,
})
local coins = Random.new(7)
for i = 1, 26 do
	local a = coins:NextNumber(0, math.pi * 2)
	local r = coins:NextNumber(0, 2.2)
	local y = 0.6 + (i // 6) * 0.45 + coins:NextNumber(0, 0.2)
	part(
		"Coin",
		Vector3.new(0.25, 1.4, 1.4),
		CFrame.new(JAR + Vector3.new(math.cos(a) * r, y, math.sin(a) * r))
			* CFrame.Angles(
				coins:NextNumber(-0.5, 0.5),
				coins:NextNumber(0, 6),
				math.rad(90) + coins:NextNumber(-0.4, 0.4)
			),
		{
			Shape = Enum.PartType.Cylinder,
			Material = Enum.Material.Metal,
			Color = rgb(232, 182, 76),
			CanCollide = false,
			CastShadow = false,
		}
	)
end
local tag = part(
	"JarLabel",
	Vector3.new(4.2, 2.4, 0.05),
	CFrame.new(JAR + Vector3.new(0, 3.6, -3.05)) * CFrame.Angles(0, math.pi, 0),
	{
		Color = rgb(246, 240, 226),
		Material = Enum.Material.Fabric,
		CanCollide = false,
	}
)
local tagGui = Instance.new("SurfaceGui")
tagGui.Face = Enum.NormalId.Back -- faces the ring (-Z)
tagGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
tagGui.PixelsPerStud = 40
tagGui.LightInfluence = 1
tagGui.Parent = tag
local tagText = Instance.new("TextLabel")
tagText.Size = UDim2.fromScale(1, 1)
tagText.BackgroundTransparency = 1
tagText.Font = Enum.Font.PermanentMarker
tagText.TextScaled = true
tagText.TextColor3 = rgb(60, 46, 36)
tagText.Text = "TIP JAR ♥\nfor our next game"
tagText.Parent = tagGui
local jarPrompt = Instance.new("ProximityPrompt")
jarPrompt.Name = "SupportPrompt"
jarPrompt.ActionText = "Support"
jarPrompt.ObjectText = "Tip jar"
jarPrompt.HoldDuration = 0
jarPrompt.RequiresLineOfSight = false
jarPrompt.MaxActivationDistance = 10
jarPrompt.Parent = jar
