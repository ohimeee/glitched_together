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
	SunTexture: string?, -- nil = Roblox's default sun
	SunSize: number?, -- degrees (Sky.SunAngularSize), default 21
	EnvSpecular: number?, -- Lighting.EnvironmentSpecularScale, default 1 (lower = less sky sheen on glossy toys)
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
			Brightness = 2.4,
			Ambient = rgb(120, 130, 150),
			OutdoorAmbient = rgb(150, 170, 200),
			AtmosphereDensity = 0.18, -- light haze only: more and the grass washes out to mint
			AtmosphereHaze = 0.5,
			AtmosphereColor = rgb(200, 230, 255),
			AtmosphereDecay = rgb(120, 180, 255),
			BloomIntensity = 0.6,
			BloomThreshold = 1.6,
			Saturation = 0.25,
			Contrast = 0.05,
			Tint = rgb(255, 250, 240),
			SunTexture = "rbxassetid://120731124856629", -- a kid's crayon sun (textures/PP_CrayonSun2.png, art-direction §8)
			SunSize = 30,
			EnvSpecular = 0.25, -- the plastic kit reflected so much sky that the grass read pale mint
		},
	},
	StarfallCastle = {
		Name = "StarfallCastle",
		Title = "Starfall Castle",
		Palette = { rgb(59, 42, 90), rgb(255, 179, 71), rgb(232, 182, 76) }, -- night purple, torch amber, trim gold (art-direction §16)
		Look = {
			-- night interior, warm torch pools against cool purple (art-direction.md §8–9); the grey-box adds wall torches
			ClockTime = 21,
			Brightness = 1.5,
			Ambient = rgb(100, 80, 140),
			OutdoorAmbient = rgb(120, 95, 160),
			AtmosphereDensity = 0.2,
			AtmosphereHaze = 1,
			AtmosphereColor = rgb(110, 80, 150),
			AtmosphereDecay = rgb(255, 179, 71),
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
		-- grey, void, Miko teal, Glitch magenta: the only strong colors are the Code Layer and the Glitch (art-direction §8, §16)
		Palette = { rgb(122, 125, 133), rgb(20, 21, 24), rgb(31, 199, 182), rgb(255, 43, 214) },
		Look = {
			-- cold and dim, but the grey blocks must still read (art-direction §9: saturation −0.4, dense grey haze)
			ClockTime = 0,
			Brightness = 1.2,
			Ambient = rgb(118, 120, 132),
			OutdoorAmbient = rgb(128, 130, 142),
			AtmosphereDensity = 0.32,
			AtmosphereHaze = 0.8,
			AtmosphereColor = rgb(96, 98, 108),
			AtmosphereDecay = rgb(70, 110, 120),
			BloomIntensity = 1.2,
			BloomThreshold = 1.1,
			Saturation = -0.4,
			Contrast = 0.1,
			Tint = rgb(235, 242, 248),
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
	Lighting.EnvironmentSpecularScale = look.EnvSpecular or 1

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

	local sky = child("Sky", "WorldSky")
	sky.SunTextureId = look.SunTexture or "rbxasset://sky/sun.jpg"
	sky.SunAngularSize = look.SunSize or 21
end

return { Order = Order, ByName = ByName, ApplyLook = applyLook }
