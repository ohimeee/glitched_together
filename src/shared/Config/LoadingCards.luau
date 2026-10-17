-- Loading screen paintings (user plan Oct 12, art approved Oct 17: "all the images is perfect"). One painted card
-- per world, rendered in Blender (blender_assets/LoadingCards.blend, scenes Card_<World>; scenery only, no
-- characters), 4K → 1824×1024 and split into two 912×1024 halves (Roblox caps images at 1024 per side), uploaded
-- as images. LoadingController shows the halves side by side with a slow drift, the world title + tagline and one
-- rotating tip. A world without a card falls back to its sky panorama (Worlds.<name>.Look.Skybox).
export type Card = {
	L: string, -- left half
	R: string, -- right half
	Tagline: string,
	Tips: { string },
}

local Cards: { [string]: Card } = {
	Prologue = {
		L = "rbxassetid://111841740424601",
		R = "rbxassetid://109193362496507",
		Tagline = "Press start. It's been a while.",
		Tips = {
			"Kai is the orange ▲, Miko the teal ●. Things in your color are yours to use.",
			"White things need both of you.",
			"Stuck? Pip drops a hint if you wait a little.",
		},
	},
	PixelPlains = {
		L = "rbxassetid://107955064004071",
		R = "rbxassetid://86349749900573",
		Tagline = "Where every adventure started.",
		Tips = {
			"Kai's ray gun freezes things in place. Frozen platforms make great stepping stones.",
			"Miko's grapple pulls blocks and swings from rings.",
			"Double jump, then dash: you reach much further than you think.",
			"Your progress saves at every checkpoint.",
		},
	},
	StarfallCastle = {
		L = "rbxassetid://92024846608441",
		R = "rbxassetid://129779703066332",
		Tagline = "The kingdom from the back of a notebook.",
		Tips = {
			"Miko's shield can send fireballs back where they came from.",
			"Kai's fire lights braziers and burns wooden doors.",
			"Level up to pick a new card for your kit.",
			"Down? Mash to get back up.",
		},
	},
	GlitchedCore = {
		L = "rbxassetid://133304373532070",
		R = "rbxassetid://111792677628289",
		Tagline = "The parts you never finished.",
		Tips = {
			"Kai can copy a piece of the world and paste it somewhere else.",
			"Miko's Layer Shift reaches into the code layer underneath the world.",
			"If it looks unfinished, it might still be useful.",
		},
	},
	Epilogue = {
		L = "rbxassetid://135780320504914",
		R = "rbxassetid://117692760130122",
		Tagline = "Continue?",
		Tips = {
			"Take your time. Nothing here can hurt you.",
		},
	},
}

return Cards
