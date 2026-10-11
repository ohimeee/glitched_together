-- Adventure client entry point: Init input, then every controller.
local Input = require(script.Parent.Input)
Input.Init()

local Controllers = script.Parent.Controllers
local order = {
	"LoadingController", -- first: covers the screen before anything else draws
	"MoveAnimController",
	"MovementController",
	"StationController",
	"CameraController",
	"KitController",
	"HUDController",
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
	"AudioController",
	"AmbientController",
	"MeteorController",
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
