-- Exact colors from art-direction.md §16. Reserved gameplay colors (§6) mean one thing each and are never used
-- for decoration: Kai's targets orange, Miko's teal, both-player objects white, neutral interactables yellow,
-- danger red, The Glitch magenta (+ cyan fringe / black checker).
local hex = Color3.fromHex

-- Neon adds a lot of brightness in Roblox (orange reads yellow, teal reads white-cyan). Use these on Neon parts
-- so the glow still reads as the reserved color.
local function glow(c: Color3): Color3
	return c:Lerp(Color3.new(0, 0, 0), 0.35)
end

local Palette
local glowOf: { [string]: Color3 } = {}

-- The color to use on a Neon part: reserved colors get their Glow version, anything else is unchanged.
local function forNeon(c: Color3): Color3
	return glowOf[c:ToHex()] or c
end

Palette = {
	ForNeon = forNeon,
	Glow = {
		Kai = glow(hex("#FF8A2B")),
		Miko = glow(hex("#1FC7B6")),
		Duo = hex("#8E96A8"), -- white Neon + bloom is blinding; this still reads as white
		Neutral = glow(hex("#FFD23F")),
		Danger = glow(hex("#E5383B")),
		Glitch = glow(hex("#FF2BD6")),
	},
	-- reserved gameplay colors
	Kai = hex("#FF8A2B"),
	Miko = hex("#1FC7B6"),
	Duo = hex("#F5F7FA"),
	Neutral = hex("#FFD23F"),
	Danger = hex("#E5383B"),
	Glitch = hex("#FF2BD6"),
	GlitchCyan = hex("#2BF2FF"),
	GlitchBlack = hex("#0B0B10"),

	-- world palettes
	RealWorld = {
		NightBlue = hex("#1C2742"),
		ScreenGlow = hex("#8FB8FF"),
		Lamp = hex("#FFB763"),
		Wall = hex("#CBBFA8"),
	},
	Prologue = { Navy = hex("#111A3A"), DeepNavy = hex("#0A0F24"), White = hex("#EEF2FF"), Pink = hex("#FF5FA2") },
	PixelPlains = {
		Grass = hex("#5BD15B"),
		GrassShadow = hex("#3FA34D"),
		Sky = hex("#6EC6FF"),
		Gold = hex("#FFC83D"),
		Dirt = hex("#B5773F"),
		Cloud = hex("#FFFFFF"),
	},
	Castle = {
		NightPurple = hex("#3B2A5A"),
		Royal = hex("#5A3E8C"),
		Stone = hex("#6E6A80"),
		Torch = hex("#FFB347"),
		Gold = hex("#E8B64C"),
		Banner = hex("#8C2F5A"),
	},
	Core = { Grey = hex("#7A7D85"), Dark = hex("#3A3C42"), Void = hex("#141518") },
	Final = { Sky = hex("#1A2466"), Starlight = hex("#FFF3C4") },
}

for _, name in { "Kai", "Miko", "Duo", "Neutral", "Danger", "Glitch" } do
	glowOf[(Palette :: any)[name]:ToHex()] = Palette.Glow[name]
end

return Palette
