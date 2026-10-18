-- Supporter recognition, server only, shared by the lobby and the adventure place (Config/Supporters for the why).
-- Totals live in the OrderedDataStore "SupporterTotals" (key = user id, value = Robux tipped), so both places and
-- every server read the same wall. Per-player choices (tag color, title, hidden) live in "SupporterPrefs".
-- The current list is published on workspace attribute "Supporters" (JSON { {u = id, n = name} }, highest total
-- first) for the end credits. In Studio nothing is written: totals are kept in memory so the wall can be tested.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config.Supporters)
local Products = require(ReplicatedStorage.Shared.Config.Products)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)

assert(RunService:IsServer(), "Supporters is server only")

local T = Tuning.Supporters
local STUDIO = RunService:IsStudio()

export type Entry = { UserId: number, Name: string, Total: number }
type Prefs = { Color: number?, Title: string?, Hidden: boolean?, AuraOff: boolean? }

local Supporters = {}

local totals: OrderedDataStore? = nil
local prefStore: DataStore? = nil
if not STUDIO then
	pcall(function()
		totals = DataStoreService:GetOrderedDataStore("SupporterTotals")
		prefStore = DataStoreService:GetDataStore("SupporterPrefs")
	end)
end

local memory: { [number]: number } = {} -- Studio totals
local list: { Entry } = {}
local changed = Instance.new("BindableEvent")
Supporters.Changed = changed.Event

local names: { [number]: string } = {}
local prefs: { [number]: Prefs } = {}
local tipped: { [number]: number } = {} -- players in this server: their total
local owns: { [Player]: { Aura: boolean, Tag: boolean } } = {}
local tagHeight = T.TagHeight

local function nameOf(id: number): string
	if not names[id] then
		local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, id)
		names[id] = if ok and name then name else `Player {id}`
	end
	return names[id]
end

local function prefsOf(id: number): Prefs
	if prefs[id] then
		return prefs[id]
	end
	local p: Prefs = {}
	if prefStore then
		local ok, saved = pcall(function()
			return (prefStore :: DataStore):GetAsync(tostring(id))
		end)
		if ok and type(saved) == "table" then
			p = saved
		end
	end
	prefs[id] = p
	return p
end

local function savePrefs(id: number)
	if prefStore then
		task.spawn(pcall, function()
			(prefStore :: DataStore):SetAsync(tostring(id), prefs[id])
		end)
	end
end

local function publish()
	local out = {}
	for _, e in list do
		table.insert(out, { u = e.UserId, n = e.Name })
	end
	workspace:SetAttribute("Supporters", HttpService:JSONEncode(out))
	changed:Fire(list)
end

-- Re-read the top supporters (highest total first, hidden ones left out).
function Supporters.Refresh()
	local raw: { { key: string, value: number } } = {}
	if totals then
		local ok, page = pcall(function()
			return (totals :: OrderedDataStore):GetSortedAsync(false, math.min(100, T.WallMax * 2)):GetCurrentPage()
		end)
		if not ok then
			warn("[Supporters] read failed:", page)
			return
		end
		raw = page
	else
		for id, total in memory do
			table.insert(raw, { key = tostring(id), value = total })
		end
		table.sort(raw, function(a, b)
			return a.value > b.value
		end)
	end
	local fresh: { Entry } = {}
	for _, row in raw do
		local id = tonumber(row.key)
		if id and row.value > 0 and not prefsOf(id).Hidden then
			table.insert(fresh, { UserId = id, Name = nameOf(id), Total = row.value })
			if #fresh >= T.WallMax then
				break
			end
		end
	end
	if STUDIO and #fresh == 0 and T.StudioPreview then
		-- placeholder supporters so the walls can be judged in Studio (the owner's headshot on every card)
		local owner = if game.CreatorType == Enum.CreatorType.User and game.CreatorId ~= 0
			then game.CreatorId
			else 11657510634
		local amounts =
			{ 1000, 500, 250, 200, 150, 100, 100, 100, 50, 50, 50, 50, 50, 50, 20, 20, 20, 10, 10, 10, 10, 10, 10 }
		for i = 1, T.WallMax do
			table.insert(fresh, { UserId = owner, Name = `Placeholder{i}`, Total = amounts[i] or 10 })
		end
	end
	list = fresh
	publish()
end

function Supporters.List(): { Entry }
	return list
end

-- The tag + aura on one character (called on spawn and whenever a pass / tip / choice changes).
local function dress(p: Player)
	local character = p.Character
	local head = character and character:FindFirstChild("Head")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not head or not root then
		return
	end
	local has = owns[p] or { Aura = false, Tag = false }
	local tip = (tipped[p.UserId] or 0) > 0
	local pref = prefsOf(p.UserId)

	local tag = head:FindFirstChild("SupporterTag") :: BillboardGui?
	if not (tip or has.Tag) then
		if tag then
			tag:Destroy()
		end
	else
		if not tag then
			local newTag = Instance.new("BillboardGui")
			newTag.Name = "SupporterTag"
			newTag.Size = UDim2.new(T.Tag.X, 24, T.Tag.Y, 6)
			newTag.StudsOffset = Vector3.new(0, tagHeight, 0)
			newTag.LightInfluence = 0
			newTag.MaxDistance = 120
			local label = Instance.new("TextLabel")
			label.Name = "Text"
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.FredokaOne
			label.TextScaled = true
			label.TextStrokeTransparency = 0.35
			label.Parent = newTag
			newTag.Parent = head
			tag = newTag
		end
		local title = if has.Tag
				and pref.Title
				and table.find(Config.Titles, pref.Title)
			then pref.Title
			elseif tip then Config.TipTitle
			else Config.PassTitle
		local color = Config.Colors[if has.Tag then pref.Color or 1 else 1] or Config.Colors[1]
		local label = (tag :: BillboardGui):FindFirstChild("Text") :: TextLabel
		label.Text = `★ {title}`
		label.TextColor3 = color.Color
	end

	local aura = root:FindFirstChild("SupporterAura")
	local glow = root:FindFirstChild("SupporterGlow")
	local wantAura = has.Aura and pref.AuraOff ~= true
	if not wantAura then
		if aura then
			aura:Destroy()
		end
		if glow then
			glow:Destroy()
		end
	elseif not aura then
		local e = Instance.new("ParticleEmitter")
		e.Name = "SupporterAura"
		e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		e.Color = ColorSequence.new(Config.AuraColor)
		e.LightEmission = 1
		e.Rate = T.AuraRate
		e.Lifetime = NumberRange.new(1, 1.6)
		e.Speed = NumberRange.new(0.4, 1.2)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		e.Shape = Enum.ParticleEmitterShape.Box
		e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		e.Parent = root
		local light = Instance.new("PointLight")
		light.Name = "SupporterGlow"
		light.Color = Config.AuraColor
		light.Brightness = T.AuraLight
		light.Range = 8
		light.Parent = root
	end
end

local function checkPasses(p: Player)
	local has = { Aura = false, Tag = false }
	for key, pass in Products.Passes do
		if p:GetAttribute(`Fake{key}`) then
			has[key] = true
		elseif pass.Id ~= 0 then
			local ok, yes = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, p.UserId, pass.Id)
			has[key] = ok and yes == true
		end
	end
	owns[p] = has
end

local function readTotal(id: number): number
	if totals then
		local ok, v = pcall(function()
			return (totals :: OrderedDataStore):GetAsync(tostring(id))
		end)
		return if ok and type(v) == "number" then v else 0
	end
	return memory[id] or 0
end

-- A fresh tip receipt (SupportService) or the admin /supporter test.
function Supporters.Record(userId: number, robux: number): boolean
	if totals then
		local ok, err = pcall(function()
			(totals :: OrderedDataStore):UpdateAsync(tostring(userId), function(old)
				return (old or 0) + robux
			end)
		end)
		if not ok then
			warn("[Supporters] total not saved:", err)
			return false
		end
	else
		memory[userId] = (memory[userId] or 0) + robux
	end
	tipped[userId] = (tipped[userId] or 0) + robux
	local p = Players:GetPlayerByUserId(userId)
	if p then
		dress(p)
	end
	task.spawn(Supporters.Refresh)
	return true
end

-- Show or hide the player's name on the wall + in the credits (their choice, from the thank-you panel).
function Supporters.SetHidden(p: Player, hidden: boolean)
	prefsOf(p.UserId).Hidden = hidden or nil
	savePrefs(p.UserId)
	task.spawn(Supporters.Refresh)
end

local function promptPass(p: Player, key: string): boolean
	local pass = Products.Passes[key]
	if (owns[p] or {})[key] then
		return false
	end
	if pass.Id ~= 0 then
		MarketplaceService:PromptGamePassPurchase(p, pass.Id)
	end
	return true
end

-- Lobby board prompts: cycle the tag color / title (Name Tag pass), toggle the aura (Aura pass); not owned = buy it.
function Supporters.Cycle(p: Player, what: "Color" | "Title" | "Aura")
	if promptPass(p, if what == "Aura" then "Aura" else "Tag") then
		return
	end
	local pref = prefsOf(p.UserId)
	if what == "Color" then
		pref.Color = (pref.Color or 1) % #Config.Colors + 1
	elseif what == "Title" then
		local i = table.find(Config.Titles, pref.Title or "") or 0
		pref.Title = Config.Titles[i % #Config.Titles + 1]
	else
		pref.AuraOff = if pref.AuraOff then nil else true
	end
	savePrefs(p.UserId)
	dress(p)
end

-- Admin test: fake a tip / a pass for this player (Studio: memory only).
function Supporters.Fake(p: Player, what: string)
	if what == "aura" or what == "tag" then
		local key = if what == "aura" then "Aura" else "Tag"
		p:SetAttribute(`Fake{key}`, not p:GetAttribute(`Fake{key}`) or nil)
		checkPasses(p)
		dress(p)
	elseif STUDIO then
		Supporters.Record(p.UserId, 10)
	end
end

local started = false
-- opts.TagHeight: studs over the head (the lobby's role tag sits higher than the adventure's partner tag)
function Supporters.Init(opts: { TagHeight: number? }?)
	if started then
		return
	end
	started = true
	tagHeight = (opts and opts.TagHeight) or T.TagHeight
	local function join(p: Player)
		task.spawn(function()
			checkPasses(p)
			tipped[p.UserId] = readTotal(p.UserId)
			prefsOf(p.UserId)
			dress(p)
		end)
		p.CharacterAdded:Connect(function(character)
			character:WaitForChild("Head", 10)
			character:WaitForChild("HumanoidRootPart", 10)
			dress(p)
		end)
	end
	Players.PlayerAdded:Connect(join)
	for _, p in Players:GetPlayers() do
		join(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		owns[p] = nil
		tipped[p.UserId] = nil
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(p, _, bought)
		if bought then
			checkPasses(p)
			dress(p)
		end
	end)
	publish()
	task.spawn(function()
		while true do
			Supporters.Refresh()
			task.wait(T.Refresh)
		end
	end)
end

-- The wall (user, Oct 18: "polaroid podium"): Kai and Miko's photo wall. The top 3 supporters get big polaroids with
-- gold / silver / bronze star stickers, everyone else small pinned cards in rank order. Each card shows the Robux total
-- (user: so others see what it takes to pass them).
-- A SurfaceGui on `part`'s `face`; opts: Title, PixelsPerStud, Font, Ink (text color), Paper (card color)
local MEDALS = {
	Color3.fromRGB(255, 200, 61), -- gold
	Color3.fromRGB(205, 212, 222), -- silver
	Color3.fromRGB(214, 140, 84), -- bronze
}

function Supporters.Wall(
	part: BasePart,
	face: Enum.NormalId,
	opts: {
		Title: string?,
		PixelsPerStud: number?,
		Font: Enum.Font?,
		Ink: Color3?,
		Paper: Color3?,
		TitleGlow: number?, -- the title on its own self-lit layer at this Brightness (the cards stay scene-lit)
	}?
)
	local o = opts or {}
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SupporterWall"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = o.PixelsPerStud or 20
	gui.LightInfluence = 1 -- lit by the scene only: self-lit white paper glowed in the night (user)
	gui.Parent = part
	local font = o.Font or Enum.Font.PermanentMarker
	local ink = o.Ink or Color3.fromRGB(40, 32, 28)
	local paper = o.Paper or Color3.fromRGB(226, 216, 196)

	local head = Instance.new("TextLabel")
	head.Size = UDim2.fromScale(1, 0.12)
	head.BackgroundTransparency = 1
	head.Font = font
	head.TextScaled = true
	head.TextColor3 = MEDALS[1]
	head.TextStrokeTransparency = 0.4
	head.Text = o.Title or "★ THANK YOU, SUPPORTERS ★"
	head.Parent = gui
	if o.TitleGlow then
		local glowGui = Instance.new("SurfaceGui")
		glowGui.Name = "SupporterTitle"
		glowGui.Face = face
		glowGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		glowGui.PixelsPerStud = gui.PixelsPerStud
		glowGui.LightInfluence = 0
		glowGui.Brightness = o.TitleGlow
		glowGui.Parent = part
		head.Parent = glowGui
		local halo = Instance.new("UIStroke") -- a soft gold rim round the letters
		halo.Color = MEDALS[1]
		halo.Transparency = 0.55
		halo.Thickness = 3
		halo.Parent = head
	end

	local board = Instance.new("Frame")
	board.Position = UDim2.fromScale(0, 0.13)
	board.Size = UDim2.fromScale(1, 0.87)
	board.BackgroundTransparency = 1
	board.Parent = gui

	local rng = Random.new(18)
	-- one photo: a white frame (photo square + a name strip under it), a pin, and for the top 3 a star sticker
	local function photo(e: Entry, rank: number, center: Vector2, height: number, big: boolean)
		local card = Instance.new("Frame")
		card.AnchorPoint = Vector2.new(0.5, 0)
		card.Position = UDim2.fromScale(center.X, center.Y)
		card.Size = UDim2.fromScale(1, height) -- the aspect ratio below sets the width from this height
		card.BackgroundColor3 = paper
		card.BorderSizePixel = 0
		card.Rotation = rng:NextNumber(-5, 5)
		card.Parent = board
		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 0.84
		aspect.DominantAxis = Enum.DominantAxis.Height
		aspect.Parent = card
		local shadow = Instance.new("UIStroke")
		shadow.Color = Color3.new(0, 0, 0)
		shadow.Transparency = 0.75
		shadow.Thickness = 2
		shadow.Parent = card
		local pic = Instance.new("ImageLabel")
		pic.AnchorPoint = Vector2.new(0.5, 0)
		pic.Position = UDim2.fromScale(0.5, 0.07)
		pic.Size = UDim2.fromScale(0.86, 0.64)
		pic.BackgroundColor3 = Color3.fromRGB(58, 64, 92) -- night-sky backdrop behind the headshot
		pic.BorderSizePixel = 0
		pic.Image = `rbxthumb://type=AvatarHeadShot&id={e.UserId}&w=150&h=150`
		pic.ScaleType = Enum.ScaleType.Crop
		pic.Parent = card
		local name = Instance.new("TextLabel")
		name.Position = UDim2.fromScale(0.05, 0.72)
		name.Size = UDim2.fromScale(0.9, 0.15)
		name.BackgroundTransparency = 1
		name.Font = font
		name.TextScaled = true
		name.TextColor3 = ink
		name.Text = e.Name
		name.Parent = card
		local robux = Instance.new("TextLabel")
		robux.Position = UDim2.fromScale(0.1, 0.87)
		robux.Size = UDim2.fromScale(0.8, 0.11)
		robux.BackgroundTransparency = 1
		robux.Font = Enum.Font.FredokaOne
		robux.TextScaled = true
		robux.TextColor3 = Color3.fromRGB(170, 120, 20)
		robux.Text = `{e.Total} R$`
		robux.Parent = card
		if big then
			local sticker = Instance.new("TextLabel")
			sticker.AnchorPoint = Vector2.new(0.5, 0.5)
			sticker.Position = UDim2.fromScale(0.92, 0.06)
			sticker.Size = UDim2.fromScale(0.34, 0.34)
			sticker.SizeConstraint = Enum.SizeConstraint.RelativeXX
			sticker.BackgroundTransparency = 1
			sticker.Font = Enum.Font.FredokaOne
			sticker.TextScaled = true
			sticker.TextColor3 = MEDALS[rank]
			sticker.TextStrokeTransparency = 0.2
			sticker.Text = "★"
			sticker.Rotation = 12
			sticker.Parent = card
			local num = Instance.new("TextLabel")
			num.AnchorPoint = Vector2.new(0.5, 0.5)
			num.Position = UDim2.fromScale(0.5, 0.56)
			num.Size = UDim2.fromScale(0.42, 0.42)
			num.BackgroundTransparency = 1
			num.Font = Enum.Font.FredokaOne
			num.TextScaled = true
			num.TextColor3 = ink
			num.Text = tostring(rank)
			num.Parent = sticker
		else
			local pin = Instance.new("Frame")
			pin.AnchorPoint = Vector2.new(0.5, 0.5)
			pin.Position = UDim2.fromScale(0.5, 0.02)
			pin.Size = UDim2.fromScale(0.12, 0.12)
			pin.SizeConstraint = Enum.SizeConstraint.RelativeXX
			pin.BackgroundColor3 = Config.Colors[3].Color
			pin.BorderSizePixel = 0
			pin.Parent = card
			local round = Instance.new("UICorner")
			round.CornerRadius = UDim.new(0.5, 0)
			round.Parent = pin
		end
	end

	-- podium spots (centre x, top y, height; fractions of the board): #1 middle and highest, #2 left, #3 right
	local PODIUM = {
		{ Vector2.new(0.5, 0.0), 0.52 },
		{ Vector2.new(0.27, 0.08), 0.44 },
		{ Vector2.new(0.73, 0.08), 0.44 },
	}
	local function draw(entries: { Entry })
		for _, c in board:GetChildren() do
			c:Destroy()
		end
		if #entries == 0 then
			local empty = Instance.new("TextLabel")
			empty.Size = UDim2.fromScale(1, 0.7)
			empty.BackgroundTransparency = 1
			empty.Font = font
			empty.TextScaled = true
			empty.TextColor3 = paper
			empty.TextStrokeTransparency = 0.5
			empty.Text = "No supporters yet.\nSupport us at the end of the story\nand your photo goes up here!"
			empty.Parent = board
			return
		end
		for rank = 1, math.min(3, #entries) do
			photo(entries[rank], rank, PODIUM[rank][1], PODIUM[rank][2], true)
		end
		-- the rest: rows of small cards under the podium, in rank order
		local rest = #entries - 3
		local perRow = 10
		for i = 1, math.max(0, rest) do
			local row = (i - 1) // perRow
			local col = (i - 1) % perRow
			local inRow = math.min(perRow, rest - row * perRow)
			local x = 0.5 + (col - (inRow - 1) / 2) * (1 / perRow)
			photo(entries[i + 3], i + 3, Vector2.new(x, 0.6 + row * 0.2), 0.18, false)
		end
	end
	draw(list)
	Supporters.Changed:Connect(draw)
	return gui
end

return Supporters
