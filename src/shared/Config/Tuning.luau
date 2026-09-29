-- Every number from mechanics.md. First-pass values in studs and seconds; tune after playtests.
local GRAVITY = 196.2

local function jumpVelocity(height: number): number
	return math.sqrt(2 * GRAVITY * height)
end

return {
	Gravity = GRAVITY,

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
	LongJumpForward = 55, -- crouch + jump while moving (research.md: ITT keeps momentum on a crouch-jump)
	LongJumpUp = jumpVelocity(5),
	LedgeAssistReach = 2.5, -- studs a near-miss ledge pulls you up
	MobileAutoSprintAfter = 1.5,

	-- Traversal objects
	SwingRange = 18,
	SwingBoost = 1.2,
	GrindSpeed = 40,
	GrindGrabRange = 8,
	VentForce = 90,
	DuoPoundWindow = 0.5,
	HeavyLeverHold = 1,
	HeavyLeverWindow = 1,

	-- Health
	Hearts = 3,
	HeartRegenEvery = 5,
	HitInvuln = 1,
	KillZoneRespawnDelay = 1.5,
	SafePosEvery = 0.5,
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
		MeteorAim = 60, -- max range from Kai
		ReflectBoost = 2, -- Reflect Boost upgrade multiplier
		SecondWind = { HP = 40, RallyHeal = 20 },
		WiderBlock = 160,
		LongerCharge = 22,
		BiggerFireball = 1.5,
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
	},

	-- World 3
	CopyPaste = { CopyRange = 50, PasteRange = 40, MaxPastes = 2 },
	LayerShift = { Transition = 0.3, PullRange = 35 },

	-- Pip, the floating companion (client-side)
	Pip = {
		Scale = 0.75,
		Height = 6, -- studs above the duo's midpoint
		Sharpness = 3, -- follow smoothing (higher = snappier)
		BobHeight = 0.4,
		BobSpeed = 2,
		Leash = 40, -- partner farther than this: Pip stays with you
		HintTime = 6, -- seconds Pip hangs at your shoulder after a hint
	},
}
