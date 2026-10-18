-- Closed beta (user, Oct 19): the game is public, but only approved testers can play. Testers apply in pairs via the
-- trailer's Google Form, join the Night Owl Interactive community, and the owner gives them the "Beta Tester" role.
-- Everyone else is sent back with a short note. Admins (Config/Admins) always pass. Enabled = false opens the game.
return {
	Enabled = true,
	GroupId = 129463626, -- Night Owl Interactive
	MinRank = 10, -- the "Beta Tester" role's rank (Community → Configure → Roles); higher roles pass too
	Message = "Glitched Together is in closed beta. Join the Night Owl Interactive community and apply to test it!",
}
