-- Loading screen (user Oct 11: no grey boxes popping into art in front of the player). Covers the screen while the
-- server builds and dresses a world (workspace `WorldLoading`, `LoadingWorld`, `LoadProgress` from WorldService.Load),
-- then, still covered, downloads the meshes and textures around you (ContentProvider) so nothing pops in on this
-- client either, and fades out. Shown from the moment the client starts (the first load).
-- Look (user plan Oct 12, "RDR2-style painted world card"): the world's painting (Config/LoadingCards: two image
-- halves side by side) fills the screen, still (a drift jittered), with a soft vignette, the world's name, tagline and
-- one rotating tip bottom-left, a small spinner bottom-right and only a thin progress line along the bottom edge.
-- A world without a painting shows its sky panorama instead.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Worlds = require(ReplicatedStorage.Shared.Config.Worlds)
local UiTheme = require(ReplicatedStorage.Shared.Config.UiTheme)
local LoadingCards = require(ReplicatedStorage.Shared.Config.LoadingCards)

local player = Players.LocalPlayer

local LoadingController = {}

local TIP_TIME = 5 -- s each tip stays
local ASPECT = 1824 / 1024 -- the painting's shape (two 912×1024 halves)

local gui: ScreenGui
local back: Frame
local fill: Frame
local shownAt = 0
local session = 0 -- bumps on every show: a stale hide never closes a newer screen
local spin: RBXScriptConnection?

local GENERIC_TIPS = { "Reading the save file...", "Fixing a few pixels...", "Pip is tidying up..." }

local function text(parent: Instance, props: { [string]: any }): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextYAlignment = Enum.TextYAlignment.Bottom
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeColor3 = Color3.new(0, 0, 0)
	t.TextStrokeTransparency = 0.6
	for k, v in props do
		(t :: any)[k] = v
	end
	t.Parent = parent
	return t
end

-- A dark gradient over one edge of the painting (vignette + room for the text).
local function shade(parent: Instance, rotation: number, strength: number, reach: number)
	local f = Instance.new("Frame")
	f.Size = UDim2.fromScale(1, 1)
	f.BackgroundColor3 = Color3.new(0, 0, 0)
	f.BorderSizePixel = 0
	f.ZIndex = 3
	local g = Instance.new("UIGradient")
	g.Rotation = rotation
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1 - reach, 1),
		NumberSequenceKeypoint.new(1, 1 - strength),
	})
	g.Parent = f
	f.Parent = parent
end

local function build(worldName: string?)
	if gui then
		gui:Destroy()
	end
	if spin then
		spin:Disconnect()
		spin = nil
	end
	local theme = UiTheme.For(worldName)
	local info = worldName and Worlds.ByName[worldName]
	local card = worldName and LoadingCards[worldName]

	gui = Instance.new("ScreenGui")
	gui.Name = "Loading"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.new(0, 0, 0)
	back.BorderSizePixel = 0
	back.ClipsDescendants = true
	back.Parent = gui

	-- the painting: sized to cover the screen (cropped, never letterboxed), drifting slowly
	local art = Instance.new("Frame")
	art.Name = "Art"
	art.AnchorPoint = Vector2.new(0.5, 0.5)
	art.BackgroundTransparency = 1
	art.ZIndex = 1
	art.Parent = back
	local images: { ImageLabel } = {}
	local function half(image: string, x: number, width: number)
		local i = Instance.new("ImageLabel")
		i.BackgroundTransparency = 1
		i.Position = UDim2.fromScale(x, 0)
		i.Size = UDim2.fromScale(width, 1)
		i.Image = image
		i.ScaleType = Enum.ScaleType.Stretch
		i.ZIndex = 1
		i.Parent = art
		table.insert(images, i)
	end
	local aspect = ASPECT
	if card then
		half(card.L, 0, 0.5)
		half(card.R, 0.5, 0.5)
	else
		local box = info and info.Look.Skybox
		half(if box then box.Ft else "rbxasset://textures/sky/sky512_ft.tex", 0, 1)
		aspect = 1
	end
	local function cover(): Vector2
		local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		local w = math.max(view.X, view.Y * aspect)
		return Vector2.new(w, w / aspect)
	end
	-- Still, on whole pixels (user Oct 17, "why is it shaking": a slow push-in steps pixel by pixel and the two halves
	-- snap separately, so any drift reads as jitter). The halves meet on an exact pixel column.
	local size = cover()
	local w = math.ceil(size.X / 2) * 2
	local h = math.ceil(size.Y)
	art.Size = UDim2.fromOffset(w, h)
	art.Position = UDim2.fromScale(0.5, 0.5)
	if #images == 2 then
		images[1].Size = UDim2.fromOffset(w / 2, h)
		images[2].Position = UDim2.fromOffset(w / 2, 0)
		images[2].Size = UDim2.fromOffset(w / 2, h)
	end
	for _, i in images do -- fade the painting in instead
		i.ImageTransparency = 1
		TweenService:Create(i, TweenInfo.new(0.5), { ImageTransparency = 0 }):Play()
	end

	shade(back, 90, 0.75, 0.45) -- bottom: text sits here
	shade(back, 180, 0.45, 0.35) -- left
	shade(back, 0, 0.3, 0.2) -- right
	shade(back, 270, 0.3, 0.18) -- top

	-- bottom-left: world name, tagline, rotating tip
	local block = Instance.new("Frame")
	block.BackgroundTransparency = 1
	block.AnchorPoint = Vector2.new(0, 1)
	block.Position = UDim2.new(0, 56, 1, -44)
	block.Size = UDim2.fromOffset(640, 190)
	block.ZIndex = 4
	block.Parent = back
	local scale = Instance.new("UIScale") -- phones: shrink with the screen
	local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.clamp(view.X / 1280, 0.55, 1.2)
	scale.Parent = block

	text(block, {
		Name = "Title",
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(1, 0, 0, 72),
		Font = theme.TitleFont,
		TextSize = 64,
		TextScaled = false,
		Text = if info then info.Title else "Glitched Together",
		ZIndex = 5,
	})
	text(block, {
		Name = "Tagline",
		Position = UDim2.fromOffset(2, 78),
		Size = UDim2.new(1, 0, 0, 28),
		Font = theme.Font,
		TextSize = 24,
		TextTransparency = 0.15,
		Text = if card then card.Tagline else "",
		ZIndex = 5,
	})
	local rule = Instance.new("Frame")
	rule.Position = UDim2.fromOffset(2, 118)
	rule.Size = UDim2.fromOffset(46, 3)
	rule.BackgroundColor3 = theme.Accent
	rule.BorderSizePixel = 0
	rule.ZIndex = 5
	rule.Parent = block
	local tips = if card then card.Tips else GENERIC_TIPS
	local tip = text(block, {
		Name = "Tip",
		Position = UDim2.fromOffset(2, 130),
		Size = UDim2.new(1, 0, 0, 56),
		Font = theme.Font,
		TextSize = 20,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		TextTransparency = 0.1,
		Text = tips[math.random(#tips)],
		ZIndex = 5,
	})
	if #tips > 1 then
		local mine = session
		task.spawn(function()
			local index = table.find(tips, tip.Text) or 1
			while gui and gui.Parent and mine == session do
				task.wait(TIP_TIME)
				if not (gui and gui.Parent and mine == session) then
					break
				end
				TweenService:Create(tip, TweenInfo.new(0.35), { TextTransparency = 1, TextStrokeTransparency = 1 })
					:Play()
				task.wait(0.4)
				index = index % #tips + 1
				tip.Text = tips[index]
				TweenService:Create(tip, TweenInfo.new(0.35), { TextTransparency = 0.1, TextStrokeTransparency = 0.6 })
					:Play()
			end
		end)
	end

	-- bottom-right: a small spinning arc
	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(1, 1)
	ring.Position = UDim2.new(1, -52, 1, -50)
	ring.Size = UDim2.fromOffset(30, 30)
	ring.BackgroundTransparency = 1
	ring.ZIndex = 5
	ring.Parent = back
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ring
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Parent = ring
	local arc = Instance.new("UIGradient")
	arc.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0.1),
		NumberSequenceKeypoint.new(0.51, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	arc.Parent = stroke
	spin = RunService.RenderStepped:Connect(function(dt)
		arc.Rotation = (arc.Rotation + dt * 300) % 360
	end)

	-- the progress line along the very bottom
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0, 1)
	bar.Position = UDim2.fromScale(0, 1)
	bar.Size = UDim2.new(1, 0, 0, 3)
	bar.BackgroundColor3 = Color3.new(1, 1, 1)
	bar.BackgroundTransparency = 0.85
	bar.BorderSizePixel = 0
	bar.ZIndex = 5
	bar.Parent = back
	fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0.02, 1)
	fill.BackgroundColor3 = theme.Accent
	fill.BorderSizePixel = 0
	fill.ZIndex = 6
	fill.Parent = bar

	gui.Parent = player:WaitForChild("PlayerGui")
	-- fetch the painting first (cached after the first time), so it doesn't pop in mid-drift
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(images)
		end)
	end)
end

local function setProgress(k: number)
	if fill and fill.Parent then
		TweenService:Create(fill, TweenInfo.new(0.2), { Size = UDim2.fromScale(math.clamp(k, 0.02, 1), 1) }):Play()
	end
end

local function show()
	session += 1
	shownAt = os.clock()
	build(workspace:GetAttribute("LoadingWorld") :: string?)
	setProgress(((workspace:GetAttribute("LoadProgress") or 0) :: number) * 0.85)
end

-- Download what's around you (streamed in near the spawn) while still covered.
local function preloadAround()
	task.wait(0.4) -- let streaming deliver the spawn area
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local world = workspace:FindFirstChild("World")
	if not (root and world) then
		return
	end
	local list: { Instance } = {}
	local radius = Tuning.WorldLoad.ClientRadius
	for _, d in world:GetDescendants() do
		if d:IsA("MeshPart") then
			if (d.Position - root.Position).Magnitude < radius then
				table.insert(list, d)
			end
		elseif d:IsA("Decal") or d:IsA("Texture") or d:IsA("SurfaceAppearance") then
			local part = d.Parent
			if part and part:IsA("BasePart") and (part.Position - root.Position).Magnitude < radius then
				table.insert(list, d)
			end
		end
	end
	local done, total = 0, #list
	local finished = false
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(list, function()
				done += 1
				setProgress(0.85 + 0.15 * done / math.max(total, 1))
			end)
		end)
		finished = true
	end)
	local started = os.clock()
	while not finished and os.clock() - started < Tuning.WorldLoad.ClientTimeout do
		task.wait(0.1)
	end
end

local function hide()
	local mine = session
	preloadAround()
	setProgress(1)
	local wait = Tuning.WorldLoad.MinShow - (os.clock() - shownAt)
	if wait > 0 then
		task.wait(wait)
	end
	if mine ~= session or workspace:GetAttribute("WorldLoading") == true or not gui then
		return -- a new load started meanwhile
	end
	session += 1 -- stops the tip loop
	local closing = gui
	local fade = TweenInfo.new(0.6)
	TweenService:Create(back, fade, { BackgroundTransparency = 1 }):Play()
	for _, d in back:GetDescendants() do
		if d:IsA("ImageLabel") then
			TweenService:Create(d, fade, { ImageTransparency = 1 }):Play()
		elseif d:IsA("Frame") then
			TweenService:Create(d, fade, { BackgroundTransparency = 1 }):Play()
		elseif d:IsA("TextLabel") then
			TweenService:Create(d, fade, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		elseif d:IsA("UIStroke") then
			TweenService:Create(d, fade, { Transparency = 1 }):Play()
		end
	end
	task.delay(0.65, function()
		closing:Destroy()
		if gui == closing and spin then
			spin:Disconnect()
			spin = nil
		end
	end)
end

function LoadingController.Init()
	show() -- the first load: covered from the start
	if workspace:GetAttribute("WorldLoading") == false then
		task.spawn(hide) -- joined after it had loaded
	end
	workspace:GetAttributeChangedSignal("WorldLoading"):Connect(function()
		if workspace:GetAttribute("WorldLoading") == true then
			show()
		else
			task.spawn(hide)
		end
	end)
	workspace:GetAttributeChangedSignal("LoadProgress"):Connect(function()
		if workspace:GetAttribute("WorldLoading") == true then
			setProgress(((workspace:GetAttribute("LoadProgress") or 0) :: number) * 0.85)
		end
	end)
	workspace:GetAttributeChangedSignal("LoadingWorld"):Connect(function()
		if workspace:GetAttribute("WorldLoading") == true then
			show() -- restyle for the world being loaded
		end
	end)
end

return LoadingController
