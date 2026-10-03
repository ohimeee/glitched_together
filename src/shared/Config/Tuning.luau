-- Every number from mechanics.md. First-pass values in studs and seconds; tune after playtests.
local GRAVITY = 196.2

local function jumpVelocity(height: number): number
	return math.sqrt(2 * GRAVITY * height)
end

return {
	Gravity = GRAVITY,
	JumpVelocity = jumpVelocity, -- launch speed for a height in studs (level builders use it for launchers)

	-- Lobby
	LockTime = 5,

	-- Shared moveset
	WalkSpeed = 16,
	SprintSpeed = 24,
	CrouchSpeed = 8,
	JumpHeight = 7.5,
	DoubleJumpVelocity = jumpVelocity(6),
	DashDistance = 14,
	DashTime = 0.18,
	GroundDashCooldown = 0.6,
	PoundHang = 0.15,
	PoundFallSpeed = 110,
	PoundStunRadius = 5,
	BounceLaunchVelocity = jumpVelocity(22),
	WallClingSlide = 4,
	WallClingTime = 1.5,
	WallJumpUp = jumpVelocity(9),
	WallJumpAway = 40,
	CoyoteTime = 0.12,
	JumpBuffer = 0.1,
	-- crouch + jump while moving (research.md: ITT keeps momentum on a crouch-jump). Speed is held for
	-- LongJumpHold s (~20 studs), so long jump + double + dash stays near the sprint reach (~41, CLAUDE.md table).
	LongJumpForward = 40,
	LongJumpUp = jumpVelocity(5),
	LongJumpHold = 0.45,
	LedgeAssistReach = 2.5, -- studs a near-miss ledge pulls you up
	MobileAutoSprintAfter = 1.5,

	-- Follow camera (CameraController): mouse-look, cursor locked, crosshair = screen center
	Camera = {
		MouseSensitivity = 0.0035, -- radians per pixel
		StickSpeed = 3.2, -- radians per second at full stick
		TouchSensitivity = 0.006,
		PitchMin = -75, -- degrees (looking down)
		PitchMax = 70, -- degrees (looking up)
		Distance = 16, -- studs behind the pivot
		MinDistance = 6,
		MaxDistance = 40,
		PivotHeight = 2.2, -- studs above the root (head height)
		Shoulder = Vector3.new(2.4, 0.8, 0), -- camera-space offset while holding a tool (crosshair beside the body)
		GroundClearance = 1.5, -- looking up: the camera never sinks below the floor, it looks up from low
		FOV = 74,
		SwingFovBoost = 10, -- degrees wider at full swing speed (Spider-Man trick: speed reads bigger)
	},

	-- Traversal objects
	SwingRange = 18,
	SwingPromptRange = 30, -- "[F] SWING" chips show this close (SwingPromptController); bright inside SwingRange
	SwingBoost = 1.2,
	-- It Takes Two style swing (MovementController): an assisted pendulum that settles into a steady arc forward
	-- along the way you came; you only time the jump. A/D slowly turn it.
	SwingGravity = 120, -- studs/s² on the rope: a bit under world gravity so the arc reads big and weighty
	SwingArc = 60, -- degrees each side of straight down the assist settles on
	SwingAssist = 1.6, -- per second: how fast the swing eases into that arc (from a standstill or a fast run-up)
	SwingMaxSpeed = 80, -- studs/s cap (no flings)
	SwingBounce = 0.3, -- hitting a wall mid-swing bounces back at this fraction of the speed
	SwingStuckTime = 0.35, -- seconds blocked before the swing lets go (you drop and stand up)
	SwingJumpForward = 16, -- studs/s added forward along the swing when you jump off
	SwingTurnRate = 1.2, -- radians/s: A/D slowly turn the swing's plane
	SwingLean = 0.85, -- 0 = upright, 1 = body lies fully along the rope
	SwingMinLength = 7, -- studs: grabbing very close lets the rope out to this
	SwingMaxLength = 16, -- studs: a far grab reels in to this (zips toward the point), then swings
	SwingReelSpeed = 40, -- studs/s the rope reels in
	SwingGroundGap = 5.5, -- studs: the rope is short enough that the bottom of the arc clears the floor by this
	GrindSpeed = 40,
	GrindGrabRange = 8,
	GrindCatchRange = 3.5, -- falling onto a rail catches it within this (root to rail top; the grind pose sits ~3 up)
	VentForce = 90,
	DuoPoundWindow = 0.5,
	HeavyLeverHold = 1,
	HeavyLeverWindow = 1,

	-- Health
	Hearts = 3,
	HeartRegenEvery = 5,
	HpRegen = { Delay = 4, PerSecond = 5 }, -- castle HP: s without a hit before it refills, then HP per second
	HitInvuln = 1,
	KillZoneRespawnDelay = 1,
	SafePosEvery = 0.25,
	VoidDrop = 25, -- studs below your last safe ground, falling with nothing under you (VoidProbe deep) = a fall
	VoidProbe = 150,
	LeverThrow = 40, -- degrees a pull lever swings over when pulled (and back when pulled again)
	LeverSwingTime = 0.35,
	SwitchGhost = 0.78, -- transparency of the switch-block set that isn't solid (still readable: where you'll land next)
	RespawnBackTime = 1.5, -- auto-respawn where you stood this many seconds before going down (off the hazard)
	DownedRespawn = 5,
	DownedRespawnBoss = 8,
	MashStep = 0.15,
	ReviveHold = 1.5,
	ReviveRange = 6,
	GhostSpeed = 8,
	CastleHP = { Kai = 100, Miko = 140 },
	ReviveHP = 30,

	-- Co-op systems
	PingLife = 4,
	CamSyncRate = 10,
	HintAfter = { 20, 45 },
	PartnerWaitTime = 120,
	SlackRange = 5, -- extra studs allowed in server range checks for lag

	-- World 1
	PauseBeam = { Range = 60, Duration = 4, AimCone = 6 },
	-- Tool effects (ToolFxController): wind-up → effect → impact, all short so they never hide the play space
	ToolFx = {
		BeamTime = 0.35, -- the Pause Beam stays visible this long after a freeze
		RingSize = 9, -- studs: freeze / release shockwave at the target
		RingTime = 0.45,
		RopeWidth = 0.35,
		ScanTime = 0.45, -- Copy: the scan line sweeping over the copied object
		PasteSnapTime = 0.3, -- Paste: ghost outline → solid
		WipeTime = 0.35, -- Layer Shift: teal line across Miko's screen
		-- Layer Shift seen by others (ShiftCloakController): a teal line sweeps her body away / back
		CloakTime = 0.55,
		CloakOutline = 0.85, -- partner outline transparency while she's in the Code Layer (the faint hint)
		CloakRingSize = 4.5,
		CloakFlickerBand = 0.7, -- studs around the line where parts glitch-flicker
		CloakPixels = 2, -- pixels shed per frame during the sweep
	},
	-- Level contraptions (ContraptionService); levels can override per part with attributes
	Contraptions = {
		ConveyorSpeed = 26, -- faster than sprint (24), so a running belt can't be walked up
		DropEvery = 1.2,
		DropSize = Vector3.new(6, 6, 6),
		DropLifetime = 5,
		-- dropped blocks are moved by code, not gravity: they start slow and speed up, so Kai has a window to
		-- freeze one near the top (user, Oct 4: they fell too fast to freeze). studs/s, studs/s², studs/s
		DropSpeed = 4,
		DropAccel = 14,
		DropMaxSpeed = 70,
		ChaseSpeed = 30, -- Glitch Chase wall; grinding is 40, so the duo stays ahead if they keep moving
		ChaseRetryDelay = 2,
		ChaseWarmup = 1.5, -- seconds between the duo stepping onto the start and the wall moving
		-- Blinkers (Glitched Core phantom steps): solid only on their frames of a shared 4-frame clock
		FrameTime = 1.2,
		FrameCount = 4,
		-- Coin Bonk Stairs: steps popped from a "?" block sink slowly enough for Kai to freeze them at a height
		CoinSize = Vector3.new(6, 2, 6),
		CoinFallSpeed = 9, -- studs/s: a 9-stud band of useful heights = about a second to freeze in
		CoinFall = 40, -- studs it sinks before it vanishes
		CartSpeed = 11, -- castle Siege Cart (studs/s): Ignite reaches 30, so ~2.5 s to burn the barricade ahead
		CartStationPause = 2.5, -- s the cart rests at a midway station (crashes after it restart there)
		CartStationHeal = 50, -- HP back for both at the station
		-- Glitched Core Unloaded Chunk: floor tiles exist only inside the cone of Kai's scanner terminal
		ScanRange = 120, -- studs from the scanner
		ScanAngle = 13, -- degrees either side of where it points (flat)
		ScanLinger = 0.9, -- s a tile stays solid after the cone leaves it (a little slack, like a fade)
		-- Glitched Core Counterweight: a two-pan scale; a player weighs 1, weights carry their own `Weight`
		PlayerWeight = 1,
		ScaleGain = 0.5, -- progress per unit of weight difference (1 heavier = fully over)
	},
	KitZoneCheck = 0.2, -- s between Memory Lane kit-zone checks (WorldService)
	-- Release as a launcher (obstacles.md Part 3): Kai releasing a Freezable with a LaunchVelocity attribute flings
	-- whoever stands on it or swings from it
	ReleaseLaunch = {
		RideDepth = 4.5, -- studs below the root that still count as standing on it
		MaxHold = 1.6, -- s: horizontal launch speed is held (no air-control braking) until landing, at most this long
	},
	-- Stations (StationService): hold E at a crank, forward / back drives a linked Driven mover
	Station = {
		Reach = 8, -- studs to grab the crank; walking (or being knocked) 4 further lets go
		WheelSpin = 4, -- rad/s the crank wheel turns while cranking
		PressDebounce = 0.3, -- s: E presses closer than this count once
	},
	GrappleLine = {
		Range = 45,
		Boost = 1.3,
		AimCone = 8,
		PullRange = 35,
		PullTime = 0.4,
		PullDistance = 6,
		PullCooldown = 1,
		MaxMass = 50,
	},

	-- World 2 (castle)
	Castle = { Tether = 60, ShieldArc = 120, ShieldSpeedMult = 0.6, TauntRadius = 20, ReflectMult = 1.5 },
	FireMage = {
		Fireball = { Damage = 10, Cooldown = 0.35, Speed = 80 },
		FlameWall = { Tick = 4, TickEvery = 0.5, Cooldown = 8, Length = 12, Life = 5 },
		Ignite = { Cooldown = 1, Range = 30 },
		Blink = { Distance = 10, Cooldown = 3 },
		Meteor = { Damage = 40, Charge = 300, Radius = 12, Cast = 1.2 },
	},
	-- castle Torch Run: braziers burn out, spike traps show only in their firelight
	TorchRun = { BurnTime = 6, Reveal = 12, TrapDamage = 30 },
	-- castle Ember Fuse: Kai lights a fuse to the keg, arrow traps shoot at the spark, Miko shields it
	Fuse = {
		Speed = 5, -- studs/s along the fuse: walking pace, so Miko can keep beside it
		BreakWait = 3, -- s a spark waits at a break for Kai's Ignite before it fizzles
		SnuffRadius = 2, -- an enemy shot passing this close puts the spark out
		TrapEvery = 2.2, -- s between one trap's arrows
		TrapRange = 38,
		ArrowSpeed = 40,
		ArrowDamage = 10,
	},
	ShieldKnight = {
		Sword = { Damage = { 8, 8, 14 } },
		Charge = { Damage = 12, Cooldown = 6, Distance = 16 },
		Rally = { Damage = 15, Charge = 250, Radius = 14, Stun = 2 },
	},
	XpLevels = { 100, 250 },
	Combat = {
		Aggro = 24, -- enemies wake up when a player is this close
		OrbSpeed = 40, -- XP orbs fly to the nearest player
		OrbPickup = 3,
		SwordCombo = { Window = 0.8, Swing = 0.35, Width = 7, Reach = 6 },
		Knockback = 12, -- studs, Shield Charge
		ChargedWindow = 1.5, -- enemies shoved by a charge take double Flame Wall damage for this long
		ShieldDown = 3, -- a charged Shield Guard drops its shield for this long
		ShieldHitRadius = 3.5, -- projectiles this close to a blocking Miko hit the shield
		BodyHitRadius = 1.8, -- enemy shots passing this close (flat) to a player's middle hit them
		ShieldStopRange = 7, -- a ShieldStop hazard (spike roller) this close in front of a raised shield stalls
		MeteorAim = 60, -- max range from Kai
		ReflectBoost = 2, -- Reflect Boost upgrade multiplier
		SecondWind = { HP = 40, RallyHeal = 20 },
		WiderBlock = 160,
		LongerCharge = 22,
		BiggerFireball = 1.5,
		BiggerFireballDamage = 1.25, -- and it hits harder (playtest Oct 1): 10 -> 12.5
		FasterCast = 0.25,
		EmberTrail = { Damage = 4, Life = 3 },
	},
	Enemies = {
		Skeleton = { HP = 30, Speed = 10, Reach = 4.5, Windup = 0.7, Damage = 8, Recover = 1, XP = 10 },
		SplitSlime = { HP = 40, Speed = 8, Reach = 3.5, Windup = 0.3, Damage = 8, Recover = 1, XP = 12, SplitHP = 15 },
		StaticArcher = {
			HP = 25,
			Speed = 9,
			Range = 30,
			KeepAway = 18,
			Every = 2,
			ArrowSpeed = 60,
			Damage = 10,
			XP = 10,
		},
		ShieldGuard = { HP = 60, Speed = 7, Reach = 5, Windup = 0.7, Damage = 15, Recover = 1, XP = 20, Arc = 120 },
		StaticMage = { HP = 35, Speed = 0, Every = 3, Teleport = 5, OrbSpeed = 30, Damage = 12, XP = 15, Range = 40 },
		-- can't be hurt: lure its charge into the pillars Kai has burned (obstacles.md 2.3 Golem Lure)
		IronGolem = {
			HP = 1,
			Immune = true,
			Speed = 6,
			ChargeRange = 30, -- winds up a charge at its target from this close
			Windup = 0.9,
			ChargeSpeed = 50,
			ChargeMax = 45, -- studs per charge
			Damage = 25,
			Daze = 3, -- s stunned after smashing a burned pillar
			Bonk = 1.2, -- s stunned after hitting a wall or a sound pillar
			XP = 40,
		},
	},

	-- Bosses (mechanics.md §5)
	CrusherKing = {
		-- phase 1: fist slams (targets alternate Kai / Miko); Kai freezes a fist, Miko pounds its wrist crystal
		Hover = 24, -- studs a fist hangs over the floor while it tracks its target
		Track = 1.8, -- s a fist follows its target with a slam mark under it
		SlamTime = 0.22,
		Rest = 1.1, -- s a fist stays on the floor after a slam (freeze it now: its top is double-jump high)
		Rise = 0.8,
		Gap = 0.6, -- s between one fist going up and the other starting
		SlamRadius = 7, -- players within this of the fist's center when it lands lose a heart
		CrystalHits = 3,
		ShakeOff = 0.6, -- s after a crystal hit before the fist breaks free
		-- phase 2: the front rows drop away, he throws blocks; Kai freezes one mid-flight, Miko swings over
		DropRows = 3, -- the rows nearest the king that fall away (gap 36 across, lap 18 up)
		ThrowEvery = 2.6,
		ThrowTime = 2.4, -- s a block is in the air
		ThrowArc = 10, -- apex above the higher end
		BlockSize = 8,
		BlockRadius = 7, -- landing hurts within this
		CrumbleEvery = 3, -- s between tiles crumbling in the safe rows
		CrumbleWarn = 1, -- s a tile shakes before it falls
		CrumbleBack = 5, -- s until it's back
		-- phase 3: glitch shield; Kai freezes the whole king, Miko pulls the crown off
		Phase3Speed = 1.3, -- fists move this much faster
	},
	BossHitFlash = 0.25,

	-- World 3
	CopyPaste = { CopyRange = 50, PasteRange = 40, MaxPastes = 2, FloatDistance = 14 }, -- float: mid-air paste ahead of Kai
	LayerShift = { Transition = 0.3, PullRange = 35 },

	-- Pip, the floating companion (client-side)
	Pip = {
		Scale = 1,
		Height = 6, -- studs above the duo's midpoint
		Leash = 40, -- partner farther than this: Pip stays with you
		HintTime = 6, -- seconds Pip hangs at your shoulder after a hint
		-- spring follow: overshoots a little, then settles (damping ratio ≈ Damping / (2·√Stiffness) ≈ 0.6)
		Stiffness = 26,
		Damping = 6,
		MaxSpeed = 60, -- studs/s cap so a respawn teleport doesn't fling Pip across the map
		SnapDistance = 80, -- farther than this from its target: Pip just reappears there
		-- idle drift: a lazy figure-8 in the camera's view plane, plus a bob
		DriftRadius = 1.1,
		DriftSpeed = 0.55, -- loops per second ÷ 2π
		BobHeight = 0.3,
		BobSpeed = 2.2,
		-- banking: lean into sideways motion, nose-dip when moving toward/away from the camera
		BankPerSpeed = math.rad(2.2), -- radians per stud/s
		MaxBank = math.rad(30),
		BankSharpness = 8,
		-- excited spin + hop when a hint arrives
		SpinTime = 0.7,
		SpinHop = 1.4,
		-- glitch stutter: every JitterMin–JitterMax s, snaps around for JitterTime (Pip is half-finished code)
		JitterMin = 5,
		JitterMax = 11,
		JitterTime = 0.2,
		JitterAmount = 0.35,
		-- wings (parts named WingL / WingR) flap about their inner edge
		FlapSpeed = 9,
		FlapAngle = math.rad(22),
	},
}
