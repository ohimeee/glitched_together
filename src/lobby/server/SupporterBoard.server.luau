-- The lobby's Supporter Wall (user, Oct 18): a big corkboard on the bedroom's left wall, above the toy chest, with
-- the polaroid podium of everyone who supported the game (Util/Supporters; the same list as the Epilogue board and
-- the credits). Three paper slips pinned at its foot are the cosmetic passes' controls (Config/Supporters): reachable
-- from the toy-chest lid; not owned = Roblox's buy prompt, owned = cycle the tag color / title or turn the aura off.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Supporters = require(ReplicatedStorage.Shared.Util.Supporters)

local X0 = -160 -- the left wall (LobbyRoom)
local CENTER = Vector3.new(X0 + 1, 12, -20)
local W, H = 72, 46 -- studs (the bedroom is doll scale: ~1 m wide)
local rgb = Color3.fromRGB

Supporters.Init({ TagHeight = 4.4 }) -- over the lobby's KAI / MIKO role tag

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

local cork = part("Cork", Vector3.new(W, H, 1.2), facing, {
	Material = Enum.Material.Fabric,
	MaterialVariant = "LobbyCork",
	Color = rgb(226, 200, 170),
	CanCollide = false,
})
local OAK =
	{ Material = Enum.Material.Wood, MaterialVariant = "LobbyDesk", Color = rgb(196, 150, 104), CanCollide = false }
for _, s in { -1, 1 } do
	part("Frame", Vector3.new(W + 6, 3, 2.4), facing * CFrame.new(0, s * (H / 2 + 1.5), 0), OAK)
	part("Frame", Vector3.new(3, H, 2.4), facing * CFrame.new(s * (W / 2 + 1.5), 0, 0), OAK)
end
Supporters.Wall(cork, Enum.NormalId.Front, { PixelsPerStud = 14 })

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
	gui.LightInfluence = 0.6
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
	prompt.MaxActivationDistance = 22
	prompt.Parent = slip
	prompt.Triggered:Connect(function(player)
		Supporters.Cycle(player, s[1] :: any)
	end)
end

folder.Parent = workspace:WaitForChild("Lobby", 30) or workspace
