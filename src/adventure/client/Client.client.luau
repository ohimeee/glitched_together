-- Adventure client entry point: Init input, then every controller.
local Input = require(script.Parent.Input)
Input.Init()

local Controllers = script.Parent.Controllers
local order = {
	"MovementController",
	"CameraController",
	"KitController",
	"HUDController",
	"PartnerController",
	"PingController",
	"PeekController",
	"CutsceneController",
	"CodeLayerController",
	"EffectsController",
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
