-- Screen-size scaling for pixel-built ScreenGuis (mobile + console pass, LAUNCH.md §3): one UIScale on the ScreenGui
-- shrinks the whole HUD on a small phone and grows it on a TV (10-foot UI); edge-anchored offsets keep their edges.
--   UiFit.attach(screenGui)   adds the UIScale and keeps it fitted to the viewport
--   UiFit.scale(screenGui)    the current factor (divide screen-pixel positions by it, e.g. the crosshair)
-- Design size: Tuning.UiFit.Design (the PC window everything was built at).
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Settings = require(ReplicatedStorage.Shared.Util.Settings)

local UiFit = {}

local function fitted(): number
	local camera = workspace.CurrentCamera
	local view = if camera then camera.ViewportSize else Tuning.UiFit.Design
	local design = Tuning.UiFit.Design
	local k = math.min(view.X / design.X, view.Y / design.Y)
	if GuiService:IsTenFootInterface() then
		return math.clamp(k * Tuning.UiFit.TvBoost, 1, Tuning.UiFit.Max)
	end
	return math.clamp(k, Tuning.UiFit.Min, 1) -- PC/phone: shrink to fit, never blow up
end

-- × the settings menu's text size (the only way the UI grows past its design size on PC / phone)
local function factor(): number
	return fitted() * (Settings.Get("TextScale") :: number)
end

function UiFit.attach(gui: ScreenGui): UIScale
	local scale = gui:FindFirstChild("UiFit") :: UIScale?
	if scale then
		return scale
	end
	local s = Instance.new("UIScale")
	s.Name = "UiFit"
	s.Scale = factor()
	s.Parent = gui
	local function hook()
		local camera = workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				s.Scale = factor()
			end)
		end
		s.Scale = factor()
	end
	hook()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(hook)
	Settings.Changed:Connect(function(key)
		if key == "TextScale" then
			s.Scale = factor()
		end
	end)
	return s
end

function UiFit.scale(gui: Instance): number
	local s = gui:FindFirstChild("UiFit") :: UIScale?
	return if s then s.Scale else 1
end

return UiFit
