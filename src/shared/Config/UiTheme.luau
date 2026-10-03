-- UI look per world (art-direction.md §11 fonts and sticker panels, §16 palette, §8 world style sheets).
-- "The HUD looks like the UI of the game the kids made, and changes skin per world": every panel is a sticker
-- (thick outline, hard drop shadow) whose font, colors and corners follow the world. UiSkin (Shared/Util) applies
-- it on the client; Greybox uses the Sign* fields for in-world signs. Reserved gameplay colors (owner orange/teal,
-- duo white, neutral yellow, danger red, glitch magenta) are never panel decoration here.
local rgb = Color3.fromRGB
local hex = Color3.fromHex

export type Theme = {
	Font: Enum.Font, -- body text
	TitleFont: Enum.Font, -- headings, tool names, speaker names
	Panel: Color3,
	PanelTransparency: number,
	Ink: Color3, -- text on panels
	SubInk: Color3, -- secondary text on panels
	Stroke: Color3, -- sticker outline
	StrokeWidth: number,
	Corner: number, -- px; 0 = pixel-square
	Shadow: Color3,
	ShadowOffset: number, -- px, down-right
	Accent: Color3, -- chips, meters, highlights
	FloatInk: Color3, -- text drawn straight on the 3D view (hearts, prompts)
	FloatStroke: Color3,
	-- in-world signs (Greybox)
	SignFont: Enum.Font,
	SignBoard: Color3,
	SignInk: Color3,
	SignMaterial: Enum.Material,
	SignTilt: number, -- degrees: kid-painted signs sit a little crooked
}

local UiTheme = {}

-- Kid handwriting: notes, doodles, credits (§11).
UiTheme.HandFont = Enum.Font.PermanentMarker

local Themes: { [string]: Theme } = {
	-- The broken title menu: navy panels with white UI edges, pink accents.
	Prologue = {
		Font = Enum.Font.FredokaOne,
		TitleFont = Enum.Font.FredokaOne,
		Panel = hex("#2E3670"),
		PanelTransparency = 0.05,
		Ink = hex("#EEF2FF"),
		SubInk = rgb(180, 190, 235),
		Stroke = hex("#EEF2FF"),
		StrokeWidth = 3,
		Corner = 14,
		Shadow = hex("#0A0F24"),
		ShadowOffset = 5,
		Accent = hex("#FF5FA2"),
		FloatInk = hex("#EEF2FF"),
		FloatStroke = hex("#0A0F24"),
		SignFont = Enum.Font.FredokaOne,
		SignBoard = rgb(40, 46, 96),
		SignInk = hex("#EEF2FF"),
		SignMaterial = Enum.Material.SmoothPlastic,
		SignTilt = 0,
	},
	-- The first level they built: cream pixel panels, chunky dark outline, square corners, hard shadow.
	PixelPlains = {
		Font = Enum.Font.Arcade,
		TitleFont = Enum.Font.Arcade,
		Panel = hex("#FFF6D8"),
		PanelTransparency = 0,
		Ink = hex("#2B1B0E"),
		SubInk = hex("#6B4A2A"),
		Stroke = hex("#2B1B0E"),
		StrokeWidth = 4,
		Corner = 0,
		Shadow = hex("#2B1B0E"), -- dark, so the sticker lifts off the green grass and blue sky
		ShadowOffset = 6,
		Accent = hex("#FFC83D"),
		FloatInk = hex("#FFFFFF"),
		FloatStroke = hex("#2B1B0E"),
		SignFont = Enum.Font.PermanentMarker, -- hand-painted "START" signs (§8)
		SignBoard = hex("#B5773F"),
		SignInk = hex("#FFF6D8"),
		SignStroke = hex("#3A2414"), -- dark wood-stain outline round the painted letters
		SignMaterial = Enum.Material.WoodPlanks,
		SignTilt = -3,
	},
	-- A castle from a kid's fantasy notebook: night purple, gold trim, storybook lettering.
	StarfallCastle = {
		Font = Enum.Font.Fantasy,
		TitleFont = Enum.Font.Fantasy,
		Panel = hex("#3B2A5A"),
		PanelTransparency = 0.05,
		Ink = hex("#FFF3D6"),
		SubInk = rgb(220, 200, 160),
		Stroke = hex("#E8B64C"),
		StrokeWidth = 3,
		Corner = 10,
		Shadow = rgb(20, 12, 32),
		ShadowOffset = 5,
		Accent = hex("#FFB347"),
		FloatInk = hex("#FFF3D6"),
		FloatStroke = rgb(20, 12, 32),
		SignFont = Enum.Font.Fantasy,
		SignBoard = hex("#5A3E8C"),
		SignInk = hex("#E8B64C"),
		SignMaterial = Enum.Material.Fabric,
		SignTilt = 0,
	},
	-- The level they never finished: flat grey, monospace, placeholder feel. Color stays drained (§3).
	GlitchedCore = {
		Font = Enum.Font.Code,
		TitleFont = Enum.Font.Code,
		Panel = hex("#3A3C42"),
		PanelTransparency = 0.05,
		Ink = rgb(222, 225, 232),
		SubInk = hex("#7A7D85"),
		Stroke = hex("#7A7D85"),
		StrokeWidth = 2,
		Corner = 2,
		Shadow = hex("#141518"),
		ShadowOffset = 4,
		Accent = rgb(200, 203, 212),
		FloatInk = rgb(222, 225, 232),
		FloatStroke = hex("#141518"),
		SignFont = Enum.Font.Code,
		SignBoard = hex("#3A3C42"),
		SignInk = rgb(222, 225, 232),
		SignMaterial = Enum.Material.SmoothPlastic,
		SignTilt = 0,
	},
	-- Repaired and whole: starlight on a deep blue sky.
	Epilogue = {
		Font = Enum.Font.FredokaOne,
		TitleFont = Enum.Font.FredokaOne,
		Panel = hex("#1A2466"),
		PanelTransparency = 0.05,
		Ink = hex("#FFF3C4"),
		SubInk = rgb(220, 210, 170),
		Stroke = hex("#FFF3C4"),
		StrokeWidth = 3,
		Corner = 16,
		Shadow = rgb(10, 14, 40),
		ShadowOffset = 5,
		Accent = hex("#FFB763"),
		FloatInk = hex("#FFF3C4"),
		FloatStroke = rgb(10, 14, 40),
		SignFont = Enum.Font.FredokaOne,
		SignBoard = hex("#1A2466"),
		SignInk = hex("#FFF3C4"),
		SignMaterial = Enum.Material.SmoothPlastic,
		SignTilt = 0,
	},
}

-- Main HUD / lobby look (FredokaOne, §11) when no world is loaded.
UiTheme.Default = Themes.Prologue

function UiTheme.For(worldName: string?): Theme
	return (worldName and Themes[worldName]) or UiTheme.Default
end

return UiTheme
