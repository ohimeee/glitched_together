-- Player move animations (R15), authored as keyframe data so they live in the repo (research.md "Move animations").
-- MoveAnimController turns each clip into a KeyframeSequence: in Studio it plays from a temporary id
-- (KeyframeSequenceProvider:RegisterKeyframeSequence), live games need the uploaded id in `Ids`
-- (tools/anim/build_move_anims.luau builds them into ServerStorage for "Save to Roblox").
--
-- Pose values per joint (named by the moving part, Pose = Motor6D.Transform): { rx, ry, rz, px, py, pz }, degrees
-- and studs, in the joint's space (R15 C0s have no rotation, so this is the character's own space):
--   LowerTorso (root): rx < 0 pitches the body forward, ry > 0 turns it left, py lifts/drops it.
--   UpperTorso (waist) / Head (neck): rx < 0 bends forward / looks down.
--   UpperArm (shoulder): rx > 0 swings the arm forward (180 = straight up); Right rz > 0 / Left rz < 0 = out sideways.
--   LowerArm (elbow): rx > 0 bends. UpperLeg (hip): rx > 0 lifts the thigh forward. LowerLeg (knee): rx < 0 bends.
-- A joint missing from a key sits at rest in that key. Spins use quarter-turn keys (keys lerp the short way).
-- Look: It Takes Two's "doll" moves: big readable silhouettes, snappy starts, arms flung wide (art-direction.md §12).

export type Pose = { number }
export type Key = { t: number, ease: string?, pose: { [string]: Pose } }
export type Clip = { priority: string, loop: boolean?, keys: { Key } }

-- Uploaded animation ids (rbxassetid://...) per clip. Empty = Studio-only temporary ids.
local Ids: { [string]: string } = {
	Crouch = "rbxassetid://79655492018259",
	CrouchWalk = "rbxassetid://117525133231587",
	Dash = "rbxassetid://85879401281012",
	DoubleJump = "rbxassetid://140426401648051",
	Grind = "rbxassetid://87687361770427",
	Land = "rbxassetid://70900451462165",
	LedgeAssist = "rbxassetid://138888968403569",
	LongJump = "rbxassetid://92043900512876",
	PoundFall = "rbxassetid://140149202714000",
	PoundLand = "rbxassetid://73487794828208",
	PoundSpin = "rbxassetid://112920836236153",
	Sprint = "rbxassetid://104998793268361",
	Swing = "rbxassetid://122532924977746",
	VentFlip = "rbxassetid://72702357684616",
	VentFloat = "rbxassetid://127702530131428",
	WallCling = "rbxassetid://84506645881258",
	WallJump = "rbxassetid://125651676279611",
}

local function merge(...: { [string]: Pose }): { [string]: Pose }
	local out = {}
	for _, pose in { ... } do
		for joint, value in pose do
			out[joint] = value
		end
	end
	return out
end

-- Shared body shapes ----------------------------------------------------------------------------------------------
local tuck = { -- knees to chest, arms hugging the shins
	UpperTorso = { -25, 0, 0 },
	Head = { -15, 0, 0 },
	RightUpperArm = { 70, 0, 20 },
	LeftUpperArm = { 70, 0, -20 },
	RightLowerArm = { 80, 0, 0 },
	LeftLowerArm = { 80, 0, 0 },
	RightUpperLeg = { 110, 0, 5 },
	LeftUpperLeg = { 110, 0, -5 },
	RightLowerLeg = { -125, 0, 0 },
	LeftLowerLeg = { -125, 0, 0 },
}

local spread = { -- star shape: arms flung up and out, legs apart (ITT jump silhouette)
	RightUpperArm = { 30, 0, 110 },
	LeftUpperArm = { 30, 0, -110 },
	RightLowerArm = { 15, 0, 0 },
	LeftLowerArm = { 15, 0, 0 },
	RightUpperLeg = { 15, 0, 12 },
	LeftUpperLeg = { -10, 0, -12 },
	RightLowerLeg = { -30, 0, 0 },
	LeftLowerLeg = { -45, 0, 0 },
}

local crouch = {
	LowerTorso = { -8, 0, 0, 0, -1.05, 0 },
	UpperTorso = { -22, 0, 0 },
	Head = { 22, 0, 0 },
	RightUpperArm = { 25, 0, 12 },
	LeftUpperArm = { 25, 0, -12 },
	RightLowerArm = { 40, 0, 0 },
	LeftLowerArm = { 40, 0, 0 },
	RightUpperLeg = { 75, 0, 8 },
	LeftUpperLeg = { 75, 0, -8 },
	RightLowerLeg = { -115, 0, 0 },
	LeftLowerLeg = { -115, 0, 0 },
	RightFoot = { 40, 0, 0 },
	LeftFoot = { 40, 0, 0 },
}

local squat = { -- landing squash
	LowerTorso = { -15, 0, 0, 0, -1.1, 0 },
	UpperTorso = { -15, 0, 0 },
	Head = { 15, 0, 0 },
	RightUpperArm = { 10, 0, 45 },
	LeftUpperArm = { 10, 0, -45 },
	RightLowerArm = { 20, 0, 0 },
	LeftLowerArm = { 20, 0, 0 },
	RightUpperLeg = { 80, 0, 15 },
	LeftUpperLeg = { 80, 0, -15 },
	RightLowerLeg = { -115, 0, 0 },
	LeftLowerLeg = { -115, 0, 0 },
	RightFoot = { 35, 0, 0 },
	LeftFoot = { 35, 0, 0 },
}

-- Sprint stride (mirrored for the other foot): long reach, high back kick, big counter arm pump, leaning in.
local function stride(side: number): { [string]: Pose }
	local front, back = if side > 0 then "Right" else "Left", if side > 0 then "Left" else "Right"
	local s = side
	return {
		LowerTorso = { -14, 0, 0, 0, -0.15, 0 },
		UpperTorso = { -6, 10 * s, 0 },
		Head = { 10, -10 * s, 0 },
		[front .. "UpperLeg"] = { 55, 0, 0 },
		[front .. "LowerLeg"] = { -25, 0, 0 },
		[back .. "UpperLeg"] = { -35, 0, 0 },
		[back .. "LowerLeg"] = { -85, 0, 0 },
		[back .. "Foot"] = { -20, 0, 0 },
		[front .. "UpperArm"] = { -55, 0, 12 * s },
		[front .. "LowerArm"] = { 60, 0, 0 },
		[back .. "UpperArm"] = { 75, 0, -12 * s },
		[back .. "LowerArm"] = { 85, 0, 0 },
	}
end

local function passing(side: number): { [string]: Pose }
	local up, down = if side > 0 then "Left" else "Right", if side > 0 then "Right" else "Left"
	return {
		LowerTorso = { -14, 0, 0, 0, 0.35, 0 },
		UpperTorso = { -6, 0, 0 },
		Head = { 10, 0, 0 },
		[down .. "UpperLeg"] = { -5, 0, 0 },
		[down .. "LowerLeg"] = { -15, 0, 0 },
		[up .. "UpperLeg"] = { 30, 0, 0 },
		[up .. "LowerLeg"] = { -110, 0, 0 },
		RightUpperArm = { 10, 0, 10 },
		LeftUpperArm = { 10, 0, -10 },
		RightLowerArm = { 80, 0, 0 },
		LeftLowerArm = { 80, 0, 0 },
	}
end

local function crouchStep(side: number): { [string]: Pose }
	local front, back = if side > 0 then "Right" else "Left", if side > 0 then "Left" else "Right"
	return merge(crouch, {
		[front .. "UpperLeg"] = { 95, 0, 0 },
		[front .. "LowerLeg"] = { -105, 0, 0 },
		[back .. "UpperLeg"] = { 45, 0, 0 },
		[back .. "LowerLeg"] = { -115, 0, 0 },
		[front .. "UpperArm"] = { 5, 0, 12 * side },
		[back .. "UpperArm"] = { 45, 0, -12 * side },
	})
end

local hang = { -- swing: right hand up the rope (the rope leaves RightGripAttachment), left arm out for balance
	RightUpperArm = { 175, 0, -8 },
	RightLowerArm = { 5, 0, 0 },
	LeftUpperArm = { 50, 0, -60 },
	LeftLowerArm = { 30, 0, 0 },
	Head = { 12, 0, 0 },
}

local surf = { -- grind: side-on surfer stance, knees bent, arms wide, head facing the way you ride
	LowerTorso = { -4, 55, 0, 0, -0.55, 0 },
	UpperTorso = { -10, -20, 0 },
	Head = { 8, -35, 0 },
	RightUpperArm = { 15, 0, 80 },
	LeftUpperArm = { 15, 0, -80 },
	RightLowerArm = { 15, 0, 0 },
	LeftLowerArm = { 15, 0, 0 },
	RightUpperLeg = { 35, 0, 18 },
	LeftUpperLeg = { 35, 0, -18 },
	RightLowerLeg = { -60, 0, 0 },
	LeftLowerLeg = { -60, 0, 0 },
	RightFoot = { 25, 0, 0 },
	LeftFoot = { 25, 0, 0 },
}

local cling = { -- facing the wall: right hand high on it, right knee up against it, left side hanging free
	UpperTorso = { 6, 0, 0 },
	Head = { 18, 0, 0 },
	RightUpperArm = { 155, 0, 15 },
	RightLowerArm = { 25, 0, 0 },
	LeftUpperArm = { 70, 0, -55 },
	LeftLowerArm = { 30, 0, 0 },
	RightUpperLeg = { 65, 0, 5 },
	RightLowerLeg = { -80, 0, 0 },
	LeftUpperLeg = { 10, 0, -8 },
	LeftLowerLeg = { -25, 0, 0 },
}

local slam = { -- pound fall: stretched feet-first, arms straight up (stretch before the squash)
	LowerTorso = { 0, 0, 0, 0, 0.3, 0 },
	UpperTorso = { 4, 0, 0 },
	Head = { -10, 0, 0 },
	RightUpperArm = { 170, 0, 18 },
	LeftUpperArm = { 170, 0, -18 },
	RightUpperLeg = { 0, 0, 3 },
	LeftUpperLeg = { 0, 0, -3 },
	RightFoot = { -30, 0, 0 },
	LeftFoot = { -30, 0, 0 },
}

local dive = { -- long jump: superman dive, arms reaching ahead, legs trailing
	LowerTorso = { -65, 0, 0, 0, 0.4, 0 },
	UpperTorso = { 5, 0, 0 },
	Head = { 45, 0, 0 },
	RightUpperArm = { 165, 0, 12 },
	LeftUpperArm = { 165, 0, -12 },
	RightUpperLeg = { -12, 0, 6 },
	LeftUpperLeg = { -5, 0, -6 },
	RightLowerLeg = { -25, 0, 0 },
	LeftLowerLeg = { -10, 0, 0 },
	RightFoot = { -35, 0, 0 },
	LeftFoot = { -35, 0, 0 },
}

local dash = { -- body thrown forward, arms swept back, one leg trailing
	LowerTorso = { -32, 0, 0 },
	UpperTorso = { -8, 0, 0 },
	Head = { 30, 0, 0 },
	RightUpperArm = { -65, 0, 25 },
	LeftUpperArm = { -65, 0, -25 },
	RightLowerArm = { 15, 0, 0 },
	LeftLowerArm = { 15, 0, 0 },
	RightUpperLeg = { 35, 0, 0 },
	RightLowerLeg = { -45, 0, 0 },
	LeftUpperLeg = { -40, 0, 0 },
	LeftLowerLeg = { -55, 0, 0 },
}

local float = { -- riding an updraft: arms up in a V, legs loose, head back to look up the stream
	LowerTorso = { 6, 0, -5, 0, 0.3, 0 },
	UpperTorso = { 8, 0, 0 },
	Head = { 20, 0, 0 },
	RightUpperArm = { 15, 0, 135 },
	LeftUpperArm = { 25, 0, -118 },
	RightLowerArm = { 20, 0, 0 },
	LeftLowerArm = { 30, 0, 0 },
	RightUpperLeg = { 30, 0, 12 },
	LeftUpperLeg = { 5, 0, -16 },
	RightLowerLeg = { -70, 0, 0 },
	LeftLowerLeg = { -30, 0, 0 },
}

local function spin(rx: number, py: number): { [string]: Pose }
	return merge(tuck, { LowerTorso = { rx, 0, 0, 0, py, 0 } })
end

-- Clips ---------------------------------------------------------------------------------------------------------
-- Kai's Fire Mage casts (user, Oct 11). Upper body only (legs keep walking): torso, head and arms.
-- A fireball throw, `side` 1 = right hand, -1 = left (auto-fire alternates hands): cock the hand back by the
-- shoulder, then punch it out at the aim with the torso turning into it; the other arm swings back for balance.
local function throwPose(side: number, phase: string): { [string]: Pose }
	local hand, other = if side > 0 then "Right" else "Left", if side > 0 then "Left" else "Right"
	local s = side
	if phase == "cock" then
		return {
			UpperTorso = { 4, -22 * s, 0 },
			Head = { 0, 22 * s, 0 },
			[hand .. "UpperArm"] = { 55, 0, 35 * s },
			[hand .. "LowerArm"] = { 110, 0, 0 },
			[other .. "UpperArm"] = { 45, 0, -15 * s },
			[other .. "LowerArm"] = { 40, 0, 0 },
		}
	end
	return { -- "push": arm straight out at the aim, palm first
		UpperTorso = { -6, 24 * s, 0 },
		Head = { 4, -24 * s, 0 },
		[hand .. "UpperArm"] = { 92, 0, -6 * s },
		[hand .. "LowerArm"] = { 4, 0, 0 },
		[hand .. "Hand"] = { -35, 0, 0 },
		[other .. "UpperArm"] = { -30, 0, -22 * s },
		[other .. "LowerArm"] = { 35, 0, 0 },
	}
end

local function throwClip(side: number): Clip
	return {
		priority = "Action",
		keys = {
			{ t = 0, pose = {} },
			{ t = 0.06, pose = throwPose(side, "cock") },
			{ t = 0.12, ease = "Linear", pose = throwPose(side, "push") },
			{ t = 0.2, pose = throwPose(side, "push") },
			{ t = 0.34, pose = {} },
		},
	}
end

local armsUp = { -- both hands high, gathering fire overhead
	UpperTorso = { 12, 0, 0 },
	Head = { 18, 0, 0 },
	RightUpperArm = { 165, 0, 18 },
	LeftUpperArm = { 165, 0, -18 },
	RightLowerArm = { 25, 0, 0 },
	LeftLowerArm = { 25, 0, 0 },
}
local palmsDown = { -- both palms driven at the floor ahead, bent over them
	UpperTorso = { -28, 0, 0 },
	Head = { 18, 0, 0 },
	RightUpperArm = { 62, 0, 32 },
	LeftUpperArm = { 62, 0, -32 },
	RightLowerArm = { 8, 0, 0 },
	LeftLowerArm = { 8, 0, 0 },
	RightHand = { -50, 0, 0 },
	LeftHand = { -50, 0, 0 },
}

-- Miko's Shield Knight (user, Oct 11): sword in the right hand, shield in the left (ToolFx.Held). Upper body only.
-- The shield faces the way the hand's back does, so the left arm's pitches (shoulder + elbow + wrist) sum to ~0:
-- the shield stays upright with its face forward however high the arm lifts it.
local guard = { -- the shield arm between swings: lifted a little in front of the left side
	LeftUpperArm = { 30, 0, -10 },
	LeftLowerArm = { 50, 0, 0 },
	LeftHand = { -80, 0, 0 },
}
local function slash(cock: { [string]: Pose }, hit: { [string]: Pose }): Clip
	return {
		priority = "Action",
		keys = {
			{ t = 0, pose = guard },
			{ t = 0.07, pose = merge(guard, cock) },
			{ t = 0.14, ease = "Linear", pose = merge(guard, hit) },
			{ t = 0.22, pose = merge(guard, hit) },
			{ t = 0.36, pose = {} },
		},
	}
end
local blockPose = { -- standing tall behind the raised shield (user ref photo, Oct 11): the left forearm crosses her
	-- belly with the elbow out, and while Blocking the shield moves to ToolFx GlowGrip: centred, square and upright,
	-- top at her chin so her whole head shows over it; the sword arm hangs relaxed at her side. Rest joints are listed
	-- so the idle animation can't tilt the shield through her hips or wrist
	LowerTorso = { 0, 0, 0 },
	UpperTorso = { 0, 0, 0 },
	Head = { 0, 0, 0 },
	LeftUpperArm = { -10, -90, -20 },
	LeftLowerArm = { 45, 0, 0 },
	LeftHand = { 0, 0, 0 },
	RightUpperArm = { 12, 0, 14 },
	RightLowerArm = { 25, 0, 0 },
}
local chargePose = { -- the Shield Charge rush (shield on its normal grip): crouched and hunched, the left arm swings
	-- the shield across to the middle of her body (pose solved in Play: shield centred within 0.3 studs, upright,
	-- ~30 deg off square), head tucked so only the top of it peeks over the rim
	LowerTorso = { -4, 0, 0, 0, -0.6, 0 },
	UpperTorso = { -14, -20, 0 },
	Head = { 14, 20, 0 },
	LeftUpperArm = { 60, -85, 0 },
	LeftLowerArm = { 90, 0, 0 },
	LeftHand = { -150, -80, 25 },
	RightUpperArm = { 15, 0, 18 },
	RightLowerArm = { 30, 0, 0 },
	RightUpperLeg = { 40, 0, 6 },
	LeftUpperLeg = { 40, 0, -6 },
	RightLowerLeg = { -60, 0, 0 },
	LeftLowerLeg = { -60, 0, 0 },
	RightFoot = { 20, 0, 0 },
	LeftFoot = { 20, 0, 0 },
}

local Clips: { [string]: Clip } = {
	-- the 3-hit sword combo (Tuning.Combat.SwordCombo): forehand, backhand, overhead chop
	Slash1 = slash({
		UpperTorso = { 0, -28, 0 },
		Head = { 0, 28, 0 },
		RightUpperArm = { 92, -75, 0 },
		RightLowerArm = { 45, 0, 0 },
	}, {
		UpperTorso = { -4, 32, 0 },
		Head = { 2, -30, 0 },
		RightUpperArm = { 86, 58, 0 },
		RightLowerArm = { 8, 0, 0 },
	}),
	Slash2 = slash({
		UpperTorso = { 0, 30, 0 },
		Head = { 0, -30, 0 },
		RightUpperArm = { 92, 62, 0 },
		RightLowerArm = { 95, 0, 0 },
	}, {
		UpperTorso = { -4, -28, 0 },
		Head = { 2, 28, 0 },
		RightUpperArm = { 86, -70, 0 },
		RightLowerArm = { 8, 0, 0 },
	}),
	Slash3 = slash({
		UpperTorso = { 12, 0, 0 },
		Head = { 10, 0, 0 },
		RightUpperArm = { 172, 0, 8 },
		RightLowerArm = { 65, 0, 0 },
	}, {
		UpperTorso = { -28, 0, 0 },
		Head = { 20, 0, 0 },
		RightUpperArm = { 62, 0, 4 },
		RightLowerArm = { 0, 0, 0 },
	}),
	-- held while Miko blocks (MoveAnimController.Set)
	Block = {
		priority = "Action",
		loop = true,
		keys = {
			{ t = 0, pose = blockPose },
			{ t = 0.7, pose = merge(blockPose, { UpperTorso = { -2, 0, 0 }, Head = { 2, 0, 0 } }) }, -- breathing
			{ t = 1.4, pose = blockPose },
		},
	},
	-- Shield Charge: bent low behind the shield for the rush (0.3 s), then up
	ShieldCharge = {
		priority = "Action2",
		keys = {
			{ t = 0, pose = chargePose },
			{ t = 0.05, pose = merge(chargePose, { UpperTorso = { -28, -18, 0 }, Head = { 22, 18, 0 } }) },
			{ t = 0.32, pose = merge(chargePose, { UpperTorso = { -28, -18, 0 }, Head = { 22, 18, 0 } }) },
			{ t = 0.5, pose = {} },
		},
	},
	-- Rally: sword thrust to the sky, then driven down into the floor as the shockwave goes out
	Rally = {
		priority = "Action2",
		keys = {
			{ t = 0, pose = {} },
			{
				t = 0.15,
				pose = merge(guard, {
					UpperTorso = { 10, 0, 0 },
					Head = { 20, 0, 0 },
					RightUpperArm = { 178, 0, 6 },
					RightLowerArm = { 5, 0, 0 },
				}),
			},
			{
				t = 0.4,
				pose = merge(guard, {
					UpperTorso = { 12, 0, 0 },
					Head = { 24, 0, 0 },
					RightUpperArm = { 178, 0, 6 },
					RightLowerArm = { 5, 0, 0 },
				}),
			},
			{
				t = 0.52,
				ease = "Linear",
				pose = merge(guard, {
					UpperTorso = { -32, 0, 0 },
					Head = { 20, 0, 0 },
					RightUpperArm = { 40, 0, 4 },
					RightLowerArm = { 5, 0, 0 },
				}),
			},
			{
				t = 0.8,
				pose = merge(guard, {
					UpperTorso = { -32, 0, 0 },
					Head = { 20, 0, 0 },
					RightUpperArm = { 40, 0, 4 },
					RightLowerArm = { 5, 0, 0 },
				}),
			},
			{ t = 1, pose = {} },
		},
	},
	CastFireR = throwClip(1),
	CastFireL = throwClip(-1),
	-- Flame Wall: hands up, then both palms slammed down at the floor where the wall rises
	CastWall = {
		priority = "Action",
		keys = {
			{ t = 0, pose = {} },
			{ t = 0.14, pose = armsUp },
			{ t = 0.24, ease = "Linear", pose = palmsDown },
			{ t = 0.42, pose = palmsDown },
			{ t = 0.6, pose = {} },
		},
	},
	-- Ignite: wind the hand in by the chest, then flick two fingers out at the target (the snap sends the spark)
	CastIgnite = {
		priority = "Action",
		keys = {
			{ t = 0, pose = {} },
			{
				t = 0.08,
				pose = {
					UpperTorso = { 0, -14, 0 },
					Head = { 0, 14, 0 },
					RightUpperArm = { 45, 0, -10 },
					RightLowerArm = { 120, 0, 0 },
					RightHand = { 30, 0, 0 },
				},
			},
			{
				t = 0.15,
				ease = "Linear",
				pose = {
					UpperTorso = { -4, 16, 0 },
					Head = { 4, -16, 0 },
					RightUpperArm = { 98, 0, 4 },
					RightLowerArm = { 6, 0, 0 },
					RightHand = { -40, 0, 0 },
					LeftUpperArm = { -15, 0, -18 },
				},
			},
			{
				t = 0.32,
				pose = {
					UpperTorso = { -2, 14, 0 },
					Head = { 2, -14, 0 },
					RightUpperArm = { 92, 0, 4 },
					RightLowerArm = { 10, 0, 0 },
					RightHand = { -25, 0, 0 },
					LeftUpperArm = { -10, 0, -14 },
				},
			},
			{ t = 0.5, pose = {} },
		},
	},
	-- Meteor: arms raised through the 1.2 s cast (Tuning.FireMage.Meteor.Cast), then thrown down as it lands
	CastMeteor = {
		priority = "Action",
		keys = {
			{ t = 0, pose = {} },
			{ t = 0.18, pose = armsUp },
			{ t = 0.6, pose = merge(armsUp, { UpperTorso = { 16, 0, 0 } }) },
			{ t = 1.05, pose = merge(armsUp, { RightUpperArm = { 175, 0, 12 }, LeftUpperArm = { 175, 0, -12 } }) },
			{ t = 1.18, ease = "Linear", pose = palmsDown },
			{ t = 1.4, pose = palmsDown },
			{ t = 1.6, pose = {} },
		},
	},
	-- double jump: tucked front flip, opens into the star at the top
	DoubleJump = {
		priority = "Action2",
		keys = {
			{ t = 0, pose = merge(spread, { LowerTorso = { 10, 0, 0 } }) },
			{ t = 0.07, ease = "Linear", pose = spin(-90, 0.6) },
			{ t = 0.15, ease = "Linear", pose = spin(-180, 0.8) },
			{ t = 0.23, ease = "Linear", pose = spin(-270, 0.6) },
			{ t = 0.31, pose = merge(spread, { LowerTorso = { 0, 0, 0, 0, 0.2, 0 } }) },
			{ t = 0.5, pose = merge(spread, { LowerTorso = { 0, 0, 0 } }) },
		},
	},
	Dash = {
		priority = "Action2",
		keys = {
			{ t = 0, pose = {} },
			{ t = 0.04, pose = dash },
			{ t = 0.16, pose = dash }, -- held for the burst (Tuning.DashTime)
			{ t = 0.24, pose = merge(spread, { LowerTorso = { -8, 0, 0 } }) },
		},
	},
	-- ground pound: one curled spin during the hang (Tuning.PoundHang 0.15 s), then PoundFall until impact
	PoundSpin = {
		priority = "Action2",
		keys = {
			{ t = 0, pose = spin(0, 0.4) },
			{ t = 0.04, ease = "Linear", pose = spin(90, 0.8) },
			{ t = 0.08, ease = "Linear", pose = spin(180, 1) },
			{ t = 0.12, ease = "Linear", pose = spin(270, 0.8) },
			{ t = 0.16, pose = slam },
		},
	},
	PoundFall = {
		priority = "Action2",
		loop = true,
		keys = {
			{ t = 0, pose = slam },
			{ t = 0.2, pose = slam },
		},
	},
	PoundLand = {
		priority = "Action3",
		keys = {
			{ t = 0, pose = merge(squat, { LowerTorso = { -20, 0, 0, 0, -1.3, 0 } }) },
			{ t = 0.14, pose = squat },
			{ t = 0.42, pose = {} },
		},
	},
	Land = { -- hard landing (not a pound): a quick squash
		priority = "Action2",
		keys = {
			{ t = 0, pose = squat },
			{ t = 0.07, pose = squat },
			{ t = 0.26, pose = {} },
		},
	},
	Crouch = {
		priority = "Movement",
		loop = true,
		keys = {
			{ t = 0, pose = crouch },
			{ t = 0.8, pose = merge(crouch, { LowerTorso = { -8, 0, 0, 0, -1.12, 0 } }) },
			{ t = 1.6, pose = crouch },
		},
	},
	CrouchWalk = {
		priority = "Movement",
		loop = true,
		keys = {
			{ t = 0, pose = crouchStep(1) },
			{ t = 0.3, pose = crouchStep(-1) },
			{ t = 0.6, pose = crouchStep(1) },
		},
	},
	LongJump = {
		priority = "Action2",
		keys = {
			{ t = 0, pose = crouch },
			{ t = 0.12, pose = dive },
			{ t = 0.5, pose = dive },
			{ t = 0.75, pose = merge(spread, { LowerTorso = { -10, 0, 0 } }) },
		},
	},
	WallCling = {
		priority = "Action",
		loop = true,
		keys = {
			{ t = 0, pose = cling },
			{ t = 0.25, pose = merge(cling, { LeftUpperLeg = { 18, 0, -8 }, LeftUpperArm = { 80, 0, -50 } }) },
			{ t = 0.5, pose = cling },
		},
	},
	WallJump = { -- the body already faces away from the wall: push off into the star
		priority = "Action2",
		keys = {
			{ t = 0, pose = merge(tuck, { LowerTorso = { 15, 0, 0 } }) },
			{ t = 0.1, pose = merge(spread, { LowerTorso = { -15, 0, 0 } }) },
			{ t = 0.4, pose = merge(spread, { LowerTorso = { -5, 0, 0 } }) },
		},
	},
	LedgeAssist = { -- mantle: reach up, push down on the ledge, knees tucked under
		priority = "Action2",
		keys = {
			{
				t = 0,
				pose = merge(tuck, {
					LowerTorso = { -20, 0, 0 },
					RightUpperArm = { 150, 0, 10 },
					LeftUpperArm = { 150, 0, -10 },
					RightLowerArm = { 20, 0, 0 },
					LeftLowerArm = { 20, 0, 0 },
				}),
			},
			{
				t = 0.14,
				pose = merge(tuck, {
					LowerTorso = { -25, 0, 0, 0, 0.3, 0 },
					RightUpperArm = { 20, 0, 15 },
					LeftUpperArm = { 20, 0, -15 },
					RightLowerArm = { 70, 0, 0 },
					LeftLowerArm = { 70, 0, 0 },
				}),
			},
			{ t = 0.36, pose = {} },
		},
	},
	Swing = { -- legs pump while hanging (the body is leaned along the rope by MovementController)
		priority = "Action",
		loop = true,
		keys = {
			{
				t = 0,
				pose = merge(hang, {
					RightUpperLeg = { 35, 0, 4 },
					LeftUpperLeg = { 25, 0, -4 },
					RightLowerLeg = { -30, 0, 0 },
					LeftLowerLeg = { -45, 0, 0 },
				}),
			},
			{
				t = 0.6,
				pose = merge(hang, {
					LeftUpperArm = { 40, 0, -70 },
					RightUpperLeg = { -15, 0, 4 },
					LeftUpperLeg = { -5, 0, -4 },
					RightLowerLeg = { -75, 0, 0 },
					LeftLowerLeg = { -85, 0, 0 },
				}),
			},
			{
				t = 1.2,
				pose = merge(hang, {
					RightUpperLeg = { 35, 0, 4 },
					LeftUpperLeg = { 25, 0, -4 },
					RightLowerLeg = { -30, 0, 0 },
					LeftLowerLeg = { -45, 0, 0 },
				}),
			},
		},
	},
	Grind = { -- balance wobble
		priority = "Action",
		loop = true,
		keys = {
			{ t = 0, pose = surf },
			{
				t = 0.45,
				pose = merge(surf, {
					LowerTorso = { -4, 55, 4, 0, -0.65, 0 },
					RightUpperArm = { 15, 0, 92 },
					LeftUpperArm = { 15, 0, -66 },
				}),
			},
			{ t = 0.9, pose = surf },
		},
	},
	-- jump vent / fan updraft: a slow tucked flip on entering, then a skydiver float that flails while you ride it
	VentFlip = {
		priority = "Action2",
		keys = {
			{ t = 0, pose = merge(spread, { LowerTorso = { 0, 0, 0 } }) },
			{ t = 0.14, ease = "Linear", pose = spin(-90, 0.5) },
			{ t = 0.28, ease = "Linear", pose = spin(-180, 0.7) },
			{ t = 0.42, ease = "Linear", pose = spin(-270, 0.5) },
			{ t = 0.58, pose = merge(float, { LowerTorso = { 0, 0, 0, 0, 0.2, 0 } }) },
		},
	},
	VentFloat = {
		priority = "Action",
		loop = true,
		keys = {
			{ t = 0, pose = float },
			{
				t = 0.8,
				pose = merge(float, {
					LowerTorso = { -6, 8, 7, 0, 0.35, 0 },
					RightUpperArm = { 35, 0, 112 },
					LeftUpperArm = { 5, 0, -140 },
					RightUpperLeg = { 5, 0, 16 },
					LeftUpperLeg = { 35, 0, -10 },
					RightLowerLeg = { -25, 0, 0 },
					LeftLowerLeg = { -75, 0, 0 },
				}),
			},
			{ t = 1.6, pose = float },
		},
	},
	Sprint = { -- 0.48 s stride cycle at Tuning.SprintSpeed (MoveAnimController scales the speed)
		priority = "Movement",
		loop = true,
		keys = {
			{ t = 0, pose = stride(1) },
			{ t = 0.12, pose = passing(1) },
			{ t = 0.24, pose = stride(-1) },
			{ t = 0.36, pose = passing(-1) },
			{ t = 0.48, pose = stride(1) },
		},
	},
}

-- R15 joint tree: each part's parent part (the Pose hierarchy follows it).
local Parent = {
	LowerTorso = "HumanoidRootPart",
	UpperTorso = "LowerTorso",
	Head = "UpperTorso",
	RightUpperArm = "UpperTorso",
	RightLowerArm = "RightUpperArm",
	RightHand = "RightLowerArm",
	LeftUpperArm = "UpperTorso",
	LeftLowerArm = "LeftUpperArm",
	LeftHand = "LeftLowerArm",
	RightUpperLeg = "LowerTorso",
	RightLowerLeg = "RightUpperLeg",
	RightFoot = "RightLowerLeg",
	LeftUpperLeg = "LowerTorso",
	LeftLowerLeg = "LeftUpperLeg",
	LeftFoot = "LeftLowerLeg",
}

-- A pose value as the joint's Transform.
local function toCFrame(p: Pose?): CFrame
	if not p then
		return CFrame.identity
	end
	return CFrame.new(p[4] or 0, p[5] or 0, p[6] or 0)
		* CFrame.fromEulerAnglesYXZ(math.rad(p[1] or 0), math.rad(p[2] or 0), math.rad(p[3] or 0))
end

-- Build a clip as a KeyframeSequence (every joint the clip touches gets a Pose in every key).
local function build(name: string): KeyframeSequence
	local clip = Clips[name]
	local used: { [string]: boolean } = {}
	for _, key in clip.keys do
		for joint in key.pose do
			used[joint] = true
		end
	end
	-- the parents of used joints need (weightless) Poses too, to hold the hierarchy
	local needed: { [string]: boolean } = {}
	for joint in used do
		local j: string? = joint
		while j and j ~= "HumanoidRootPart" do
			needed[j] = true
			j = Parent[j]
		end
	end

	local seq = Instance.new("KeyframeSequence")
	seq.Name = name
	seq.Loop = clip.loop == true
	seq.Priority = (Enum.AnimationPriority :: any)[clip.priority]
	for _, key in clip.keys do
		local kf = Instance.new("Keyframe")
		kf.Time = key.t
		local root = Instance.new("Pose")
		root.Name = "HumanoidRootPart"
		root.Weight = 0
		root.Parent = kf
		local made: { [string]: Instance } = { HumanoidRootPart = root }
		local function make(joint: string): Instance
			if made[joint] then
				return made[joint]
			end
			local parent = make(Parent[joint])
			local pose = Instance.new("Pose")
			pose.Name = joint
			pose.CFrame = toCFrame(key.pose[joint])
			pose.Weight = if used[joint] then 1 else 0
			pose.EasingStyle = (Enum.PoseEasingStyle :: any)[key.ease or "Cubic"]
			pose.EasingDirection = Enum.PoseEasingDirection.InOut
			pose.Parent = parent
			made[joint] = pose
			return pose
		end
		for joint in needed do
			make(joint)
		end
		kf.Parent = seq
	end
	return seq
end

return {
	Ids = Ids,
	Clips = Clips,
	Parent = Parent,
	toCFrame = toCFrame,
	build = build,
}
