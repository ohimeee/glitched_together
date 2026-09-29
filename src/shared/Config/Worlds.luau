-- World order and look. Palettes come from design.md §8; lighting follows research.md
-- ("Pixar-esque": saturated, soft haze, bloom only on Neon).
export type Look = {
	ClockTime: number,
	Brightness: number,
	Ambient: Color3,
	OutdoorAmbient: Color3,
	AtmosphereDensity: number,
	AtmosphereHaze: number,
	AtmosphereColor: Color3,
	AtmosphereDecay: Color3,
	BloomIntensity: number,
	BloomThreshold: number,
	Saturation: number,
	Contrast: number,
	Tint: Color3,
}

export type World = {
	Name: string,
	Title: string,
	Palette: { Color3 },
	Look: Look,
	Music: string?, -- rbxassetid, TODO when audio lands
}

local Order = { "Prologue", "PixelPlains", "StarfallCastle", "GlitchedCore", "Epilogue" }

local rgb = Color3.fromRGB

local ByName: { [string]: World } = {
	Prologue = {
		Name = "Prologue",
		Title = "The Title Screen",
		Palette = { rgb(20, 24, 58), rgb(240, 240, 250), rgb(255, 80, 170) }, -- dark navy, white UI, pink glitch
		Look = {
			ClockTime = 0,
			Brightness = 1.5,
			Ambient = rgb(60, 60, 110),
			OutdoorAmbient = rgb(110, 110, 170),
			AtmosphereDensity = 0.35,
			AtmosphereHaze = 1.5,
			AtmosphereColor = rgb(120, 110, 200),
			AtmosphereDecay = rgb(255, 80, 170),
			BloomIntensity = 0.8,
			BloomThreshold = 1.4,
			Saturation = 0.15,
			Contrast = 0.1,
			Tint = rgb(235, 235, 255),
		},
	},
	PixelPlains = {
		Name = "PixelPlains",
		Title = "Pixel Plains",
		Palette = { rgb(88, 200, 72), rgb(110, 190, 255), rgb(255, 205, 40) }, -- bright green, sky blue, coin gold
		Look = {
			ClockTime = 13,
			Brightness = 3,
			Ambient = rgb(120, 130, 150),
			OutdoorAmbient = rgb(150, 170, 200),
			AtmosphereDensity = 0.25,
			AtmosphereHaze = 1,
			AtmosphereColor = rgb(200, 230, 255),
			AtmosphereDecay = rgb(120, 180, 255),
			BloomIntensity = 0.6,
			BloomThreshold = 1.6,
			Saturation = 0.25,
			Contrast = 0.05,
			Tint = rgb(255, 250, 240),
		},
	},
	StarfallCastle = {
		Name = "StarfallCastle",
		Title = "Starfall Castle",
		Palette = { rgb(70, 40, 110), rgb(255, 140, 40), rgb(230, 190, 70) }, -- deep purple, torch orange, gold
		Look = {
			ClockTime = 20.5,
			Brightness = 1,
			Ambient = rgb(55, 40, 80),
			OutdoorAmbient = rgb(70, 50, 100),
			AtmosphereDensity = 0.4,
			AtmosphereHaze = 2,
			AtmosphereColor = rgb(110, 80, 150),
			AtmosphereDecay = rgb(255, 140, 40),
			BloomIntensity = 1,
			BloomThreshold = 1.2,
			Saturation = 0.15,
			Contrast = 0.15,
			Tint = rgb(255, 235, 220),
		},
	},
	GlitchedCore = {
		Name = "GlitchedCore",
		Title = "The Glitched Core",
		Palette = { rgb(130, 130, 135), rgb(15, 15, 18), rgb(60, 255, 120), rgb(255, 40, 200) }, -- grey, black, green, magenta
		Look = {
			ClockTime = 0,
			Brightness = 1.2,
			Ambient = rgb(70, 70, 80),
			OutdoorAmbient = rgb(80, 80, 90),
			AtmosphereDensity = 0.45,
			AtmosphereHaze = 1,
			AtmosphereColor = rgb(60, 60, 70),
			AtmosphereDecay = rgb(60, 255, 120),
			BloomIntensity = 1.2,
			BloomThreshold = 1.1,
			Saturation = -0.2,
			Contrast = 0.2,
			Tint = rgb(235, 255, 240),
		},
	},
	Epilogue = {
		Name = "Epilogue",
		Title = "Continue",
		Palette = { rgb(30, 45, 95), rgb(255, 225, 150), rgb(160, 190, 255) }, -- warm night blues
		Look = {
			ClockTime = 22,
			Brightness = 1.5,
			Ambient = rgb(60, 70, 120),
			OutdoorAmbient = rgb(80, 95, 150),
			AtmosphereDensity = 0.2,
			AtmosphereHaze = 0.5,
			AtmosphereColor = rgb(130, 150, 220),
			AtmosphereDecay = rgb(255, 210, 150),
			BloomIntensity = 1,
			BloomThreshold = 1.3,
			Saturation = 0.2,
			Contrast = 0.05,
			Tint = rgb(255, 245, 230),
		},
	},
}

local Lighting = game:GetService("Lighting")

local function child(className: string, name: string): any
	local existing = Lighting:FindFirstChild(name)
	if existing and existing:IsA(className) then
		return existing
	end
	local inst = Instance.new(className)
	inst.Name = name
	inst.Parent = Lighting
	return inst
end

-- Applies a world's lighting. Safe on server and client.
local function applyLook(look: Look)
	Lighting.ClockTime = look.ClockTime
	Lighting.Brightness = look.Brightness
	Lighting.Ambient = look.Ambient
	Lighting.OutdoorAmbient = look.OutdoorAmbient
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1

	local atmosphere = child("Atmosphere", "WorldAtmosphere")
	atmosphere.Density = look.AtmosphereDensity
	atmosphere.Haze = look.AtmosphereHaze
	atmosphere.Color = look.AtmosphereColor
	atmosphere.Decay = look.AtmosphereDecay
	atmosphere.Offset = 0.1

	local bloom = child("BloomEffect", "WorldBloom")
	bloom.Intensity = look.BloomIntensity
	bloom.Threshold = look.BloomThreshold
	bloom.Size = 28

	local cc = child("ColorCorrectionEffect", "WorldColor")
	cc.Saturation = look.Saturation
	cc.Contrast = look.Contrast
	cc.TintColor = look.Tint
end

return { Order = Order, ByName = ByName, ApplyLook = applyLook }
