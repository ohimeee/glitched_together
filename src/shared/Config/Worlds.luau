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
	-- cinematic depth of field (It Takes Two's soft background): the far panorama and distant level pieces blur a
	-- little, which also hides the skybox's pixels. Default { Far = 0.15, Focus = 40, Radius = 70 }
	Dof: { Far: number, Focus: number, Radius: number }?,
	SunRays: number?, -- SunRaysEffect intensity (0 = off), for worlds with a visible sun
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
			-- the title screen built for real (Blender panorama, tools/prologue_sky): a navy theater void with soft
			-- stars, a glossy mirror floor with a UI grid far below, giant acrylic menu panels with neon rims, glossy
			-- toy planets and floating toy blocks (It Takes Two's space chapter), the kid-handwritten "Starfall
			-- Kingdom" logo glowing ahead. Day clock (Roblox dims skyboxes at night) aimed at the render's cool key
			-- light (ClockTime 10.95 at latitude 61), at night-level brightness
			ClockTime = 10.95,
			Latitude = 61,
			Brightness = 0.7,
			EnvDiffuse = 0.6,
			EnvSpecular = 0.8, -- the glossy menu plastic picks up the panorama's neon
			Ambient = rgb(62, 68, 122),
			OutdoorAmbient = rgb(74, 82, 146),
			AtmosphereDensity = 0.2,
			AtmosphereHaze = 0, -- the panorama has its own haze; Roblox's would paint over it
			AtmosphereColor = rgb(26, 34, 82),
			AtmosphereDecay = rgb(255, 95, 162),
			BloomIntensity = 1,
			BloomThreshold = 1.2,
			Saturation = 0.15,
			Contrast = 0.1,
			Tint = rgb(235, 235, 255),
			Skybox = {
				Bk = "rbxassetid://117792848022332",
				Ft = "rbxassetid://133378729761902",
				Lf = "rbxassetid://94667748630633",
				Rt = "rbxassetid://111964410695923",
				Up = "rbxassetid://82645456853239",
				Dn = "rbxassetid://106737989483976",
			},
			BakedSky = true,
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
			SunRays = 0.05, -- soft god rays from the crayon sun (It Takes Two's warm low sun)
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
			Dof = { Far = 0.22, Focus = 62, Radius = 45 }, -- the top-down camera sits ~63 studs from the floor
		},
	},
	GlitchedCore = {
		Name = "GlitchedCore",
		Title = "The Glitched Core",
		-- grey, void, Miko teal, Glitch magenta: the only strong colors are the Code Layer and the Glitch (art-direction §8, §16)
		Palette = { rgb(122, 125, 133), rgb(20, 21, 24), rgb(31, 199, 182), rgb(255, 43, 214) },
		Look = {
			-- the unfinished level as a real scale model: grey primer chunks of the earlier worlds on brass rods over an
			-- endless pencil-gridded drafting sheet, a pencil-sketched sky, a few magenta Glitch tears (Blender panorama,
			-- tools/core_sky). Overcast work-lamp light; Roblox dims skyboxes at night, so a day clock aims the light
			-- where the render's key light came from (ClockTime 13.6 at latitude -7). Saturation -0.4 (art-direction §9)
			ClockTime = 13.6,
			Latitude = -7,
			Brightness = 1.6,
			EnvDiffuse = 0.7,
			EnvSpecular = 0.4,
			Ambient = rgb(118, 121, 130),
			OutdoorAmbient = rgb(140, 143, 152),
			AtmosphereDensity = 0.28,
			AtmosphereHaze = 0, -- the panorama has its own haze; Roblox's would paint over it
			AtmosphereColor = rgb(158, 162, 169), -- the render's haze (#9EA2A9), so far geometry melts into the sheet
			AtmosphereDecay = rgb(140, 146, 156),
			BloomIntensity = 1.2,
			BloomThreshold = 1.1,
			Saturation = -0.4,
			Contrast = 0.1,
			Tint = rgb(240, 244, 250),
			Skybox = {
				Bk = "rbxassetid://138941382806679",
				Ft = "rbxassetid://121540696844585",
				Lf = "rbxassetid://109539663859465",
				Rt = "rbxassetid://84423646772581",
				Up = "rbxassetid://138758600631870",
				Dn = "rbxassetid://134879075833502",
			},
			BakedSky = true,
		},
	},
	-- not a world you play: the lobby (Kai and Miko's bedroom at night, src/lobby/server/LobbyRoom.luau)
	Lobby = {
		Name = "Lobby",
		Title = "The Bedroom",
		Palette = { rgb(40, 44, 90), rgb(255, 200, 140), rgb(170, 175, 220) },
		Look = {
			-- moonlight falls in through the window (+Z) at a day clock (Roblox dims skyboxes at night): ClockTime
			-- 10.25 at latitude 80 aims the light from above the window into the room, at moonlight brightness;
			-- warm pools come from the desk lamp, the fairy lights and the hallway door
			ClockTime = 10.25,
			Latitude = 80,
			Brightness = 0.7,
			EnvDiffuse = 0.5,
			EnvSpecular = 0.5,
			Ambient = rgb(118, 114, 156),
			OutdoorAmbient = rgb(110, 112, 158),
			AtmosphereDensity = 0,
			AtmosphereHaze = 0,
			AtmosphereColor = rgb(40, 44, 90),
			AtmosphereDecay = rgb(40, 44, 90),
			BloomIntensity = 1,
			BloomThreshold = 1.1,
			Saturation = 0.1,
			Contrast = 0.12,
			Tint = rgb(236, 236, 255),
			BakedSky = true,
			-- macro-photo depth of field: a tight focus near the camera sells the doll scale (tilt-shift)
			Dof = { Far = 0.4, Focus = 24, Radius = 26 },
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

-- out of the bedroom window: the moonlit valley (the kingdom they dreamed up); a suburb render could replace it
ByName.Lobby.Look.Skybox = ByName.StarfallCastle.Look.Skybox

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

	local dofLook = look.Dof or { Far = 0.15, Focus = 40, Radius = 70 }
	local dof = child("DepthOfFieldEffect", "WorldDof")
	dof.FarIntensity = dofLook.Far
	dof.FocusDistance = dofLook.Focus
	dof.InFocusRadius = dofLook.Radius
	dof.NearIntensity = 0

	local rays = child("SunRaysEffect", "WorldSunRays")
	rays.Intensity = look.SunRays or 0
	rays.Spread = 0.7
	rays.Enabled = (look.SunRays or 0) > 0

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
