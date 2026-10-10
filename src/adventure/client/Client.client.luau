-- Adventure client entry point: Init input, then every controller.
local Input = require(script.Parent.Input)
Input.Init()

local Controllers = script.Parent.Controllers
local order = {
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
	"FanController",
	"PropMotionController",
	"SwingPromptController",
	"SaveDiskController",
	"ToolFxController",
	"AudioController",
	"AmbientController",
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
