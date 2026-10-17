-- Card reveal (memory card-reveal-ui; user, Oct 5: a TikTok anime card reveal, "we could use that"): sealed cards
-- drop in, flip open over a burst of light rays and sparkles, a holo shine sweeps across them, they tilt toward the
-- cursor, and the picked card pops while the others fall away. Reusable: the castle level-up picker first (HUD),
-- later boss title cards, Memory unlocks, cosmetics. All code-drawn (no images): rays are thin gradient frames, the
-- art window holds a big glyph. Theme fonts follow the world (UiSkin); `accent` is the owner's color.
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UiSkin = require(game:GetService("ReplicatedStorage").Shared.Util.UiSkin)
local Audio = require(game:GetService("ReplicatedStorage").Shared.Util.Audio)

local CardReveal = {}

export type Card = {
	id: string,
	name: string,
	desc: string,
	icon: string, -- a glyph / emoji drawn big in the art window
	ribbon: string?, -- the tag over the top-left corner ("UPGRADE")
	stars: number?,
}

export type Opts = {
	title: string,
	accent: Color3, -- glow, rays, border
	back: Color3, -- card back / frame fill
	gold: Color3, -- stars, ribbon, title
	cards: { Card },
	onPick: (id: string) -> (),
	zIndex: number?,
}

local CARD = Vector2.new(230, 330)
local GAP = 290 -- centre to centre
local RAYS = 14

local function new(className: string, props: { [string]: any }, parent: Instance?): any
	local inst = Instance.new(className)
	for k, v in props do
		(inst :: any)[k] = v
	end
	inst.Parent = parent
	return inst
end

local function tween(
	inst: Instance,
	t: number,
	props: { [string]: any },
	style: Enum.EasingStyle?,
	dir: Enum.EasingDirection?
)
	local tw = TweenService:Create(
		inst,
		TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
		props
	)
	tw:Play()
	return tw
end

local function round(parent: Instance, r: number)
	new("UICorner", { CornerRadius = UDim.new(0, r) }, parent)
end

-- A soft sunburst behind a card: thin bars through the centre, each fading toward both ends.
local function rays(parent: Instance, color: Color3, z: number): Frame
	local holder = new("Frame", {
		Name = "Rays",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(620, 620),
		BackgroundTransparency = 1,
		ZIndex = z,
	}, parent)
	for i = 1, RAYS do
		local bar = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(0, if i % 2 == 0 then 22 else 40, 1, 0),
			Rotation = (i - 1) / RAYS * 180,
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = z,
		}, holder)
		new("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.35),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}, bar)
	end
	return holder
end

local function sparkles(parent: Instance, at: UDim2, color: Color3, z: number)
	for _ = 1, 16 do
		local a = math.random() * math.pi * 2
		local d = 120 + math.random() * 140
		local s = new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = at,
			Size = UDim2.fromOffset(28, 28),
			BackgroundTransparency = 1,
			Text = if math.random() < 0.5 then "✦" else "✧",
			TextColor3 = if math.random() < 0.4 then Color3.new(1, 1, 1) else color,
			TextScaled = true,
			Font = Enum.Font.GothamBold,
			Rotation = math.random(0, 90),
			ZIndex = z,
		}, parent)
		local t = 0.6 + math.random() * 0.5
		tween(s, t, {
			Position = at + UDim2.fromOffset(math.cos(a) * d, math.sin(a) * d),
			Rotation = s.Rotation + 180,
			TextTransparency = 1,
			Size = UDim2.fromOffset(10, 10),
		}, Enum.EasingStyle.Quart)
		task.delay(t, function()
			s:Destroy()
		end)
	end
end

-- Opens the reveal. Returns a close function (also called after a pick).
function CardReveal.Show(parent: Instance, o: Opts): () -> ()
	local z = o.zIndex or 40
	local alive = true
	local conns: { RBXScriptConnection } = {}
	local root = new("Frame", {
		Name = "CardReveal",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 1,
		ZIndex = z,
	}, parent)
	tween(root, 0.35, { BackgroundTransparency = 0.45 })

	local title = new("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, -CARD.Y / 2 - 70),
		Size = UDim2.fromOffset(700, 64),
		BackgroundTransparency = 1,
		Text = o.title,
		TextSize = 46,
		ZIndex = z + 9,
	}, root)
	UiSkin.Text(title, "Title", o.gold)
	local titleScale = new("UIScale", { Scale = 0.4 }, title)
	tween(titleScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)

	local closed = false
	local function close()
		if closed then
			return
		end
		closed = true
		alive = false
		for _, c in conns do
			c:Disconnect()
		end
		if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(root) then
			GuiService.SelectedObject = nil
		end
		tween(root, 0.3, { BackgroundTransparency = 1 })
		for _, d in root:GetDescendants() do
			if d:IsA("GuiObject") then
				local props: { [string]: any } = {}
				if d.BackgroundTransparency < 1 then
					props.BackgroundTransparency = 1
				end
				if d:IsA("TextLabel") or d:IsA("TextButton") then
					props.TextTransparency = 1
				end
				if next(props) then
					tween(d, 0.25, props)
				end
			elseif d:IsA("UIStroke") then
				tween(d, 0.25, { Transparency = 1 })
			end
		end
		task.delay(0.35, function()
			root:Destroy()
		end)
	end

	local n = #o.cards
	local slots: { { holder: Frame, button: TextButton, rays: Frame, shine: UIGradient, tiltTarget: number, lift: number } } =
		{}
	local picked = false
	for i, card in o.cards do
		local x = (i - (n + 1) / 2) * GAP
		local pos = UDim2.new(0.5, x, 0.5, 20)
		local holder = new("Frame", {
			Name = "Card" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = pos - UDim2.fromOffset(0, 420),
			Size = UDim2.fromOffset(CARD.X, CARD.Y),
			BackgroundTransparency = 1,
			ZIndex = z + 1,
		}, root)
		local cardRays = rays(holder, o.accent, z + 1)
		cardRays.Visible = false
		local glow = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(CARD.X + 70, CARD.Y + 70),
			BackgroundColor3 = o.accent,
			BackgroundTransparency = 0.82,
			ZIndex = z + 2,
		}, holder)
		round(glow, 48)

		-- the face (and the back: same frame, its contents swap at the flip's midpoint)
		local face = new("Frame", {
			Name = "Face",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = o.back,
			ClipsDescendants = true,
			ZIndex = z + 3,
		}, holder)
		round(face, 18)
		local stroke = new("UIStroke", { Color = o.accent, Thickness = 5, Transparency = 0 }, face)

		local backSide =
			new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = z + 4 }, face)
		new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(o.back:Lerp(o.accent, 0.25), o.back:Lerp(Color3.new(0, 0, 0), 0.4)),
		}, face)
		local mark = new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
			Size = UDim2.fromOffset(150, 150),
			BackgroundTransparency = 1,
			Text = "?",
			TextScaled = true,
			ZIndex = z + 5,
		}, backSide)
		UiSkin.Text(mark, "Title", o.gold)
		local backTag = new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -22),
			Size = UDim2.fromOffset(200, 30),
			BackgroundTransparency = 1,
			Text = card.ribbon or "UPGRADE",
			TextSize = 24,
			ZIndex = z + 5,
		}, backSide)
		UiSkin.Text(backTag, "Title", o.gold)

		local front = new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Visible = false,
			ZIndex = z + 4,
		}, face)
		local art = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 16),
			Size = UDim2.new(1, -28, 0, 150),
			BackgroundColor3 = o.accent,
			ZIndex = z + 5,
		}, front)
		round(art, 12)
		new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(o.accent:Lerp(Color3.new(1, 1, 1), 0.25), o.back:Lerp(Color3.new(0, 0, 0), 0.5)),
		}, art)
		new("UIStroke", { Color = o.gold, Thickness = 2, Transparency = 0.2 }, art)
		local icon = new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.52),
			Size = UDim2.fromOffset(110, 110),
			BackgroundTransparency = 1,
			Text = card.icon,
			TextScaled = true,
			Font = Enum.Font.GothamBold,
			TextColor3 = Color3.new(1, 1, 1),
			ZIndex = z + 6,
		}, art)
		local iconScale = new("UIScale", { Scale = 1 }, icon)
		local ribbon = new("TextLabel", {
			Position = UDim2.fromOffset(-30, 12),
			Size = UDim2.fromOffset(130, 26),
			Rotation = -30,
			BackgroundColor3 = o.gold,
			Text = card.ribbon or "UPGRADE",
			TextSize = 15,
			ZIndex = z + 8,
		}, front)
		UiSkin.Text(ribbon, "Title", UiSkin.InkOn(o.gold))
		local name = new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 172),
			Size = UDim2.new(1, -20, 0, 34),
			BackgroundTransparency = 1,
			Text = card.name,
			TextScaled = true,
			ZIndex = z + 6,
		}, front)
		UiSkin.Text(name, "Title", o.gold)
		new("UITextSizeConstraint", { MaxTextSize = 28 }, name)
		local stars = new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 206),
			Size = UDim2.new(1, -20, 0, 24),
			BackgroundTransparency = 1,
			Text = string.rep("★", card.stars or 1),
			TextSize = 22,
			Font = Enum.Font.GothamBold,
			TextColor3 = o.gold,
			ZIndex = z + 6,
		}, front)
		stars.Name = "Stars" -- keeps GothamBold: the pixel / code fonts miss the ★ glyph
		local desc = new("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 236),
			Size = UDim2.new(1, -28, 0, 80),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.6,
			Text = card.desc,
			TextWrapped = true,
			TextSize = 20,
			ZIndex = z + 6,
		}, front)
		round(desc, 8)
		UiSkin.Text(desc, "Body", Color3.new(1, 1, 1))

		-- the holo shine: a bright diagonal band that sweeps across the whole card
		local shineFrame = new("Frame", {
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.55,
			ZIndex = z + 9,
		}, face)
		local shine = new("UIGradient", {
			Rotation = 25,
			Offset = Vector2.new(-1.2, 0),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.42, 1),
				NumberSequenceKeypoint.new(0.5, 0.2),
				NumberSequenceKeypoint.new(0.58, 1),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}, shineFrame)

		local button = new("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			Selectable = true,
			Active = false,
			ZIndex = z + 10,
		}, holder)
		local slot = { holder = holder, button = button, rays = cardRays, shine = shine, tiltTarget = 0, lift = 0 }
		slots[i] = slot

		-- drop in, sealed; then flip open
		task.delay(0.12 * (i - 1), function()
			if not alive then
				return
			end
			tween(holder, 0.5, { Position = pos }, Enum.EasingStyle.Back)
			Audio.play("Hover")
		end)
		task.delay(0.75 + 0.3 * (i - 1), function()
			if not alive then
				return
			end
			local half =
				tween(face, 0.14, { Size = UDim2.fromScale(0, 1) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			half.Completed:Wait()
			if not alive then
				return
			end
			backSide.Visible = false
			front.Visible = true
			tween(face, 0.2, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Back)
			cardRays.Visible = true
			cardRays.Size = UDim2.fromOffset(120, 120)
			tween(cardRays, 0.5, { Size = UDim2.fromOffset(620, 620) }, Enum.EasingStyle.Quart)
			tween(glow, 0.5, { BackgroundTransparency = 0.6 })
			stroke.Thickness = 9
			tween(stroke, 0.5, { Thickness = 5 })
			iconScale.Scale = 0.3
			tween(iconScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
			sparkles(root, pos, o.accent, z + 11)
			Audio.play("Select")
			button.Active = true
			if i == 1 and UserInputService.GamepadEnabled then
				GuiService.SelectedObject = button
			end
		end)

		table.insert(
			conns,
			button.MouseEnter:Connect(function()
				if not picked then
					slot.lift = 1
					Audio.play("Hover")
				end
			end)
		)
		table.insert(
			conns,
			button.MouseLeave:Connect(function()
				slot.lift = 0
				slot.tiltTarget = 0
			end)
		)
		table.insert(
			conns,
			button.SelectionGained:Connect(function()
				slot.lift = 1
			end)
		)
		table.insert(
			conns,
			button.SelectionLost:Connect(function()
				slot.lift = 0
			end)
		)
		table.insert(
			conns,
			button.Activated:Connect(function()
				if picked or not button.Active then
					return
				end
				picked = true
				Audio.play("Select")
				for j, other in slots do
					if j == i then
						local scale = other.holder:FindFirstChild("Lift")
							or new("UIScale", { Name = "Lift", Scale = 1 }, other.holder)
						tween(scale, 0.3, { Scale = 1.15 }, Enum.EasingStyle.Back)
						other.holder.Rotation = 0
						sparkles(root, other.holder.Position, o.accent, z + 11)
					else
						tween(
							other.holder,
							0.4,
							{ Position = other.holder.Position + UDim2.fromOffset(0, 500), Rotation = (j - i) * 20 },
							Enum.EasingStyle.Back,
							Enum.EasingDirection.In
						)
					end
				end
				task.delay(0.55, function()
					close()
					o.onPick(card.id)
				end)
			end)
		)
	end

	-- every frame: rays turn, shine sweeps, cards tilt toward the cursor and lift while hovered
	local t0 = os.clock()
	table.insert(
		conns,
		RunService.RenderStepped:Connect(function(dt)
			local now = os.clock() - t0
			local mouse = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
			for i, slot in slots do
				slot.rays.Rotation += dt * 12 * (if i % 2 == 0 then -1 else 1)
				local sweep = ((now + i * 0.6) % 2.6) / 2.6
				slot.shine.Offset = Vector2.new(-1.2 + 2.4 * sweep, 0)
				if not picked then
					local h = slot.holder
					local centre = h.AbsolutePosition + h.AbsoluteSize / 2
					if slot.lift > 0 then
						slot.tiltTarget = math.clamp((mouse.X - centre.X) / (CARD.X / 2), -1, 1) * 6
					end
					h.Rotation += (slot.tiltTarget - h.Rotation) * math.min(1, dt * 10)
					local s = h:FindFirstChild("Lift") :: UIScale?
					if not s then
						s = new("UIScale", { Name = "Lift", Scale = 1 }, h)
					end
					local target = 1 + 0.06 * slot.lift;
					(s :: UIScale).Scale += (target - (s :: UIScale).Scale) * math.min(1, dt * 12)
				end
			end
		end)
	)
	return close
end

return CardReveal
