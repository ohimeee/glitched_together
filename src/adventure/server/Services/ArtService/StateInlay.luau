-- A trigger's state used to show on its grey-box part (InteractableService turns it green neon while active). Once
-- the part wears a skin it's hidden, so a thin glowing inlay on top carries that state instead: the idle color
-- (neutral yellow for plates, duo white for two-player pieces), green while held / done.
local Palette = require(game:GetService("ReplicatedStorage").Shared.Config.Palette)

local ACTIVE = Color3.fromRGB(90, 255, 140)

return function(part: BasePart, idle: Color3?, size: Vector3?, offset: CFrame?): Part
	local inlay = Instance.new("Part")
	inlay.Name = "StateInlay"
	inlay.Size = size or Vector3.new(part.Size.X * 0.42, 0.06, part.Size.Z * 0.42)
	inlay.CFrame = part.CFrame * (offset or CFrame.new(0, part.Size.Y / 2 + 0.12, 0))
	inlay.Anchored = true
	inlay.CanCollide = false
	inlay.CanQuery = false
	inlay.CanTouch = false
	inlay.Material = Enum.Material.Neon
	inlay.Transparency = 0.25
	inlay.Parent = part
	local base = idle or Palette.Glow.Neutral
	local function show()
		inlay.Color = if part:GetAttribute("Active") then ACTIVE else base
	end
	part:GetAttributeChangedSignal("Active"):Connect(show)
	show()
	return inlay
end
