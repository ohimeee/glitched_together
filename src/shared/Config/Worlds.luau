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
	EnvDiffuse: number?, -- Lighting.EnvironmentDiffuseScale, default 1
	-- a Blender-rendered panorama around the level (blender_assets/<World>Sky.blend → textures/sky); nil = default sky
	Skybox: { Bk: string, Ft: string, Lf: string, Rt: string, Up: string, Dn: string }?,
	Latitude: number?, -- Lighting.GeographicLatitude (default 41.73): with ClockTime, aims the light at a baked moon
	BakedSky: boolean?, -- the skybox already has its moon/sun and stars: hide Roblox's own celestial bodies and stars
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
			-- Oct 2 (10th session): afternoon sun to match the Blender panorama (blender_assets/PixelPlainsSky.blend,
			-- rendered with the sun at this ClockTime's direction); lower light so the level sits in that world
			ClockTime = 15,
			Brightness = 1.6,
			Ambient = rgb(120, 130, 150),
			OutdoorAmbient = rgb(110, 120, 140),
			EnvDiffuse = 0.6,
			AtmosphereDensity = 0.12, -- the panorama carries its own aerial haze; this only softens far level pieces
			AtmosphereHaze = 0,
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
			Skybox = { -- voxel valley far below, lakes, villages, floating islands, the Starfall castle ahead on the skyline
				Bk = "rbxassetid://115564504494293",
				Ft = "rbxassetid://124076922050746",
				Lf = "rbxassetid://134819212004535",
				Rt = "rbxassetid://106272469387845",
				Up = "rbxassetid://123368559944337",
				Dn = "rbxassetid://135599544937063",
			},
		},
	},
	StarfallCastle = {
		Name = "StarfallCastle",
		Title = "Starfall Castle",
		Palette = { rgb(59, 42, 90), rgb(255, 179, 71), rgb(232, 182, 76) }, -- night purple, torch amber, trim gold (art-direction §16)
		Look = {
			-- night interior, warm torch pools against cool purple (art-direction.md §8–9); the grey-box adds wall torches.
			-- Roblox dims a custom skybox at night, so the clock stays at day and the "sun" is the baked moon: ClockTime
			-- 8.9 at latitude 78 points it exactly at the moon in the panorama, at moonlight brightness
			ClockTime = 8.9,
			Latitude = 78,
			Brightness = 0.45,
			EnvDiffuse = 0.5,
			EnvSpecular = 0.5,
			Ambient = rgb(100, 80, 140),
			OutdoorAmbient = rgb(120, 95, 160),
			AtmosphereDensity = 0.15,
			AtmosphereHaze = 0, -- the panorama has its own night haze; Roblox's would paint over it
			AtmosphereColor = rgb(110, 80, 150),
			AtmosphereDecay = rgb(255, 179, 71),
			BloomIntensity = 1,
			BloomThreshold = 1.2,
			Saturation = 0.15,
			Contrast = 0.15,
			Tint = rgb(255, 235, 220),
			-- the castle stands on a crag over a moonlit kingdom: right below (the top-down camera sees mostly the Dn face) a
			-- river valley with a stone bridge, a lantern road, a village with a chapel and a watermill, pine forest; further
			-- out snowy mountains, a lake, villages, Milky Way; rendered from 700 up so the valley reads far below, with valley
			-- mist (blender_assets/PixelPlainsSky.blend, scene CastleSky, collection DnSet)
			Skybox = {
				Bk = "rbxassetid://76482591344110",
				Ft = "rbxassetid://129799494219118",
				Lf = "rbxassetid://76374802988677",
				Rt = "rbxassetid://111055250742013",
				Up = "rbxassetid://111236374199370",
				Dn = "rbxassetid://100676855591730",
			},
			BakedSky = true,
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
			Brightness = 1.5,
			Ambient = rgb(138, 140, 152), -- lifted Oct 2 so the primer/concrete surfaces read
			OutdoorAmbient = rgb(150, 152, 164),
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
	Lighting.GeographicLatitude = look.Latitude or 41.7333
	Lighting.Brightness = look.Brightness
	Lighting.Ambient = look.Ambient
	Lighting.OutdoorAmbient = look.OutdoorAmbient
	Lighting.EnvironmentDiffuseScale = look.EnvDiffuse or 1
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
	sky.CelestialBodiesShown = not look.BakedSky
	sky.StarCount = if look.BakedSky then 0 else 3000
	local box = look.Skybox
	sky.SkyboxBk = if box then box.Bk else "rbxasset://textures/sky/sky512_bk.tex"
	sky.SkyboxFt = if box then box.Ft else "rbxasset://textures/sky/sky512_ft.tex"
	sky.SkyboxLf = if box then box.Lf else "rbxasset://textures/sky/sky512_lf.tex"
	sky.SkyboxRt = if box then box.Rt else "rbxasset://textures/sky/sky512_rt.tex"
	sky.SkyboxUp = if box then box.Up else "rbxasset://textures/sky/sky512_up.tex"
	sky.SkyboxDn = if box then box.Dn else "rbxasset://textures/sky/sky512_dn.tex"
end

return { Order = Order, ByName = ByName, ApplyLook = applyLook }
