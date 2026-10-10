-- Loading screen (user Oct 11: no grey boxes popping into art in front of the player). Covers the screen while the
-- server builds and dresses a world (workspace `WorldLoading`, `LoadingWorld`, `LoadProgress` from WorldService.Load),
-- then, still covered, downloads the meshes and textures around you (ContentProvider) so nothing pops in on this
-- client either, and fades out. A sticker panel in the loading world's own UI theme: "LOADING <world>" over a save
-- file progress bar. Shown from the moment the client starts (the first load).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Worlds = require(ReplicatedStorage.Shared.Config.Worlds)
local UiTheme = require(ReplicatedStorage.Shared.Config.UiTheme)

local player = Players.LocalPlayer

local LoadingController = {}

local gui: ScreenGui
local back: Frame
local panel: Frame
local title: TextLabel
local worldLabel: TextLabel
local fill: Frame
local note: TextLabel
local shownAt = 0
local session = 0 -- bumps on every show: a stale hide never closes a newer screen

local NOTES = { "Reading the save file...", "Fixing a few pixels...", "Pip is tidying up..." }

local function sticker(frame: GuiObject, theme: UiTheme.Theme)
	local stroke = Instance.new("UIStroke")
	stroke.Color = theme.Stroke
	stroke.Thickness = theme.StrokeWidth
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	if theme.Corner > 0 then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, theme.Corner)
		corner.Parent = frame
	end
end

local function build(worldName: string?)
	if gui then
		gui:Destroy()
	end
	local theme = UiTheme.For(worldName)
	gui = Instance.new("ScreenGui")
	gui.Name = "Loading"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 1000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = theme.Shadow
	back.BorderSizePixel = 0
	back.Parent = gui

	panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(460, 190)
	panel.BackgroundColor3 = theme.Panel
	panel.BorderSizePixel = 0
	panel.Parent = back
	sticker(panel, theme)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(460, 190)
	limit.Parent = panel
	local scale = Instance.new("UIScale") -- phones: the panel shrinks with the screen
	scale.Parent = panel
	local function fit()
		local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		scale.Scale = math.clamp(view.X / 560, 0.55, 1)
	end
	fit()

	title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(24, 18)
	title.Size = UDim2.new(1, -48, 0, 24)
	title.Font = theme.Font
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = theme.SubInk
	title.Text = "LOADING"
	title.Parent = panel

	worldLabel = Instance.new("TextLabel")
	worldLabel.BackgroundTransparency = 1
	worldLabel.Position = UDim2.fromOffset(24, 46)
	worldLabel.Size = UDim2.new(1, -48, 0, 48)
	worldLabel.Font = theme.TitleFont
	worldLabel.TextScaled = true
	worldLabel.TextXAlignment = Enum.TextXAlignment.Left
	worldLabel.TextColor3 = theme.Ink
	local info = worldName and Worlds.ByName[worldName]
	worldLabel.Text = if info then info.Title else "Glitched Together"
	worldLabel.Parent = panel

	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromOffset(24, 112)
	bar.Size = UDim2.new(1, -48, 0, 22)
	bar.BackgroundColor3 = theme.Shadow
	bar.BackgroundTransparency = 0.4
	bar.BorderSizePixel = 0
	bar.Parent = panel
	sticker(bar, theme)
	fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(0.02, 1)
	fill.BackgroundColor3 = theme.Accent
	fill.BorderSizePixel = 0
	fill.Parent = bar
	if theme.Corner > 0 then
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, theme.Corner)
		corner.Parent = fill
	end

	note = Instance.new("TextLabel")
	note.BackgroundTransparency = 1
	note.Position = UDim2.fromOffset(24, 146)
	note.Size = UDim2.new(1, -48, 0, 20)
	note.Font = theme.Font
	note.TextScaled = true
	note.TextXAlignment = Enum.TextXAlignment.Left
	note.TextColor3 = theme.SubInk
	note.Text = NOTES[math.random(#NOTES)]
	note.Parent = panel

	gui.Parent = player:WaitForChild("PlayerGui")
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
	local closing = gui
	local fade = TweenInfo.new(0.45)
	TweenService:Create(back, fade, { BackgroundTransparency = 1 }):Play()
	for _, d in back:GetDescendants() do
		if d:IsA("Frame") then
			TweenService:Create(d, fade, { BackgroundTransparency = 1 }):Play()
		elseif d:IsA("TextLabel") then
			TweenService:Create(d, fade, { TextTransparency = 1 }):Play()
		elseif d:IsA("UIStroke") then
			TweenService:Create(d, fade, { Transparency = 1 }):Play()
		end
	end
	task.delay(0.5, function()
		closing:Destroy()
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
