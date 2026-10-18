-- Adventure client entry point: Init input, then every controller.
local Input = require(script.Parent.Input)
Input.Init()

local Controllers = script.Parent.Controllers
local order = {
	"LoadingController", -- first: covers the screen before anything else draws
	"PerfController", -- low-end devices: thinner particles from the start
	"MoveAnimController",
	"MovementController",
	"StationController",
	"CameraController",
	"KitController",
	"HUDController",
	"TouchController",
	"ReviveController",
	"PartnerController",
	"PingController",
	"PeekController",
	"CutsceneController",
	"CreditsController",
	"CodeLayerController",
	"ShiftCloakController",
	"EffectsController",
	"PipController",
	"BeltController",
	"SpringController",
	"CartRideController",
	"FanController",
	"PropMotionController",
	"SwingPromptController",
	"KeyPromptController",
	"ToolFxController",
	"HeldSwayController",
	"AudioController",
	"AmbientController",
	"MeteorController",
	"TrailerController", -- admin /trailer recording mode
}

for _, name in order do
	local module = Controllers:FindFirstChild(name)
	if module then
		local ok, err = pcall(function()
			require(module).Init()
		end)
		if not ok then
			warn(`[Client] {name} failed to start:`, err)
		end
	end
end

-- settings menu (gear, top right): gameplay input sinks while it's up (MenuContext; left alone if a cutscene owns it)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ownedMenu = false
require(ReplicatedStorage.Shared.Util.SettingsMenu).Init({
	editLayout = require(Controllers.TouchController).EditLayout,
	onOpen = function()
		if not Input.isEnabled("MenuContext") then
			ownedMenu = true
			Input.setEnabled("MenuContext", true)
		end
	end,
	onClose = function()
		if ownedMenu then
			ownedMenu = false
			Input.setEnabled("MenuContext", false)
		end
	end,
})
