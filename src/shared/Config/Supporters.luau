-- Supporter recognition (user, Oct 18): no gameplay advantage, looks only.
--   * anyone who tips (Products.Support) gets their Roblox headshot + name on the Supporter Wall (lobby cork board +
--     Epilogue notice board), in the end credits ("special thanks"), and a gold SUPPORTER tag over their head
--   * game pass Tags.Pass ("Name Tag Color"): pick the tag's color and title (lobby board prompt cycles them)
--   * game pass Aura ("Glowing Aura"): soft sparkles round the character
-- Teal and magenta are Miko's and Glitch's (art-direction §6): never offered as tag or aura colors.
-- Never word it as charity or donations (Roblox rule): "support" / "supporter" only.
return {
	-- title shown by default: a tipper gets SUPPORTER, a Name Tag pass owner who never tipped gets VIP
	TipTitle = "SUPPORTER",
	PassTitle = "VIP",
	-- titles a Name Tag pass owner can pick from (cycled with the lobby board prompt)
	Titles = { "SUPPORTER", "VIP", "PATRON", "GLITCH HUNTER", "PIXEL PAL", "BUG SQUASHER", "STAR KEEPER" },
	-- tag colors (index 1 = the default gold)
	Colors = {
		{ Name = "Gold", Color = Color3.fromRGB(255, 200, 61) },
		{ Name = "Sunset", Color = Color3.fromRGB(255, 140, 66) },
		{ Name = "Rose", Color = Color3.fromRGB(255, 92, 92) },
		{ Name = "Lime", Color = Color3.fromRGB(150, 230, 80) },
		{ Name = "Sky", Color = Color3.fromRGB(110, 170, 255) },
		{ Name = "Silver", Color = Color3.fromRGB(235, 238, 245) },
	},
	AuraColor = Color3.fromRGB(255, 226, 150), -- warm gold-white
}
