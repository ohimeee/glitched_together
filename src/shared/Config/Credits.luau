-- The end credits (Epilogue, CreditsController): first the game inside the game (Story Line: "Starfall Kingdom, by
-- Kai & Miko"), then the real credits. Third-party entries must match CREDITS.md (licenses: CC0 / CC BY only).
export type Block = { Title: string, Lines: { string } }

local Credits: { Block } = {
	{ Title = "STARFALL KINGDOM", Lines = { "a game by Kai & Miko", "(finally finished)" } },
	{ Title = "GLITCHED TOGETHER", Lines = { "a co-op adventure for two" } },
	{ Title = "Made by", Lines = { "buldak0555" } },
	{ Title = "Built with", Lines = { "Roblox Studio, Rojo, Blender", "and Claude (Anthropic)" } },
	{
		Title = "Boss models",
		Lines = {
			'"Celestial Dragon (Flawless)" by achrefrhm9 (CC BY 4.0)',
			'"Meteor Golem - Cosmic Rock Creature" by s8819296 (CC BY 4.0)',
			"both via Sketchfab, modified",
		},
	},
	{ Title = "Textures", Lines = { "Poly Haven (CC0)", "ambientCG (CC0)" } },
	{ Title = "Music", Lines = { "APM Music (licensed for Roblox experiences)" } },
	{ Title = "Inspired by", Lines = { "the two-player co-op of It Takes Two", "(no assets used)" } },
	{ Title = "Thank you for playing", Lines = { "together." } },
}

return Credits
