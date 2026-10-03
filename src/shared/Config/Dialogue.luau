-- Story lines and Pip hints (from the Story Bible). Cutscene ids match the story triggers table.
export type Line = { Speaker: string, Text: string }

local Cutscenes: { [string]: { Line } } = {
	Intro_Continue = {
		{ Speaker = "???", Text = "Your save file is still here. CONTINUE?" },
		{ Speaker = "Pip", Text = "PLAYER ONE! PLAYER TWO! You came back!" },
		{ Speaker = "Pip", Text = "...Why are you standing so far apart?" },
		{
			Speaker = "Pip",
			Text = "The Glitch is eating everything. The only way out is the exit at the end of the game.",
		},
		{ Speaker = "Pip", Text = "And it needs two players. You wrote that rule! Line 42!" },
	},
	Prologue_Gate = {
		{ Speaker = "Pip", Text = "This is going to be a long game." },
	},
	W1_Enter = {
		{
			Speaker = "Pip",
			Text = "Pixel Plains! Your very first level. Kai, you get the Pause Beam. Miko, the Grapple Line.",
		},
	},
	-- Memory 1 "Level One" (Story Line, World 1): after the Crusher King
	W1_Memory1 = {
		{ Speaker = "Pip", Text = "MEMORY FILE 1 OF 3: LEVEL_ONE.SAV. ...Loading." },
		{
			Speaker = "Memory",
			Text = "Kai's bedroom floor. Two twelve-year-olds, graph paper everywhere, building this exact level.",
		},
		{
			Speaker = "Memory",
			Text = "Miko draws a crown on the Crusher King and laughs so hard she drops the pencil.",
		},
		{ Speaker = "Miko", Text = "When we finish it, we launch it together. No matter what." },
		{ Speaker = "Kai", Text = "No matter what." },
		{ Speaker = "Memory", Text = "They pinky-promise." },
	},
	W1_End = {
		{ Speaker = "Kai", Text = "You promised." },
		{ Speaker = "Miko", Text = "So did you." },
		{ Speaker = "Pip", Text = "...Great teamwork, everyone!" },
	},
	W2_Enter = {
		{ Speaker = "Miko", Text = "Nice hat, wizard." },
		{ Speaker = "Pip", Text = "Fire Mage and Shield Knight! Just like you drew them." },
	},
	W2_End = {
		{ Speaker = "Kai", Text = "You were going to tell me?" },
		{ Speaker = "Miko", Text = "I waited for you. All day." },
	},
	-- Memory 3 "Launch Day" (Story Line, World 3): the end of 3-3 Memory Lane, before the final boss
	W3_Memory3 = {
		{ Speaker = "Pip", Text = "MEMORY FILE 3 OF 3: LAUNCH_DAY.SAV. ...Loading." },
		{ Speaker = "Memory", Text = "Launch day. Kai, fifteen, sits on his bed with his shoes on. He doesn't go." },
		{ Speaker = "Memory", Text = "Next morning he runs all the way to Miko's house. The moving truck is gone." },
		{ Speaker = "Memory", Text = "He goes home and deletes the project folder." },
		{ Speaker = "???", Text = "DELETE GLITCHED_TOGETHER? Y/N" },
		{ Speaker = "Miko", Text = "You came?" },
		{ Speaker = "Kai", Text = "You were already gone." },
		{ Speaker = "Pip", Text = "There's one more file. It was corrupted in the castle. It's from Miko." },
		{ Speaker = "Miko", Text = "I was scared. I'm sorry. You're my best friend, Player One." },
		{ Speaker = "Kai", Text = "...Let's finish it. Together." },
	},
	Final_Phase3 = {
		{ Speaker = "Pip", Text = "It's not a monster. It's the level you never finished." },
	},
	Epilogue_End = {
		{ Speaker = "Pip", Text = "Same time tomorrow, Player One? Player Two?" },
	},
}

-- Generic Pip nudges when a section has no hand-written hints. Hint 1 nudges; hint 2 points. Never the answer.
local GenericHints = {
	{
		"Two players, two halves of the puzzle. What can YOU see that they can't?",
		"INSERT HINT HERE. ...Try pinging something with Q!",
	},
	{ "Have you tried... talking? I hear it's great.", "Look for something only one of you can use." },
}

return { Cutscenes = Cutscenes, GenericHints = GenericHints }
