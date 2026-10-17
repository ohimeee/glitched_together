-- Developer products (Creator Dashboard > the experience > Monetization > Developer Products; copy each id here).
-- 0 = not created yet: the button still shows (so the screen can be judged in Studio) but only says so when pressed.
-- Support = the end-credits tip jar (user, Oct 12): optional, gives nothing in game (no pay-to-win), and never
-- called charity: Roblox only allows that wording for real charity campaigns.
return {
	Support = {
		{ Id = 0, Robux = 10 }, -- TODO: product "Support: 10"
		{ Id = 0, Robux = 50 }, -- TODO: product "Support: 50"
		{ Id = 0, Robux = 100 }, -- TODO: product "Support: 100"
	},
	-- game passes (Creator Dashboard > Monetization > Passes), looks only (Config/Supporters)
	Passes = {
		Aura = { Id = 0, Robux = 99 }, -- TODO: pass "Glowing Aura"
		Tag = { Id = 0, Robux = 49 }, -- TODO: pass "Name Tag Color"
	},
}
