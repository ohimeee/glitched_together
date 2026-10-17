-- Developer products (Creator Dashboard > the experience > Monetization > Developer Products; copy each id here).
-- 0 = not created yet: the button still shows (so the screen can be judged in Studio) but only says so when pressed.
-- Support = the end-credits tip jar (user, Oct 12): optional, gives nothing in game (no pay-to-win), and never
-- called charity: Roblox only allows that wording for real charity campaigns.
return {
	-- one product per price: Roblox can't charge a typed amount, so the "other amount" box picks the closest one.
	-- Quick = a button of its own in the tip jar.
	Support = {
		{ Id = 0, Robux = 5 }, -- TODO: product "Support: 5"
		{ Id = 0, Robux = 10, Quick = true }, -- TODO: product "Support: 10"
		{ Id = 0, Robux = 25 }, -- TODO: product "Support: 25"
		{ Id = 0, Robux = 50, Quick = true }, -- TODO: product "Support: 50"
		{ Id = 0, Robux = 100, Quick = true }, -- TODO: product "Support: 100"
		{ Id = 0, Robux = 250 }, -- TODO: product "Support: 250"
		{ Id = 0, Robux = 500 }, -- TODO: product "Support: 500"
		{ Id = 0, Robux = 1000 }, -- TODO: product "Support: 1000"
	},
	-- game passes (Creator Dashboard > Monetization > Passes), looks only (Config/Supporters)
	Passes = {
		Aura = { Id = 0, Robux = 99 }, -- TODO: pass "Glowing Aura"
		Tag = { Id = 0, Robux = 49 }, -- TODO: pass "Name Tag Color"
	},
}
