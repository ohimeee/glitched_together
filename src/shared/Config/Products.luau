-- Developer products (Creator Dashboard > the experience > Monetization > Developer Products; copy each id here).
-- 0 = not created yet: the button still shows (so the screen can be judged in Studio) but only says so when pressed.
-- Support = the end-credits tip jar (user, Oct 12): optional, gives nothing in game (no pay-to-win), and never
-- called charity: Roblox only allows that wording for real charity campaigns.
return {
	-- one product per price: Roblox can't charge a typed amount, so the "other amount" box picks the closest one.
	-- Quick = a button of its own in the tip jar.
	Support = {
		{ Id = 3719606066, Robux = 5 }, -- product "Support: 5"
		{ Id = 3719606297, Robux = 10, Quick = true }, -- product "Support: 10"
		{ Id = 3719606469, Robux = 25 }, -- product "Support: 25"
		{ Id = 3719606594, Robux = 50, Quick = true }, -- product "Support: 50"
		{ Id = 3719606685, Robux = 100, Quick = true }, -- product "Support: 100"
		{ Id = 3719606828, Robux = 250 }, -- product "Support: 250"
		{ Id = 3719606941, Robux = 500 }, -- product "Support: 500"
		{ Id = 3719607042, Robux = 1000 }, -- product "Support: 1000"
	},
	-- game passes (Creator Dashboard > Monetization > Passes), looks only (Config/Supporters)
	Passes = {
		Aura = { Id = 2036931847, Robux = 99 }, -- pass "Glowing Aura"
		Tag = { Id = 2040021635, Robux = 49 }, -- pass "Name Tag Color"
	},
}
