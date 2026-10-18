-- Pip's hints (user, Oct 19): per world, per checkpoint section (`cp` = the duo's checkpoint while they are there),
-- written for ONE role each: Kai never hears Miko's job and the other way round ("Both" when the job is shared).
--   off   spot as an offset (studs) from that section's checkpoint pad; the nearest spot within `r` wins, entries
--         without `off` are the section's fallback
--   phase boss phase (workspace BossPhase) the line is for
--   Kai2 / Miko2 / Both2  the more direct line (second hint, or after HintDeaths setbacks)
-- Key names are {Action} tokens (Util/Glyphs): the player sees their own device's key. HintService picks the line.
local V = Vector3.new

return {
	Prologue = {
		{
			cp = 1,
			Both = "Hop the big menu buttons. The last gap is long: {Jump}, {Jump} again in the air, then {Dash}!",
		},
		{ cp = 2, Both = "Jump into a wall, then {Jump} again to kick off it. Bounce between the two walls to climb!" },
		{
			cp = 3,
			Both = "Grab the swing point with {Swing} and let go with {Jump} at the far end. {Swing} grabs the rail too!",
		},
		{
			cp = 4,
			off = V(-8, 0, 12),
			r = 18,
			Both = "One of you stands on the bounce pad, the other {GroundPound}s it. Up goes your partner, onto the high plate!",
		},
		{
			cp = 4,
			off = V(0, 10, 56),
			r = 22,
			Both = "{GroundPound} the button to flip the fan upward, and your partner rides it up.",
		},
		{
			cp = 5,
			Both = "{GroundPound} the big button together, then both hold {Interact} on the heavy lever at the same time.",
		},
	},

	PixelPlains = {
		-- 1 Starter Meadow: two trials, one per role
		{
			cp = 1,
			Kai = "Your trial is the lane with the orange signs. Miko has her own!",
			Miko = "Your trial is the lane with the teal signs. Kai has his own!",
		},
		{
			cp = 1,
			off = V(-75, 0, 49),
			r = 45,
			Kai = "Freeze a rising pillar with {Tool1}, hop on, then freeze the next one.",
			Miko = "This is Kai's trial. Yours is the other lane!",
		},
		{
			cp = 1,
			off = V(-75, 0, 127),
			r = 30,
			Kai = "Freeze a crusher with {Tool1}, or wait for it to lift and run!",
			Miko = "This is Kai's trial. Yours is the other lane!",
		},
		{
			cp = 1,
			off = V(75, 20, 51),
			r = 40,
			Kai = "This is Miko's trial. Yours is the other lane!",
			Miko = "Grab the teal rings with {Swing} and swing across. {Jump} lets go.",
		},
		{
			cp = 1,
			off = V(90, 0, 111),
			r = 28,
			Kai = "This is Miko's trial. Yours is the other lane!",
			Miko = "Pull the crate with {Tool2} up to the cliff and use it as a step.",
		},
		{
			cp = 1,
			off = V(75, 27, 169),
			r = 22,
			Kai = "This is Miko's trial. Yours is the other lane!",
			Miko = "Pull the teal lever with {Tool2} to raise your bridge, then stand on the plate.",
		},
		-- 3 Windmill Hill: dropper chasm + windmill
		{
			cp = 3,
			off = V(0, 0, 52),
			r = 45,
			Kai = "Freeze a falling block with {Tool1} so Miko can swing on it. Your way over is the bridge her lever raises.",
			Miko = "When Kai freezes a falling block, grab it with {Swing} and swing over. Then pull the teal lever to raise his bridge.",
		},
		{
			cp = 3,
			off = V(0, -1, 140),
			r = 32,
			Kai = "Freeze the windmill arm with {Tool1} when it points across the pit, then run over it.",
			Miko = "Kai can freeze the windmill arm as a bridge, or swing the ring in the middle with {Swing}.",
		},
		{ cp = 4, Both = "Stand on both plates together to open the gate." },
		-- 5 Spring Snap
		{
			cp = 5,
			Kai = "Freeze the spring while it's squashed ({Tool1}). When Miko's on it, release with {Tool2} and she flies!",
			Miko = "Stand on the spring once Kai freezes it squashed. He releases, you fly up! Then pull the teal lever to raise his lift.",
		},
		-- 6 Crank Ferry
		{
			cp = 6,
			Kai = "Ride the ferry while Miko cranks. Freeze the crusher over it with {Tool1}!",
			Miko = "Hold {Interact} at your teal crank and push {Throttle} to send Kai across. He cranks you over after.",
			Kai2 = "Made it over? Your orange crank brings Miko across: hold {Interact} and push {Throttle}.",
		},
		-- 7 far cliff gate, then the cliff + the cloud shuttle
		{ cp = 7, Both = "Stand on both plates together to open the gate." },
		{
			cp = 7,
			off = V(0, 10, 45),
			r = 30,
			Kai = "Miko swings up and pulls a lever. That raises your lift!",
			Miko = "Swing the ring up the cliff with {Swing}, then pull the lever ({Tool2}) to raise Kai's lift.",
		},
		{
			cp = 7,
			off = V(0, 19, 104),
			r = 50,
			Kai = "Freeze the drifting cloud with {Tool1} when it lines up with both cliffs, then you both hop on.",
			Miko = "Wait for Kai to freeze the cloud in line with the cliffs, then hop across.",
		},
		-- 8 bounce pad, bat, fan
		{
			cp = 8,
			off = V(0, 0, 16),
			r = 15,
			Kai = "Stand on the bounce pad. When Miko pounds it, you fly up!",
			Miko = "Kai stands on the pad, you {GroundPound} it to launch him.",
		},
		{
			cp = 8,
			off = V(0, 30, 22),
			r = 16,
			Kai = "Freeze the bat with {Tool1} so Miko can grapple it.",
			Miko = "Kai freezes the bat, then it's your grapple point: {Swing}!",
		},
		{
			cp = 8,
			off = V(6, 23, 32),
			r = 15,
			Both = "{GroundPound} the button to turn the fan up, then ride the wind.",
		},
		{ cp = 9, Both = "Stand on the pad together and {GroundPound} at the same time!" },
		-- 10 Cloud Tower
		{
			cp = 10,
			Kai = "Freeze the elevator cloud at the top with {Tool1}, then hop up. Miko's lever raises your lift.",
			Miko = "Hop the elevator cloud when Kai freezes it. Swing the ring, then pull the lever ({Tool2}) to raise Kai's lift.",
		},
		{
			cp = 11,
			Kai = "Freeze a moving cloud ({Tool1}), hop on, then freeze the next one. Only one freeze at a time!",
			Miko = "Swing ring to ring with {Swing}. {Jump} lets go.",
		},
		{ cp = 12, Both = "Hold {Interact} on the heavy lever, both at the same time." },
		-- 13 Swing Cradle
		{
			cp = 13,
			Kai = "Freeze the cradle when it swings back to you ({Tool1}). Once Miko's in, release with {Tool2} to throw her over.",
			Miko = "Step into the cradle when Kai freezes it. Over there, pull the crate ({Tool2}) onto the heavy plate to raise his bridge.",
		},
		-- 14 Spin Cannon
		{
			cp = 14,
			Kai = "Freeze the cannon when it points at the island ({Tool1}). When Miko's on, release with {Tool2}!",
			Miko = "Climb on the cannon once Kai freezes it aimed at the island. Over there, pull the lever to raise his bridge.",
		},
		-- 15 Switch Towers
		{
			cp = 15,
			Kai = "Miko can't see your blocks: tell her when to flip them! Up top, stand on the plate to flip hers.",
			Miko = "Pull the lever ({Tool2}) when Kai calls it: it flips his blocks. Then he flips yours from the top.",
		},
		-- 16 Coin Factory belts
		{
			cp = 16,
			Kai = "Freeze the belt with {Tool1} and walk it, then freeze the next one.",
			Miko = "The belts are too fast. Wait for Kai to freeze each one, then walk across.",
		},
		-- 17 dropper pit
		{
			cp = 17,
			Kai = "Freeze a falling block with {Tool1} so Miko can swing on it. Her lever raises your bridge.",
			Miko = "Grab the block Kai freezes with {Swing} and swing over. Then pull the lever to raise his bridge.",
		},
		-- 18 crate door, crusher belt
		{
			cp = 18,
			off = V(0, 0, 49),
			r = 28,
			Kai = "Freeze the sliding door with {Tool1} while it's open!",
			Miko = "Pull the crate off the shelf ({Tool2}) onto the heavy plate. It holds the inner gate open.",
		},
		{
			cp = 18,
			off = V(0, 0, 86),
			r = 40,
			Kai = "Freeze a crusher with {Tool1}, then run the belt.",
			Miko = "Run under the crushers when they lift, or when Kai freezes one.",
		},
		{ cp = 19, Both = "Watch the blobs' rhythm and jump them as they pass. No need to rush!" },
		-- 20 Coin Press
		{
			cp = 20,
			Kai = "Freeze the crusher above the crate with {Tool1} so it can't smash it.",
			Miko = "Pull the crate in short hops ({Tool2}), only under a crusher Kai froze. Get it onto the plate at the end.",
		},
		-- 22 Fire Bar Run
		{
			cp = 22,
			Kai = "Walk the glass gallery beside Miko. Freeze the fire bar ahead of her ({Tool1}) when it points down the corridor.",
			Miko = "Swing over the chasm, then wait for Kai to freeze each fire bar before you pass.",
		},
		{
			cp = 23,
			Kai = "Miko's lever raises your lift. Then stand on the plates together.",
			Miko = "Pull the lever ({Tool2}) to raise Kai's lift, then both of you stand on the plates.",
		},
		-- 24-25 Coin Bonk Stairs
		{
			cp = 24,
			Kai = "Miko pulls the ? block and a coin step pops out and sinks. Freeze it ({Tool1}) at a height you can hop.",
			Miko = "Pull the ? block ({Tool2}) for a coin step. Kai freezes it, then you both hop up.",
		},
		{
			cp = 25,
			Kai = "Freeze each new step as it sinks. A new freeze drops the old step, so jump as you freeze!",
			Miko = "Stand on the frozen step and pull the next ? block ({Tool2}). Climb fast: the old step drops.",
		},
		-- 26 Warp Pipe Swap (the lanes swap halfway)
		{
			cp = 26,
			off = V(-12, 34, 42),
			r = 30,
			Kai = "Freeze the falling block with {Tool1} and hop on it.",
			Miko = "Your lane is on the other side of the wall!",
		},
		{
			cp = 26,
			off = V(12, 16, 42),
			r = 30,
			Kai = "Your lane is on the other side of the wall!",
			Miko = "Swing the rings with {Swing}.",
		},
		{ cp = 26, off = V(0, 3, 86), r = 22, Both = "Both {GroundPound} your pipe at the same time to swap sides!" },
		{
			cp = 26,
			off = V(12, -1, 122),
			r = 30,
			Kai = "Freeze the spinning arm with {Tool1} and run across it.",
			Miko = "You swapped! Your rings are in the other lane now.",
		},
		{
			cp = 26,
			off = V(-12, 16, 122),
			r = 30,
			Kai = "You swapped! Your spinning arm is in the other lane now.",
			Miko = "Swing the rings with {Swing}.",
		},
		{ cp = 27, Both = "Keep moving! {Swing} grabs a rail, jump the gaps." },
		-- 28 Crusher King
		{
			cp = 28,
			phase = 1,
			Kai = "When a fist rests on the floor, freeze it ({Tool1})! Miko pounds the crystal on it.",
			Miko = "Jump on the fist Kai froze and {GroundPound} the wrist crystal.",
		},
		{
			cp = 28,
			phase = 2,
			Kai = "Freeze a thrown block mid-air ({Tool1}) so Miko can swing to the King's lap.",
			Miko = "Grab a frozen block with {Swing}, swing to his lap, climb up and {GroundPound} both shoulder crystals.",
		},
		{
			cp = 28,
			phase = 3,
			Kai = "Freeze the whole King with {Tool1}! That drops his shield.",
			Miko = "When Kai freezes the King, climb up and pull his crown off with {Tool2}!",
		},
	},

	StarfallCastle = {
		-- 1 Gatehouse: the tutorial room
		{
			cp = 1,
			Kai = "Hold {Tool1} to throw fireballs. The way on is up the corridor!",
			Miko = "{Tool1} swings your sword, hold {Tool2} to raise your shield. Up the corridor we go!",
		},
		-- 2 Brazier Corridor → Barracks → the split wall
		{
			cp = 2,
			off = V(0, 0, 13),
			r = 14,
			Kai = "That wooden door burns! Aim at it and press {Ignite}.",
			Miko = "Kai's fire burns wood. Let him light that door, you keep watch.",
		},
		{
			cp = 2,
			off = V(0, 0, 41),
			r = 26,
			Kai = "Shield guards block from the front: let Miko hold their attention, then fireball their backs. Slimes split, so burn the bits with {Tool2}!",
			Miko = "Hold {Tool2} near a shield guard and it turns to you, then Kai hits its back. {Dash} charges through a crowd!",
		},
		{
			cp = 2,
			off = V(-15, 0, 64),
			r = 12,
			Kai = "Not your door! Iron bars on the right side of this wall: {Dash} blinks you straight through them.",
			Miko = "A cracked wall! {Dash} and charge right through it.",
		},
		{
			cp = 2,
			off = V(15, 0, 64),
			r = 12,
			Kai = "Iron bars! {Dash} blinks you through them, there's a plate behind.",
			Miko = "Bars aren't for you. Find the cracked wall on the left and {Dash} through it!",
		},
		-- 3 Split Hall: plate behind the bars + plate in the hall, held together
		{
			cp = 3,
			Kai = "Stay on the plate behind the iron bars. The gate opens when Miko stands on hers too!",
			Miko = "Clear the hall, then stand on the plate at the far left end. Kai holds the other one behind the bars.",
			Kai2 = "Behind the bars on the right: blink in with {Dash} and stand on the plate. Hold it!",
			Miko2 = "The far left plate, by the gate! You and Kai both have to stand on yours at the same time.",
		},
		-- 4 Dark Library: the teal crystal only takes bounced shots
		{
			cp = 4,
			Kai = "That teal crystal ignores your fire. Shoot into Miko's raised shield so it bounces!",
			Miko = "Stand between Kai and the teal crystal, hold {Tool2} and face the crystal. His shots bounce off you into it.",
		},
		-- 5 Spike Roller Hall
		{
			cp = 5,
			Kai = "Miko can stop the spike roller. While it's stuck, {Dash} blink through it and stand on the plate at the end.",
			Miko = "Face the spike roller and hold {Tool2}: it can't get past your shield. Keep holding until Kai reaches the plate.",
		},
		-- 6 Mirror Room: two crystals inside 1.5 s
		{
			cp = 6,
			Kai = "Light both crystals together: shoot the orange one, then quickly shoot Miko's shield so it bounces to the teal one.",
			Miko = "Hold {Tool2} facing the mirror in the corner. Kai shoots your shield and the bounce reaches the teal crystal in the nook.",
			Kai2 = "Fire twice fast: orange crystal, then Miko's shield. Both have to glow at the same time!",
		},
		-- 7 Torch Run: the dark trapped floor
		{
			cp = 7,
			Kai = "{Dash} blink through the bars into the side gallery and light the braziers ahead of Miko with {Ignite}. End on the plate!",
			Miko = "The floor is trapped! Wait for Kai's firelight and never step on a tile with a red X. Stop on the plate at the end.",
		},
		-- 8 Golem Hall
		{
			cp = 8,
			Kai = "Set the wooden pillars on fire with {Ignite}, then stay out of the golem's way!",
			Miko = "Stand in front of a burning pillar with {Tool2} up. When the golem charges, {Dash} aside so it smashes the pillar.",
		},
		-- 9 Siege Cart
		{
			cp = 9,
			Kai = "Both of you in the cart! Burn every barricade ahead with {Ignite} before you hit it.",
			Miko = "Both of you in the cart! Hold {Tool2} toward the archers on the sides.",
		},
		-- 11 Powder Hall: the Ember Fuse
		{
			cp = 11,
			Kai = "Light the fuse post with {Ignite}. When the spark stops at a gap, re-light it within 3 seconds!",
			Miko = "Walk beside the spark and hold {Tool2} toward the arrow trap. Arrows put the spark out!",
			Kai2 = "Fuse post in the corner first ({Ignite}), then re-light each gap. Fireball skeletons off Miko too!",
			Miko2 = "Keep your shield between the arrow trap and the spark, all the way to the keg.",
		},
		-- 12 Hollow Dragon
		{
			cp = 12,
			phase = 1,
			Kai = "Shoot the glowing scales on its legs while it breathes. Stay behind Miko's shield!",
			Miko = "When it breathes, face its mouth with {Tool2} up. Kai stays safe behind you.",
		},
		{
			cp = 12,
			phase = 2,
			Kai = "When it lands, drop your Meteor on it with {Ultimate}! Killing minions charges it.",
			Miko = "{Dash} the minions into Kai's flame wall. Every kill charges his Meteor!",
		},
		{
			cp = 12,
			phase = 3,
			Kai = "Plain fire won't hurt it now. Shoot into Miko's shield so the bounce hits its heart!",
			Miko = "Stand in the gap of the wall with {Tool2} up. Kai shoots your shield and the bounce hits the heart.",
		},
	},

	GlitchedCore = {
		-- 1 Missing Textures: two trials over the void
		{
			cp = 1,
			off = V(-30, 0, 76),
			r = 55,
			Kai = "Copy the orange plank with {Tool1}, hold {Tool2} and let go to paste it ahead. Paste, step on, paste again!",
			Miko = "This is Kai's trial. Yours is the other one!",
		},
		{
			cp = 1,
			off = V(30, 2, 76),
			r = 55,
			Kai = "This is Miko's trial. Yours is the other one!",
			Miko = "Press {Tool1} to see the Code Layer. The teal stones are solid for you while it's on!",
		},
		-- 2 Wire Circuit
		{
			cp = 2,
			Kai = "Copy the orange block ({Tool1}). Miko can see two hidden sockets on the floor: paste it onto each one!",
			Miko = "Switch to the Code Layer ({Tool1}) and find the two sockets on the floor. Tell Kai where to paste!",
		},
		-- 3 Door.exe
		{
			cp = 3,
			Kai = "Copy the crate Miko pulls out ({Tool1}), then paste it onto the plate she reveals. It holds the door!",
			Miko = "Stand on the door plate, switch layers, pull out the crate ({Tool2}) for Kai to copy, then pull out the plate.",
			Kai2 = "Crate first: copy it while it's out. Then paste the copy onto the code plate past the door.",
			Miko2 = "Only one thing comes out at a time: crate first (Kai copies it), then the plate for his paste.",
		},
		-- 4 Ghost Bridge
		{
			cp = 4,
			Kai = "Cross on the plank Miko pulls out, copy it ({Tool1}), then paste it over the second gap for her.",
			Miko = "Switch layers, walk the code plank, then pull it out ({Tool2}) so Kai can cross too.",
		},
		-- 5 Phantom Steps
		{
			cp = 5,
			Kai = "You can't see these steps. Listen to Miko and jump when she says go!",
			Miko = "Switch layers and watch the frame sign. Tell Kai which side and when to jump!",
		},
		{ cp = 6, Both = "{GroundPound} the white button together, at the same time!" },
		-- 7 Layer Hop
		{
			cp = 7,
			Kai = "Wait on a grey step. Miko pulls out the next teal step for you, then climb it.",
			Miko = "Climb the teal steps in the Code Layer. When Kai's on a grey step, pull out the next teal one for him ({Tool2}).",
		},
		-- 8 Counterweight
		{
			cp = 8,
			Kai = "The heavier pan sinks and the other one rises. Copy the anvil ({Tool1}) to paste more weight!",
			Miko = "Pull the anvil out of the Code Layer ({Tool2}) so it weighs in. Weigh one pan down to lift the other.",
		},
		-- 9 Title Echo (no tools)
		{
			cp = 9,
			Both = "One of you holds the start plate while the other crosses. Over there, stand on the far plate for your partner!",
		},
		-- 10 Plains Echo (Pixel Plains kit)
		{
			cp = 10,
			Kai = "Your freeze is back! Freeze a falling block ({Tool1}) for Miko, and freeze the crusher over your bridge.",
			Miko = "Your grapple is back! Swing on the block Kai freezes, then pull the lever ({Tool2}) to raise his bridge.",
		},
		-- 11 Castle Echo (castle kit)
		{
			cp = 11,
			Kai = "Fire into Miko's shield through the gap in the wall. The bounce lights the crystal!",
			Miko = "Face the crystal through the gap and hold {Tool2}. Kai shoots your shield, the bounce lights it.",
		},
		-- 12 Unloaded Chunk
		{
			cp = 12,
			Kai = "Hold {Interact} at the terminal and steer the light with {Throttle}. Miko tells you where the real path is!",
			Miko = "Only real tiles in the light are safe. Check the Code Layer for the path and tell Kai where to point it.",
		},
		-- 13 The Unfinished
		{
			cp = 13,
			phase = 1,
			Kai = "When an arm lies flat, freeze it ({Tool1})! Miko pounds the crystal on its wrist.",
			Miko = "Jump onto the arm Kai froze and {GroundPound} the teal crystal on its wrist.",
		},
		{
			cp = 13,
			phase = 2,
			Kai = "Plain fire won't hurt it. Shoot into Miko's shield so the bounce hits the open core!",
			Miko = "Shield up ({Tool2}) toward the breath, then face the core so Kai's shots bounce into it.",
		},
		{ cp = 13, phase = 3, Both = "Nothing hurts it right now. Just {Jump} the rings and hang on!" },
		{
			cp = 13,
			phase = 4,
			Kai = "Copy each piece Miko pulls out ({Tool1}) and paste it onto its glowing slot ({Tool2}, {Rotate} to turn it).",
			Miko = "Switch layers, pull a floating piece out ({Tool2}), and let Kai copy it into its slot. One at a time!",
		},
	},

	Epilogue = {
		{ cp = 1, Both = "Walk up the hill together. Something's waiting at the top." },
	},
}
