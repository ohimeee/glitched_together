-- Every sound in the game (design.md §8, art-direction.md §7 / §12), like Palette and Tuning: code asks for a
-- name, never an id. Played through Util/Audio (3D at a part/point, or 2D) and the client AudioController
-- (music, ambience, ducking). Tool uses read wind-up → effect → impact; the Glitch is always heard with a crackle.
--
-- Sources (license rules and the full source list: TOOLS.md §3b; credits: sounds/CREDITS.md):
--   PSE  = Roblox creator "ProSoundEffects" (Pro Sound Effects' licensed catalog, free in experiences)
--   APM  = Roblox creator "APMOfficial" (APM Music, licensed for Roblox experiences)
--   RBLX = Roblox's own UI sound set
-- Ids chosen from catalog descriptions; tune Volume/Pitch by ear in a playtest, swap ids freely.
--
-- Fields: Id (or Ids: a random one per play), Volume, Pitch (default 1), PitchVar (± random), Range (3D max
-- distance, studs), Group ("SFX" | "UI" | "Music" | "Ambience"), Looped, Start (music: skip an intro).

export type Def = {
	Id: string?,
	Ids: { string }?,
	Volume: number,
	Pitch: number?,
	PitchVar: number?,
	Range: number?,
	Group: string?,
	Looped: boolean?,
	Start: number?, -- music: seconds to skip at the start (and on every loop)
}

local function pse(id: number): string
	return "rbxassetid://" .. id
end

local Sfx: { [string]: Def } = {
	-- Moveset (mechanics.md §2). Plain jump, landing and footsteps are Roblox's own character sounds.
	DoubleJump = { Id = pse(9116421640), Volume = 0.35, Pitch = 1.15, PitchVar = 0.05 }, -- short shimmering boink
	LongJump = { Id = pse(9125648149), Volume = 0.35, PitchVar = 0.05 }, -- sharp tubular zoom up
	WallJump = { Id = pse(9120742710), Volume = 0.4, Pitch = 1.1, PitchVar = 0.06 }, -- thick quick whoosh
	Dash = {
		Ids = { pse(9126229267), pse(9126228975) }, -- fast airy whoosh-by
		Volume = 0.45,
		Pitch = 1.1,
		PitchVar = 0.06,
	},
	PoundStart = { Id = pse(9120742903), Volume = 0.35, Pitch = 0.8 }, -- whoosh (the hang before the drop)
	PoundImpact = { Id = pse(9116488438), Volume = 0.7, Pitch = 0.8, PitchVar = 0.05 }, -- meaty thud
	PoundDebris = { Id = pse(9118685591), Volume = 0.5, PitchVar = 0.08 }, -- dirt/rock hit under it
	Swing = { Id = pse(9118722980), Volume = 0.4, PitchVar = 0.08 }, -- rope pull
	BouncePad = { Id = pse(9113537815), Volume = 0.55, Pitch = 0.9, PitchVar = 0.05 }, -- hollow boink pop
	ReleaseLaunch = { Id = pse(12222124), Volume = 0.6, Pitch = 0.85, PitchVar = 0.05 }, -- RBLX short spring boing

	-- World 1 tools
	PauseBeamFire = { Id = pse(9120984892), Volume = 0.5, PitchVar = 0.04 }, -- glassy reversed zap
	Freeze = { Id = pse(9125611419), Volume = 0.55, Pitch = 1.15 }, -- ice crackle on the target
	Unfreeze = { Id = pse(9117869243), Volume = 0.4, Pitch = 1.3 }, -- small power-down
	GrappleShoot = { Id = pse(9118720738), Volume = 0.45, Pitch = 1.2, PitchVar = 0.05 }, -- rope whip burst
	GrappleHook = { Id = pse(9116653976), Volume = 0.45, Pitch = 1.3, PitchVar = 0.06 }, -- metal clank on the anchor
	GrappleRelease = { Id = pse(9118723089), Volume = 0.3, Pitch = 1.2 },
	Pull = { Id = pse(9118718610), Volume = 0.9, Pitch = 1.1 }, -- rope through a pulley

	-- World 3 tools
	CopyScan = { Id = pse(9118777437), Volume = 0.45 }, -- clean scanner beep
	Paste = { Id = pse(9113867249), Volume = 0.45 }, -- bright synth hit
	PastePoof = { Id = pse(9116406610), Volume = 0.35, Pitch = 1.2 },
	ShiftIn = { Id = pse(9125484349), Volume = 0.45, Pitch = 1.2 }, -- reversed synth rise, "reveal"
	ShiftOut = { Id = pse(9126160991), Volume = 0.35, Pitch = 1.1 }, -- video static burst
	PullOut = { Id = pse(9116458170), Volume = 0.4 }, -- malfunction beeps

	-- Starfall Castle tools (server-played, CombatService / abilities)
	FireballCast = { Ids = { pse(9114444008), pse(9114444052) }, Volume = 0.5, PitchVar = 0.08 },
	FireImpact = { Id = pse(9125616655), Volume = 0.5, PitchVar = 0.08 }, -- whooshing poof + crackle
	FlameWall = { Id = pse(9114446277), Volume = 0.55 },
	MeteorFall = { Id = pse(9125646252), Volume = 0.5, Pitch = 0.8 }, -- growly magic whoosh
	MeteorImpact = { Id = pse(9114554567), Volume = 0.7, Range = 200 }, -- gas fire explosion
	Blink = { Id = pse(9125640290), Volume = 0.4, Pitch = 1.1 }, -- magic poof
	Rally = { Id = pse(9116395089), Volume = 0.55 }, -- soft chiming glow
	SwordSwing = { Ids = { pse(9120742729), pse(9120742710) }, Volume = 0.45, Pitch = 1.25, PitchVar = 0.08 },
	SwordHit = { Id = pse(9119746751), Volume = 0.45, PitchVar = 0.06 },
	ShieldBlock = { Ids = { pse(9119072660), pse(9119072674) }, Volume = 0.5, PitchVar = 0.05 },
	Reflect = { Id = pse(9113147683), Volume = 0.45, Pitch = 1.2 }, -- phasey arc zap
	ShieldCharge = { Id = pse(9126229255), Volume = 0.5, Pitch = 0.9 },
	Ignite = { Id = pse(9114442751), Volume = 0.45 },
	-- breakable room props (Services/Breakables)
	CrateBreak = { -- crunchy wood crate smashes
		Ids = { pse(9120961670), pse(9120962130), pse(9120961746), pse(9126242477) },
		Volume = 0.55,
		PitchVar = 0.08,
	},
	SackBreak = { Ids = { pse(9113827650), pse(9113835765) }, Volume = 0.5, Pitch = 0.85, PitchVar = 0.08 }, -- cloth rip
	BookcaseBreak = { Id = pse(9113549604), Volume = 0.55, PitchVar = 0.05 }, -- books scatter on the floor
	CrystalLit = { Ids = { pse(9120296573), pse(9120296584) }, Volume = 0.55, PitchVar = 0.04 }, -- bright twinkling shimmer
	CrystalChime = { Id = pse(9114619050), Volume = 0.4, Pitch = 1.3 }, -- glass tink under the shimmer
	PortcullisOpen = { Id = pse(9126234868), Volume = 0.5, Pitch = 1.1 }, -- hand-cranked winch ratchet
	PortcullisRattle = { Ids = { pse(9113763589), pse(9113763639) }, Volume = 0.45 }, -- chain rattle as it starts

	-- Enemies
	EnemyHit = { Ids = { pse(9117972730), pse(9117972870), pse(9117973315) }, Volume = 0.45, PitchVar = 0.08 },
	EnemyDeath = { Id = pse(9116406643), Volume = 0.5, PitchVar = 0.06 }, -- thumpy magic poof
	SkeletonRattle = { Id = pse(9120924561), Volume = 0.35, Pitch = 1.3, PitchVar = 0.1 }, -- hollow wooden rattle
	SlimeSquish = { Id = pse(9119990452), Volume = 0.45, PitchVar = 0.1 },
	EnemySwing = { Id = pse(9113610400), Volume = 0.35, Pitch = 0.8, PitchVar = 0.08 },
	ArrowShoot = { Id = pse(9113610400), Volume = 0.4, Pitch = 1.1, PitchVar = 0.08 }, -- whip swish
	ArrowHit = { Id = pse(9113161406), Volume = 0.4, PitchVar = 0.06 },
	StaticShot = { Id = pse(9119594871), Volume = 0.4, PitchVar = 0.08 }, -- buzzy static zap (Glitch enemies)
	Teleport = { Id = pse(9116458566), Volume = 0.4 }, -- glitchy malfunction blip

	-- The Glitch: always a crackle (art-direction.md §7)
	GlitchCrackle = {
		Ids = { pse(9116278351), pse(9116276051), pse(9114246605) },
		Volume = 0.45,
		PitchVar = 0.1,
	},
	GlitchStatic = { Id = pse(9119583983), Volume = 0.35, PitchVar = 0.1 },
	GlitchHum = { Id = pse(9114524164), Volume = 0.5, Looped = true, Range = 140 }, -- buzzy force field (chase wall)

	-- Players
	Hurt = { Ids = { pse(9117973098), pse(9117973185) }, Volume = 0.5, PitchVar = 0.06 },
	Downed = { Id = pse(9113480915), Volume = 0.55 },
	Revive = { Id = pse(9116394545), Volume = 0.5 },
	Checkpoint = { Id = pse(9116394876), Volume = 0.5 },
	XpPickup = { Id = pse(9113397314), Volume = 0.3, PitchVar = 0.12 },
	LevelUp = { Id = pse(94467136212002), Volume = 0.5, Group = "UI" }, -- APM "Boom Power Up"

	-- Contraptions (Pixel Plains and on)
	Lever = { Id = pse(9116260154), Volume = 0.5 },
	PlateDown = { Id = pse(9119717523), Volume = 0.5, Pitch = 0.7 },
	PlateUp = { Id = pse(9119717523), Volume = 0.35, Pitch = 0.9 },
	GateMove = { Id = pse(9114854551), Volume = 0.45 }, -- hydraulic lift whine + stop
	Dropper = { Id = pse(9113059983), Volume = 0.4, Range = 60 }, -- pneumatic air chuff

	-- Pip (design.md §8: short bleeps with text, never long lines)
	PipBleep = { Id = pse(9113880475), Volume = 0.18, Pitch = 1.1, PitchVar = 0.25, Group = "UI" },
	PipChirp = { Id = pse(9118272977), Volume = 0.3, Group = "UI" }, -- kalimba beep-borp when a hint pops

	-- UI (Roblox's UI set)
	Click = { Id = "rbxassetid://15675059323", Volume = 0.4, Group = "UI" },
	Hover = { Id = "rbxassetid://10066931761", Volume = 0.2, Group = "UI" },
	Select = { Id = "rbxassetid://10128760939", Volume = 0.4, Group = "UI" },
	PanelOpen = { Id = "rbxassetid://15674975792", Volume = 0.3, Group = "UI" },
	Stinger = { Id = "rbxassetid://15675043410", Volume = 0.45, Group = "UI" },
}

-- Music per world (design.md §8), all APM. Crossfaded by AudioController on workspace "World".
local Music: { [string]: Def } = {
	-- "Music Box Lullaby": quiet and lonely but gentle (user, Oct 1: the solo piano "Nocturnal Loneliness",
	-- 101684715165177, was too sad)
	Prologue = { Id = pse(9047785119), Volume = 0.4 },
	PixelPlains = { Id = pse(1837768333), Volume = 0.3 }, -- "Jolly Adventure (a)": chiptune, upbeat
	StarfallCastle = { Id = pse(1841593944), Volume = 0.35 }, -- "Enchanted Kingdom a": orchestral fantasy
	-- "Castle in 8 Bit": worlds 1 + 2, remixed; the user loves it, minus its 5 s intro (Oct 1)
	GlitchedCore = { Id = pse(9048374858), Volume = 0.3, Start = 5 },
	Epilogue = { Id = pse(78697548522569), Volume = 0.4 }, -- "A Hopeful Light": the title theme, now hopeful
}

-- Boss fights (workspace "BossFight" set): replaces the world's music.
local BossMusic: { [string]: Def } = {
	PixelPlains = { Id = pse(1837768323), Volume = 0.35 }, -- "Final Boss (a)"
	StarfallCastle = { Id = pse(1848104196), Volume = 0.4 }, -- "Evil Wizard A"
	GlitchedCore = { Id = pse(9046451355), Volume = 0.35 }, -- "Null": glitchy hybrid metal
}

-- Quiet background beds under the music.
local Ambience: { [string]: Def } = {
	Prologue = { Id = pse(9114057128), Volume = 0.15 }, -- light whistly wind
	PixelPlains = { Id = pse(9119383684), Volume = 0.18 }, -- morning birds
	StarfallCastle = { Id = pse(9112780462), Volume = 0.15 }, -- torch/fireplace crackle
	GlitchedCore = { Id = pse(9125446564), Volume = 0.2 }, -- deep machine-room hum
}

return {
	Sfx = Sfx,
	Music = Music,
	BossMusic = BossMusic,
	Ambience = Ambience,
	-- SoundGroup volumes (players' mix)
	Groups = { Music = 0.8, Ambience = 0.8, SFX = 1, UI = 1 },
	Range = 90, -- default 3D max distance, studs
	MusicFade = 2, -- crossfade seconds
	CutsceneDuck = 0.35, -- music volume multiplier while a cutscene plays
}
