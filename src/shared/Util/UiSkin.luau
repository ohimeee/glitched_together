-- Client-side UI skinning (UiTheme). Register panels and text once; they re-skin live whenever the world changes
-- (workspace attribute "World", set by WorldService). A panel becomes a "sticker": outline (UIStroke), corner
-- (UICorner, 0 = pixel square) and a hard drop shadow (a sibling Frame that follows the panel).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UiTheme = require(ReplicatedStorage.Shared.Config.UiTheme)

export type TextKind = "Body" | "Title" | "Sub" | "Float" | "Hand"
type PanelOpts = { Fill: Color3?, NoShadow: boolean?, Stroke: Color3? }

local UiSkin = {}

local panels: { [GuiObject]: PanelOpts } = {}
local texts: { [GuiObject]: { kind: TextKind, color: Color3? } } = {}
local shadows: { [GuiObject]: Frame } = {}
local listeners: { (UiTheme.Theme) -> () } = {}

function UiSkin.Theme(): UiTheme.Theme
	return UiTheme.For(workspace:GetAttribute("World"))
end

local function ensure(parent: Instance, className: string): any
	local found = parent:FindFirstChildOfClass(className)
	if found then
		return found
	end
	local inst = Instance.new(className)
	inst.Parent = parent
	return inst
end

local function syncShadow(panel: GuiObject, shadow: Frame, theme: UiTheme.Theme)
	shadow.AnchorPoint = panel.AnchorPoint
	shadow.Size = panel.Size
	shadow.Position = panel.Position + UDim2.fromOffset(theme.ShadowOffset, theme.ShadowOffset)
	shadow.Rotation = panel.Rotation
	shadow.Visible = panel.Visible
	shadow.ZIndex = panel.ZIndex - 1
end

local function skinPanel(panel: GuiObject, opts: PanelOpts, theme: UiTheme.Theme)
	panel.BackgroundColor3 = opts.Fill or theme.Panel
	panel.BackgroundTransparency = theme.PanelTransparency
	panel.BorderSizePixel = 0
	ensure(panel, "UICorner").CornerRadius = UDim.new(0, theme.Corner)
	local stroke = ensure(panel, "UIStroke") :: UIStroke
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Color = opts.Stroke or theme.Stroke
	stroke.Thickness = theme.StrokeWidth
	local shadow = shadows[panel]
	if shadow then
		shadow.BackgroundColor3 = theme.Shadow
		ensure(shadow, "UICorner").CornerRadius = UDim.new(0, theme.Corner)
		syncShadow(panel, shadow, theme)
	end
end

local function skinText(label: GuiObject, kind: TextKind, color: Color3?, theme: UiTheme.Theme)
	local t = label :: any
	if kind == "Title" then
		t.Font = theme.TitleFont
	elseif kind == "Hand" then
		t.Font = UiTheme.HandFont
	else
		t.Font = theme.Font
	end
	if kind == "Float" then
		t.TextColor3 = color or theme.FloatInk
		t.TextStrokeColor3 = theme.FloatStroke
		t.TextStrokeTransparency = 0
	else
		t.TextColor3 = color or (if kind == "Sub" then theme.SubInk else theme.Ink)
		t.TextStrokeTransparency = 1
	end
end

-- Make a frame (or button) a themed sticker panel. Fill/Stroke override the theme (e.g. a role-colored chip).
function UiSkin.Panel(panel: GuiObject, opts: PanelOpts?): GuiObject
	local o: PanelOpts = opts or {}
	panels[panel] = o
	if not o.NoShadow and panel.Parent then
		local shadow = Instance.new("Frame")
		shadow.Name = panel.Name .. "_Shadow"
		shadow.BorderSizePixel = 0
		shadow.Parent = panel.Parent
		shadows[panel] = shadow
		for _, prop in { "Visible", "Position", "Size", "Rotation", "AnchorPoint", "ZIndex" } do
			panel:GetPropertyChangedSignal(prop):Connect(function()
				syncShadow(panel, shadow, UiSkin.Theme())
			end)
		end
		panel.Destroying:Connect(function()
			shadow:Destroy()
			shadows[panel] = nil
		end)
	end
	panel.Destroying:Connect(function()
		panels[panel] = nil
	end)
	skinPanel(panel, o, UiSkin.Theme())
	return panel
end

-- Theme a text object. `color` pins the text color (e.g. a role color) while font still follows the world.
function UiSkin.Text(label: GuiObject, kind: TextKind?, color: Color3?): GuiObject
	local k: TextKind = kind or "Body"
	texts[label] = { kind = k, color = color }
	label.Destroying:Connect(function()
		texts[label] = nil
	end)
	skinText(label, k, color, UiSkin.Theme())
	return label
end

-- Change a registered text's pinned color later (nil = back to the theme ink).
function UiSkin.SetTextColor(label: GuiObject, color: Color3?)
	local entry = texts[label]
	if entry then
		entry.color = color
		skinText(label, entry.kind, color, UiSkin.Theme())
	end
end

-- Readable text on a colored fill: the theme's dark shadow on light fills, its ink on dark ones.
function UiSkin.InkOn(fill: Color3): Color3
	local theme = UiSkin.Theme()
	local luminance = 0.299 * fill.R + 0.587 * fill.G + 0.114 * fill.B
	if luminance > 0.55 then
		local _, _, value = theme.Shadow:ToHSV()
		return if value < 0.4 then theme.Shadow else Color3.new(0.1, 0.1, 0.12)
	end
	return Color3.new(1, 1, 1)
end

-- Extra per-world restyling a caller wants (runs now and on every world change).
function UiSkin.OnTheme(fn: (UiTheme.Theme) -> ())
	table.insert(listeners, fn)
	fn(UiSkin.Theme())
end

local function applyAll()
	local theme = UiSkin.Theme()
	for panel, opts in panels do
		skinPanel(panel, opts, theme)
	end
	for label, entry in texts do
		skinText(label, entry.kind, entry.color, theme)
	end
	for _, fn in listeners do
		task.spawn(fn, theme)
	end
end

workspace:GetAttributeChangedSignal("World"):Connect(applyAll)

return UiSkin
