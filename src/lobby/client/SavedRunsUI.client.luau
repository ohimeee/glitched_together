-- Saved runs in the lobby (user pick Oct 17: a save-file menu + a card pop-up invite). The SAVED RUNS (n) button
-- opens one memory-card slot per partner (avatar, world, checkpoint, your role, online dot): CONTINUE when the
-- partner is in this lobby (they get a YES / NO card), INVITE when not (Roblox invite to that friend). While a pair
-- with a save stands in the capsules, both see a CONTINUE / NEW GAME chip: NEW GAME only happens if both press it.
-- Server side: SavedRuns.server.luau + Capsules.server.luau.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage.Shared.Net)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local Roles = require(ReplicatedStorage.Shared.Config.Roles)
local Worlds = require(ReplicatedStorage.Shared.Config.Worlds)
local UiSkin = require(ReplicatedStorage.Shared.Util.UiSkin)
local UiFit = require(ReplicatedStorage.Shared.Util.UiFit)
local Glyphs = require(ReplicatedStorage.Shared.Util.Glyphs)

local player = Players.LocalPlayer

local GREEN = Color3.fromRGB(40, 170, 90)
local GREY = Color3.fromRGB(120, 124, 150)
local GOLD = Color3.fromRGB(255, 200, 70)
local PINK = Palette.Prologue.Pink

local gui = Instance.new("ScreenGui")
gui.Name = "SavedRunsUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")
local fitScale = UiFit.attach(gui) -- the button stack lines up with LobbyUI's (same scale)
local TOUCH = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- gamepad: menus put the selection on their first button (console pass)
local function padSelect(): boolean
	return Glyphs.device() == "Gamepad" or GuiService:IsTenFootInterface()
end

local function label(
	parent: Instance,
	text: string,
	kind: UiSkin.TextKind,
	pos: UDim2,
	size: UDim2,
	color: Color3?
): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = pos
	t.Size = size
	t.Text = text
	t.TextScaled = true
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.ZIndex = 12
	t.Parent = parent
	UiSkin.Text(t, kind, color)
	return t
end

local function button(parent: Instance, text: string, fill: Color3, pos: UDim2, size: UDim2, z: number?): TextButton
	local b = Instance.new("TextButton")
	b.Position = pos
	b.Size = size
	b.Text = text
	b.TextScaled = true
	b.AutoButtonColor = true
	b.ZIndex = z or 13
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 7)
	pad.PaddingBottom = UDim.new(0, 7)
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = b
	b.Parent = parent
	UiSkin.Panel(b, { Fill = fill })
	UiSkin.Text(b, "Title", UiSkin.InkOn(fill))
	b.MouseEnter:Connect(function()
		b.Rotation = -2
	end)
	b.MouseLeave:Connect(function()
		b.Rotation = 0
	end)
	return b
end

local function scaleToScreen(frame: GuiObject, width: number)
	local scale = Instance.new("UIScale") -- phones: shrink with the screen
	scale.Parent = frame
	local function fit()
		local view = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		-- the panel's own fit, on top of the whole gui's UiFit (so the two don't shrink it twice)
		scale.Scale = math.clamp(math.min(view.X / (width + 40), view.Y / 640), 0.5, 1) / math.max(fitScale.Scale, 0.01)
	end
	fit()
	fitScale:GetPropertyChangedSignal("Scale"):Connect(fit)
	if workspace.CurrentCamera then
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)
	end
end

-- Toast: short notices from the server ("Asked Ben...").
local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -120)
toast.Size = UDim2.fromOffset(420, 46)
toast.TextScaled = true
toast.Visible = false
toast.ZIndex = 30
local toastPad = Instance.new("UIPadding")
toastPad.PaddingTop = UDim.new(0, 8)
toastPad.PaddingBottom = UDim.new(0, 8)
toastPad.Parent = toast
toast.Parent = gui
UiSkin.Panel(toast)
UiSkin.Text(toast, "Title")
local toastId = 0
local function showToast(text: string)
	toastId += 1
	local mine = toastId
	toast.Text = text
	toast.Visible = true
	task.delay(3, function()
		if toastId == mine then
			toast.Visible = false
		end
	end)
end
Net.event("RunInviteStatus").OnClientEvent:Connect(showToast)

local function whereText(world: string, checkpoint: number, complete: boolean?): string
	if complete then
		return "★ FINISHED"
	end
	local info = Worlds.ByName[world]
	return `{if info then info.Title else world} · Checkpoint {checkpoint}`
end

local function agoText(t: number): string
	local days = math.floor((os.time() - t) / 86400)
	if days <= 0 then
		return "today"
	elseif days == 1 then
		return "yesterday"
	end
	return `{days} days ago`
end

-- ── The save-file menu ──────────────────────────────────────────────────────────────────────────────────────────
local MENU_W, SLOT_H = 540, 118

local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.Position = UDim2.fromScale(0.5, 0.5)
menu.Size = UDim2.fromOffset(MENU_W, 470)
menu.Visible = false
menu.ZIndex = 10
menu.Parent = gui
UiSkin.Panel(menu)
scaleToScreen(menu, MENU_W)

label(menu, "SAVED RUNS", "Title", UDim2.fromOffset(22, 14), UDim2.new(1, -110, 0, 38))
label(
	menu,
	"One save per partner. Continue together when they're here.",
	"Sub",
	UDim2.fromOffset(22, 54),
	UDim2.new(1, -44, 0, 20)
)
local close = button(menu, "X", PINK, UDim2.new(1, -62, 0, 14), UDim2.fromOffset(44, 40))

local list = Instance.new("ScrollingFrame")
list.Position = UDim2.fromOffset(16, 86)
list.Size = UDim2.new(1, -32, 1, -102)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 6
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.ZIndex = 11
list.Parent = menu
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 12)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list
local listPad = Instance.new("UIPadding")
listPad.PaddingTop = UDim.new(0, 4)
listPad.PaddingLeft = UDim.new(0, 4)
listPad.PaddingRight = UDim.new(0, 12)
listPad.PaddingBottom = UDim.new(0, 10)
listPad.Parent = list

local openButton =
	button(gui, "SAVED RUNS", Color3.fromRGB(70, 90, 200), UDim2.new(1, -16, 1, -74), UDim2.fromOffset(210, 52), 2)
openButton.AnchorPoint = Vector2.new(1, 1)
if TOUCH then -- LobbyUI's stack moves to the top right on phones (the jump button's corner)
	openButton.AnchorPoint = Vector2.new(1, 0)
	openButton.Position = UDim2.new(1, -16, 0, 60 + 58)
end

local runs: { any } = {}
local firstAction: GuiObject? = nil

local function slot(e: any, index: number)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -8, 0, SLOT_H)
	card.LayoutOrder = index
	card.ZIndex = 12
	card.Parent = list
	UiSkin.Panel(card, { Fill = Color3.fromRGB(36, 44, 98), NoShadow = true })

	-- the partner's avatar in a small square "memory card" window
	local face = Instance.new("ImageLabel")
	face.Position = UDim2.fromOffset(12, 12)
	face.Size = UDim2.fromOffset(SLOT_H - 24, SLOT_H - 24)
	face.BackgroundColor3 = Color3.fromRGB(24, 28, 64)
	face.ZIndex = 13
	face.Parent = card
	local faceCorner = Instance.new("UICorner")
	faceCorner.CornerRadius = UDim.new(0, 8)
	faceCorner.Parent = face
	task.spawn(function()
		local ok, image = pcall(function()
			return Players:GetUserThumbnailAsync(e.partner, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok then
			face.Image = image
		end
	end)

	local x = SLOT_H - 2
	label(card, `FILE {index}`, "Sub", UDim2.fromOffset(x, 10), UDim2.fromOffset(80, 16))
	label(card, e.name, "Title", UDim2.fromOffset(x, 26), UDim2.new(1, -x - 150, 0, 30))
	-- online dot + text, top right
	label(
		card,
		if e.online then "● IN LOBBY" else "○ offline",
		"Body",
		UDim2.new(1, -140, 0, 12),
		UDim2.fromOffset(126, 20),
		if e.online then Color3.fromRGB(110, 230, 140) else GREY
	).TextXAlignment =
		Enum.TextXAlignment.Right
	-- row 3: where the run is (full width up to the button); row 4: your role · when
	local textW = UDim2.new(1, -x - 172, 0, 22)
	label(
		card,
		whereText(e.world, e.checkpoint, e.complete),
		"Body",
		UDim2.fromOffset(x, 58),
		textW,
		if e.complete then GOLD else nil
	)
	local role = (Roles :: any)[e.role]
	local who = if role then `{if role.Shape == "Triangle" then "▲" else "●"} you: {role.Label}  ·  ` else ""
	label(
		card,
		`{who}last played {agoText(e.t or 0)}`,
		"Sub",
		UDim2.fromOffset(x, 86),
		textW,
		if role then role.Color else nil
	)

	local act = button(
		card,
		if e.online then "CONTINUE ▶" else "INVITE ✉",
		if e.online then GREEN else PINK,
		UDim2.new(1, -164, 0.5, -10),
		UDim2.fromOffset(150, 44)
	)
	act.Activated:Connect(function()
		if e.online then
			Net.event("RunInvite"):FireServer(e.partner)
			return
		end
		local ok, canInvite = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
		if not (ok and canInvite) then
			showToast("Invites aren't available here.")
			return
		end
		local options = Instance.new("ExperienceInviteOptions")
		options.InviteUser = e.partner
		options.PromptMessage = `Continue our run: {whereText(e.world, e.checkpoint, e.complete)}`
		pcall(SocialService.PromptGameInvite, SocialService, player, options)
	end)
	if index == 1 then
		firstAction = act
	end
end

local function render()
	for _, c in list:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	firstAction = nil
	local key = if padSelect() then "  [Y]" else "" -- the gamepad shortcut
	openButton.Text = (if #runs > 0 then `SAVED RUNS ({#runs})` else "SAVED RUNS") .. key
	if #runs == 0 then
		local empty = label(
			list,
			"No saved runs yet. Step into the capsules with a friend!",
			"Body",
			UDim2.new(),
			UDim2.new(1, -8, 0, 60)
		)
		empty.TextWrapped = true
		empty.TextXAlignment = Enum.TextXAlignment.Center
		return
	end
	for i, e in runs do
		slot(e, i)
	end
end

local function setMenu(open: boolean)
	menu.Visible = open
	if open then
		menu.Position = UDim2.new(0.5, 0, 0.5, 20)
		TweenService:Create(menu, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Position = UDim2.fromScale(0.5, 0.5) })
			:Play()
		if padSelect() or GuiService.SelectedObject ~= nil then
			GuiService.SelectedObject = firstAction or close
		end
	elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(menu) then
		GuiService.SelectedObject = nil
	end
end
openButton.Activated:Connect(function()
	setMenu(not menu.Visible)
end)
close.Activated:Connect(function()
	setMenu(false)
end)
-- gamepad: Y opens / closes the menu (no cursor to reach the button), B closes it
UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.ButtonY and not processed then
		setMenu(not menu.Visible)
	elseif input.KeyCode == Enum.KeyCode.ButtonB and menu.Visible then
		setMenu(false)
	end
end)

Net.event("SavedRuns").OnClientEvent:Connect(function(list: { any })
	runs = list
	render()
end)
Glyphs.Changed:Connect(render)
render()

-- ── The invite card ("Ana wants to continue") ───────────────────────────────────────────────────────────────────
local offer = Instance.new("Frame")
offer.AnchorPoint = Vector2.new(0.5, 0.5)
offer.Position = UDim2.fromScale(0.5, 0.42)
offer.Size = UDim2.fromOffset(420, 190)
offer.Visible = false
offer.ZIndex = 20
offer.Parent = gui
UiSkin.Panel(offer)
scaleToScreen(offer, 420)
local offerTitle = label(offer, "", "Title", UDim2.fromOffset(22, 18), UDim2.new(1, -44, 0, 34))
offerTitle.ZIndex = 21
local offerWhere = label(offer, "", "Body", UDim2.fromOffset(22, 58), UDim2.new(1, -44, 0, 26))
offerWhere.ZIndex = 21
local yes = button(offer, "YES, LET'S GO", GREEN, UDim2.new(0, 22, 1, -70), UDim2.fromOffset(230, 48), 22)
local no = button(offer, "NO", GREY, UDim2.new(1, -142, 1, -70), UDim2.fromOffset(120, 48), 22)
local offerFrom: number? = nil
local offerId = 0

local function closeOffer(accepted: boolean?)
	if offerFrom and accepted ~= nil then
		Net.event("RunInviteReply"):FireServer(offerFrom, accepted)
	end
	offerFrom = nil
	offer.Visible = false
end
yes.Activated:Connect(function()
	closeOffer(true)
end)
no.Activated:Connect(function()
	closeOffer(false)
end)

Net.event("RunInviteOffer").OnClientEvent
	:Connect(function(fromId: number, name: string, world: string, checkpoint: number, complete: boolean)
		offerId += 1
		local mine = offerId
		offerFrom = fromId
		offerTitle.Text = `{name} wants to continue`
		offerWhere.Text = string.upper(whereText(world, checkpoint, complete))
		offer.Visible = true
		offer.Size = UDim2.fromOffset(380, 170)
		TweenService:Create(offer, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(420, 190) })
			:Play()
		if padSelect() or GuiService.SelectedObject ~= nil then
			GuiService.SelectedObject = yes
		end
		task.delay(30, function()
			if offerId == mine and offer.Visible then
				closeOffer(nil) -- ran out: the server drops it too
			end
		end)
	end)

-- ── Capsule chip: CONTINUE / NEW GAME while a pair with a save stands in the capsules ───────────────────────────
local chip = Instance.new("Frame")
chip.AnchorPoint = Vector2.new(0.5, 1)
chip.Position = UDim2.new(0.5, 0, 1, -24)
chip.Size = UDim2.fromOffset(500, 132)
chip.Visible = false
chip.ZIndex = 15
chip.Parent = gui
UiSkin.Panel(chip)
scaleToScreen(chip, 500)
local chipTitle = label(chip, "", "Body", UDim2.fromOffset(20, 12), UDim2.new(1, -40, 0, 22))
chipTitle.ZIndex = 16
local keep = button(chip, "", GREEN, UDim2.new(0, 20, 1, -66), UDim2.fromOffset(220, 50), 17)
local fresh = button(chip, "", GREY, UDim2.new(1, -240, 1, -66), UDim2.fromOffset(220, 50), 17)
keep.Activated:Connect(function()
	Net.event("CapsuleNewGame"):FireServer(false)
end)
fresh.Activated:Connect(function()
	Net.event("CapsuleNewGame"):FireServer(true)
end)

local function syncChip()
	local save = player:GetAttribute("SeatSave") :: string?
	local was = chip.Visible
	chip.Visible = save ~= nil
	if not save then
		if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(chip) then
			GuiService.SelectedObject = nil
		end
		return
	end
	if not was and padSelect() and GuiService.SelectedObject == nil then
		GuiService.SelectedObject = keep -- seated with a gamepad: A = CONTINUE, right = NEW GAME
	end
	local votes = (player:GetAttribute("SeatVotes") or 0) :: number
	local mine = player:GetAttribute("SeatMyVote") == true
	chipTitle.Text = `YOUR RUN WITH {string.upper((player:GetAttribute("SeatPartner") or "PARTNER") :: string)}: {save}`
	keep.Text = if mine then "CONTINUE" else "CONTINUE ✓"
	fresh.Text = if votes >= 2 then "NEW GAME ✓✓" else if mine then "NEW GAME ✓ (1/2)" else `NEW GAME ({votes}/2)`
	-- the lobby theme never changes, so the picked side's fill can be set directly
	keep.BackgroundColor3 = if mine then GREY else GREEN
	fresh.BackgroundColor3 = if mine then PINK else GREY
end
for _, a in { "SeatSave", "SeatPartner", "SeatVotes", "SeatMyVote" } do
	player:GetAttributeChangedSignal(a):Connect(syncChip)
end
syncChip()
