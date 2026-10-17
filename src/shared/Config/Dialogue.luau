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
	-- Section reveals (CutsceneService builds the fly-over from the section; Greybox revealTrigger)
	Reveal_WindmillHill = {
		{
			Speaker = "Pip",
			Text = "Windmill Hill! Kai, freeze anything that falls. Miko, swing on whatever he freezes!",
		},
	},
	Reveal_SpringYard = {
		{ Speaker = "Pip", Text = "The Spring Yard. Everything here bounces. Including bad ideas." },
	},
	Reveal_CloudClimb = {
		{ Speaker = "Pip", Text = "Cloud Climb! It's a long way up. Don't look down. Okay, look down a little." },
	},
	Reveal_CloudTower = {
		{ Speaker = "Pip", Text = "A tower made of clouds. Freeze the elevator cloud before it floats off!" },
	},
	Reveal_SwingWorks = {
		{ Speaker = "Pip", Text = "Swing Works! Whoever built this really, REALLY liked ropes." },
	},
	Reveal_SwitchTowers = {
		{ Speaker = "Pip", Text = "Two towers, two switches. You flip hers, she flips yours. Teamwork!" },
	},
	Reveal_CoinFactory = {
		{ Speaker = "Pip", Text = "The Coin Factory. Belts, crushers and timed doors. Classic you two." },
	},
	Reveal_CoinPress = {
		{ Speaker = "Pip", Text = "The Coin Press. Hop the blobs, pull the crate through and mind the stompy bits!" },
	},
	Reveal_FirebarRun = {
		{ Speaker = "Pip", Text = "Fire bars! Kai, the freeze is yours. Miko, keep moving!" },
	},
	Reveal_CoinBonk = {
		{ Speaker = "Pip", Text = "Bonk the blocks, build the stairs. Very scientific." },
	},
	Reveal_PipeSwap = {
		{ Speaker = "Pip", Text = "Warp pipes! Pound at the same time and you swap places." },
	},
	Reveal_PastePast = {
		{ Speaker = "Pip", Text = "A locked door. Kai, you're the copy machine. Miko, you see the code." },
	},
	Reveal_WireMaze = {
		{ Speaker = "Pip", Text = "The Wire Maze. Nothing here is finished. Including the floor." },
	},
	Reveal_LayerHop = {
		{ Speaker = "Pip", Text = "Layers on layers. Miko, tell him where the floor really is!" },
	},
	Reveal_Counterweight = {
		{ Speaker = "Pip", Text = "A giant scale. Something has to go on the other side..." },
	},
	Reveal_TitleEcho = {
		{ Speaker = "Pip", Text = "Memory Lane. This is... the title screen we made. Remember?" },
	},
	Reveal_PlainsEcho = {
		{ Speaker = "Pip", Text = "Pixel Plains again? It looks smaller than I remember." },
	},
	Reveal_CastleEcho = {
		{ Speaker = "Pip", Text = "The castle! Mage and Knight, one more time." },
	},
	Reveal_UnloadedChunk = {
		{ Speaker = "Pip", Text = "This part never loaded. Kai, light the way with the scanner!" },
	},
	-- The Crusher King's arrival (Greybox CamPath_W1_BossIntro)
	W1_BossIntro = {
		{ Speaker = "Pip", Text = "Is that... the Crusher King? You drew him on graph paper!" },
		{ Speaker = "???", Text = "CRUSH. THE. PLAYERS." },
		{ Speaker = "Pip", Text = "Kai, freeze his fists! Miko, smash those crystals!" },
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
	-- The Hollow Dragon's arrival (Greybox CamPath_W2_BossIntro)
	W2_BossIntro = {
		{ Speaker = "Kai", Text = "Our dragon. We spent a whole weekend on its wings." },
		{ Speaker = "Pip", Text = "It's hollow inside... the Glitch ate right through it!" },
		{ Speaker = "Pip", Text = "Miko, shield up when it breathes! Kai, burn the scales it shows you!" },
	},
	-- Memory 2 "The Hidden Room" (Story Line, World 2): behind the throne, after the dragon
	W2_Memory2 = {
		{ Speaker = "Pip", Text = "MEMORY FILE 2 OF 3: HIDDEN_ROOM.SAV. ...Loading." },
		{ Speaker = "Memory", Text = "A room behind the throne that Kai never knew about. Miko built it in secret." },
		{
			Speaker = "Memory",
			Text = "Miko, fifteen, alone at her computer at night. She's crying, typing a long message.",
		},
		{ Speaker = "Memory", Text = "She hides it in this room." },
		{ Speaker = "Miko", Text = "I'll show him at launch. He'll understand." },
		{ Speaker = "???", Text = "FILE CORRUPTED." },
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
	-- The Unfinished's arrival (Greybox CamPath_W3_BossIntro); phase 3 says what it really is, not this
	W3_BossIntro = {
		{ Speaker = "Pip", Text = "WARNING: FILE TOO BIG TO OPEN. ...It's opening itself!" },
		{ Speaker = "Miko", Text = "It's made of pieces of every world we built." },
		{ Speaker = "Pip", Text = "It'll keep changing the rules. Use whatever tools it hands you!" },
	},
	Final_Phase3 = {
		{ Speaker = "Pip", Text = "It's not a monster. It's the level you never finished." },
	},
	-- Final_Save (Story Line): both pounded the SAVE button; the golem becomes the finished level
	Final_Save = {
		{ Speaker = "???", Text = "SAVING GLITCHED_TOGETHER... 100%" },
		{ Speaker = "Pip", Text = "It stopped. It's... it's not glitching anymore." },
		{ Speaker = "Miko", Text = "We finished it, Kai. We actually finished it." },
		{ Speaker = "Kai", Text = "Took us long enough." },
	},
	-- Epilogue "Continue" (Story Line): Pip's goodbye on the hilltop under the new starry sky
	Epilogue_Goodbye = {
		{ Speaker = "Pip", Text = "Look at it. Every world, finished. No holes, no static. Just stars." },
		{
			Speaker = "Pip",
			Text = "I was a placeholder, you know. A helper you made up for a game that never shipped.",
		},
		{ Speaker = "Pip", Text = "Thanks for coming back for me. For it. For each other." },
		{ Speaker = "Pip", Text = "Same time tomorrow, Player One? Player Two?" },
	},
	-- ...then the real world (Story Line steps 2-4), then the credits roll (CreditsController)
	Epilogue_End = {
		{ Speaker = "Memory", Text = "Two bedrooms, two screens, far apart. STARFALL KINGDOM: 100% COMPLETE." },
		{ Speaker = "Miko", Text = "hey" },
		{ Speaker = "Memory", Text = "She deletes it. Types it again. Sends it." },
		{ Speaker = "Memory", Text = "Across the country, Kai's phone buzzes. He smiles, and calls her." },
		{ Speaker = "Kai", Text = "Hey, Player Two." },
	},
}

-- Generic Pip nudges when a section has no hand-written hints. Hint 1 nudges; hint 2 points. Never the answer.
local GenericHints = {
	{
		"Two players, two halves of the puzzle. What can YOU see that they can't?",
		"INSERT HINT HERE. ...Try pinging something with {Ping}!",
	},
	{ "Have you tried... talking? I hear it's great.", "Look for something only one of you can use." },
}

return { Cutscenes = Cutscenes, GenericHints = GenericHints }
