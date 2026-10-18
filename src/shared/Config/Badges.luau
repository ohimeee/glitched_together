-- Badge ids (LAUNCH.md §4, Oct 19). Create them on Creator Hub (the game → Engagement → Badges), icons in
-- marketing/badges/ (tools/paint_style/badges.py). 0 = not created yet: that badge is skipped.
-- Both players get every badge (Services/Badges awards to DuoService.Players()).
return {
	-- leaving a world (WorldService.Advance), by world name
	Worlds = {
		Prologue = 1576512310218932, -- badge "The Title Screen" (badge_prologue.png)
		PixelPlains = 4016027219599332, -- badge "Pixel Plains" (badge_pixel_plains.png)
		StarfallCastle = 1089297389944119, -- badge "Starfall Castle" (badge_starfall_castle.png)
		GlitchedCore = 0, -- TODO: badge "The Glitched Core" (badge_glitched_core.png)
	},
	-- a boss beaten (BossService.Finished), by boss name
	Bosses = {
		CrusherKing = 1049996413689457, -- badge "Crusher King" (badge_crusher_king.png)
		HollowDragon = 2123905406430315, -- badge "Hollow Dragon" (badge_hollow_dragon.png)
		Unfinished = 0, -- TODO: badge "The Unfinished" (badge_the_unfinished.png)
	},
	-- CONTINUE? YES at the end of the credits
	Finished = 0, -- TODO: badge "Glitched Together" (badge_game_finished.png)
}
