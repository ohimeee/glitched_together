# Glitched Together — Mechanics Spec

Every move, tool, enemy and boss, with starting numbers. All numbers are **first-pass tuning values** in Roblox studs and seconds; expect to change them after playtests. Each section notes the It Takes Two (ITT) mechanic it's modeled on and how ours differs.

Roles are fixed for the whole game: **Kai = Player 1 (male)**, **Miko = Player 2 (female)**.

---

## 0. Lobby and character pick

| Rule | Value |
| --- | --- |
| Lobby | One shared platform everyone loads into |
| Capsule pairs | 6 pairs; each pair = 1 Kai capsule (orange) + 1 Miko capsule (teal) + a status screen |
| Picking a character | Step into a Kai capsule → you are Kai; step into a Miko capsule → you are Miko. One player per capsule |
| Lock-in | Starts when both capsules of the same pair are filled; **5 s** countdown on the pair's screen |
| Reset | Either player steps out → countdown cancels; it restarts from 5 when both are back in |
| Launch | At 0, both are frozen in place, then teleported together to their own private main-world server |
| Screen states | STEP IN TO PLAY · WAITING FOR MIKO · WAITING FOR KAI · LOCKING IN... 5–1 · LOADING... · TRY AGAIN (if the teleport fails) |

The role picked in the lobby is the role for the whole run (and for that duo's save).

---

## 1. Controls

Modeled on ITT's PC layout (jump, dash, ground pound/crouch, swing/grind, toggle sprint, primary/secondary ability, interact, cancel, find partner), remapped for Roblox.

| Action | PC | Gamepad | Mobile |
| --- | --- | --- | --- |
| Move | WASD | Left stick | Thumbstick |
| Camera | Mouse | Right stick | Drag |
| Jump / double jump | Space | A / Cross | Jump button |
| Dash | Left Shift | B / Circle | Dash button |
| Ground pound (air) / crouch (ground) | Left Ctrl | Right stick click / R3 | Pound button (appears in air) |
| Swing / grind grab | F | Right bumper | Context button |
| Sprint (toggle) | C | Left stick click | Auto-sprint after 1.5 s of movement |
| Tool use 1 | Left mouse | Right trigger | Tool button 1 |
| Tool use 2 / aim | Right mouse | Left trigger | Tool button 2 |
| Interact / revive | E | X / Square | Context button |
| Ping | Q | D-pad up | Ping button |
| Partner Peek (hold) | Tab | D-pad down | Peek button |

Roblox's default Shift Lock is **disabled** (Shift is dash).

---

## 2. Shared moveset (both players, whole game)

ITT teaches sprint, ground pound, double jump, dash, wall cling and wall jump in its opening tutorial. We keep the same set.

| Move | Value | Notes |
| --- | --- | --- |
| Walk speed | 16 | Roblox default |
| Sprint speed | 24 | Toggle; cancels when stopping |
| Jump height | 7.5 | |
| Double jump height | 6 | Once per air time; resets on landing, wall cling, grapple, swing |
| Dash | 14 studs over 0.18 s | 1 air dash per air time; ground dash cooldown 0.6 s |
| Ground pound | 0.15 s hang, then fall at 110 studs/s | Breaks cracked floors, presses heavy buttons, stuns small enemies in 5-stud radius |
| Ground pound bounce | Landing a pound on a Bounce Pad launches the *other* player standing on it 22 studs up | ITT uses pounds to boost the partner; our version needs the partner on the pad |
| Crouch | Speed 8, height halved | Fits through low gaps |
| Wall cling | Slide down at 4 studs/s for up to 1.5 s | Only on "Clingable" walls (rough texture) |
| Wall jump | 9 up, 12 away from wall | Resets double jump |
| Coyote time | 0.12 s | Jump still allowed just after leaving a ledge |
| Jump buffer | 0.1 s | Jump pressed just before landing still fires |

### Traversal objects (all worlds)

| Object | What it does | ITT counterpart |
| --- | --- | --- |
| Swing Point | Press F in range (18 studs) to swing; release with Jump for a 1.2× speed boost | Swing points everywhere in ITT |
| Grind Rail | Land on or press F near to grind at 40 studs/s; Jump to hop off; can switch rails mid-air | Grind rails (Shed, Tree, Cuckoo Clock) |
| Bounce Pad | See ground pound bounce | Ground-pound partner boosts |
| Jump Vent | Upward air stream; ground-pound its button to flip direction | Shed fans reversed by ground-pounding red buttons |
| Pressure Plate | Stays down while a player stands on it | Common in ITT |
| Duo Gate | Opens only when both plates are held at once | Two-player doors |
| Duo Pound | Button that needs both players to ground-pound within 0.5 s of each other | ITT has moments where both must pound at the same time |
| Heavy Lever | Needs both players pulling (hold E together for 1 s) | Shared levers in The Shed |

---

## 3. Health, death, respawn, revive

ITT respawns a dead player quickly, and in boss fights the dead player can mash a button to come back faster. We keep that and add a partner revive.

| Rule | Value |
| --- | --- |
| Health (platforming worlds) | 3 hearts; 1 heart lost per hit; regenerate 1 heart every 5 s out of danger |
| Health (castle) | 100 HP bar over the head (ITT's dungeon crawler shows health bars over heads too) |
| Fall into a kill zone | Instant respawn at the last safe ground position after 1.5 s |
| Reaching 0 health | Become **Downed** (small ghost, can move slowly, can't use tools) |
| Auto-respawn from Downed | After 5 s (8 s in boss fights) on your own path: where you stood 1.5 s before going down (else the checkpoint). Not next to your partner: in split sections that skipped your part (playtest Oct 1) |
| Mash to respawn (boss fights) | Each press of Jump removes 0.15 s from the timer |
| Partner revive | Partner holds E near your ghost for 1.5 s → you revive on the spot with 1 heart / 30 HP |
| Both Downed at once | Short "GAME OVER?" glitch screen → both restart from the last checkpoint |
| Checkpoints | Shared; touching one saves both players; spaced every 60–90 s of play |

---

## 4. World tools

### Prologue: The Title Screen
Base moves only. Teaches: jump, double jump, dash, ground pound, sprint, wall jump, interact, revive (scripted fall), pressure plates, Duo Gate.

---

### World 1: Pixel Plains — Pause Beam / Grapple Line
**Modeled on:** ITT's Shed, where Cody's nails pin platforms in place and create swing points for May's hammer. Ours: Kai *freezes time on objects* instead of pinning them; Miko swings with her own line instead of from Kai's tool.

#### Kai — Pause Beam
| Use | Input | Value |
| --- | --- | --- |
| **Freeze** | Tool 1 on a Freezable object | Range 60; object stops completely for 4 s; one frozen object at a time; freezing a new one releases the old one |
| **Release** | Tool 2 | Unfreezes early; object resumes exactly where its motion was paused |
| Aim | Crosshair | Soft lock-on to Freezable objects within 6° of the crosshair |
| Visual | Frozen objects turn blue with a pixel "PAUSE ⏸" icon and a 4-s ring timer | |

Freezable things: moving platforms, crushers, falling blocks, swinging hammers, conveyor belts, rotating gears, Freezable enemies (frozen enemies can't attack and can be grappled onto), boss fists.

#### Miko — Grapple Line
| Use | Input | Value |
| --- | --- | --- |
| **Swing** | Tool 1 | Range 45; latches onto Grapple Rings **and any object Kai has frozen**; swing like a Swing Point; release with Jump for 1.3× speed boost |
| **Pull** | Tool 2 on a Pullable object | Range 35; yanks it to 6 studs in front of Miko over 0.4 s; 1 s cooldown; max object mass 50 |
| Aim | Crosshair | Soft lock-on within 8°; valid targets glow orange |

Pullable things: crates, levers (pull = activate), loose wall bricks, boss crowns, small enemies (pulls them toward Miko, stunned 1 s).

#### Signature combos
- Kai freezes a falling block in mid-air → Miko grapples onto it → swings across the gap.
- Kai freezes a crusher at the top of its cycle → both run under.
- Miko pulls a crate onto a Pressure Plate → Kai freezes the moving door it opens before it closes again.
- Kai freezes a Static Bat → Miko grapples to it as a moving-then-stopped anchor.

#### Enemies
| Enemy | Behavior | How to beat |
| --- | --- | --- |
| Glitch Blob | Walks back and forth, 1 heart on touch | Ground pound on it, or Miko pulls it into a hazard |
| Static Bat | Flies in a figure-8, dives at nearest player | Kai freezes it, then either player jumps on it |
| Pixel Crusher (hazard) | Slams down on a 2.5-s cycle | Freeze at the top; can't be destroyed |

#### Set piece: "Glitch Chase" (1.5 min)
The Glitch eats the level behind them. Both grind a long rail through collapsing terrain. Kai must freeze falling blocks that land on the rail ahead; Miko must grapple across broken rail gaps and pull Kai's switch-levers. Missing a beat = respawn at the start of that rail segment (segments are 20 s long).

---

### World 2: Starfall Castle — Fire Mage / Shield Knight (top-down)
**Modeled on:** ITT's Rose's Room castle, a top-down dungeon crawler where Cody is an ice mage (ice blasts, short teleports) and May is a fire-sword knight (sword, flaming dashes, fire bursts), with ability cooldowns and special attacks. Ours: Kai gets **fire** (not ice), Miko gets a **shield** (not a fire sword), and blocking/reflecting is the core combo instead of freezing lava.

**Camera and movement:** top-down, fixed angle, centered on the midpoint of both players. Players can't separate more than 60 studs (an invisible tether pulls the camera out, then stops the leader). Move with WASD/stick, aim with mouse/right stick. No jumping in this world; Dash stays (Kai's becomes a short blink, see below).

#### Kai — Fire Mage (100 HP)
| Skill | Input | Damage | Cooldown | Notes |
| --- | --- | --- | --- | --- |
| Fireball | Tool 1 (hold to auto-fire) | 10 | 0.35 s | Projectile, speed 80; can be reflected by Miko's shield for 1.5× damage |
| Flame Wall | Tool 2 | 4 per 0.5 s | 8 s | 12-stud line, lasts 5 s; blocks enemy movement; enemies pushed through take double |
| Ignite | E on a brazier / web / wooden door | — | 1 s | Lights braziers (reveals dark rooms), burns webs and doors; range 30 |
| Blink (replaces dash) | Dash | — | 3 s | 10-stud teleport; can pass through iron bars |
| **Meteor** (ultimate) | Tool 1 + Tool 2 together when charged | 40 | Charges from damage dealt (300 dmg to fill) | 12-stud radius, 1.2 s cast, marked circle on the ground |

#### Miko — Shield Knight (140 HP)
| Skill | Input | Damage | Cooldown | Notes |
| --- | --- | --- | --- | --- |
| Sword combo | Tool 1 | 8 / 8 / 14 | 3-hit chain | Short arc in front |
| Shield Block | Hold Tool 2 | — | none (hold) | Blocks 100% damage in a 120° front arc; move at 60% speed; **reflects projectiles**, including Kai's fireballs |
| Shield Charge | Dash | 12 + knockback | 6 s | 16-stud rush; breaks cracked walls; shoves enemies (into Flame Walls, spikes, pits) |
| Taunt (passive) | — | — | — | Enemies within 20 studs prefer Miko while Shield Block is held |
| **Rally** (ultimate) | Tool 1 + Tool 2 together when charged | 15 | Charges from damage blocked (250 to fill) | 14-stud shockwave, stuns 2 s |

#### Leveling (castle only)
XP orbs drop from enemies, shared by both players (each gets full XP).

| Level | XP needed | Kai picks one | Miko picks one |
| --- | --- | --- | --- |
| 2 | 100 | Bigger Fireball (+50% size) **or** Faster Cast (cooldown 0.25 s) | Wider Block (160° arc) **or** Longer Charge (22 studs) |
| 3 | 250 | Double Flame Wall (two walls) **or** Ember Trail (Blink leaves fire) | Reflect Boost (reflected shots 2×) **or** Second Wind (+40 HP, heal 20 on Rally) |

#### Signature combos
- Kai fires at Miko's raised shield from behind → the fireball reflects off it, bent 90°, to hit a switch around a corner or an enemy behind cover.
- Miko Shield Charges enemies into Kai's Flame Wall.
- Kai Ignites braziers so Miko can see pressure-plate traps in dark rooms.
- Kai Blinks through iron bars to hit a plate that lowers a bridge for Miko.

#### Enemies
| Enemy | HP | Behavior | Counter |
| --- | --- | --- | --- |
| Glitched Skeleton | 30 | Walks in, swings | Any damage |
| Split Slime | 40 → 2 × 15 | Splits when hit | Flame Wall cleans up the pieces |
| Static Archer | 25 | Keeps distance, shoots arrows | Miko blocks and reflects arrows back |
| Shield Guard | 60 | Front shield blocks all damage | Kai hits from behind while Miko holds aggro, or Miko Charges to knock the shield aside |
| Static Mage | 35 | Teleports, casts slow orbs | Rally stun, then burst |

#### Set piece: "Siege Cart" (2 min)
They ride a mine cart through the castle on a fixed track (camera still top-down). Kai burns wooden barricades ahead before the cart hits them; Miko blocks arrow volleys from archers on the walls. Barricade hit or both players at 0 HP = restart the ride.

---

### World 3: Glitched Core — Copy/Paste / Layer Shift
**Modeled on:** ITT's Cuckoo Clock (time rewind vs. clone-and-teleport, planning-heavy puzzles) for the *thinking* style, and Hazelight's Split Fiction final level for the *split information* idea. Ours: one player sees a hidden layer, the other duplicates objects.

#### Kai — Copy/Paste
| Use | Input | Value |
| --- | --- | --- |
| **Copy** | Tool 1 on a Copyable object | Range 50; stores 1 object (a new copy overwrites the old); white outline on Copyable objects |
| **Paste** | Tool 2 | Shows a ghost preview while held; release to place within 40 studs; max 2 pasted copies in the world (a 3rd removes the oldest); can't paste overlapping a player; rotate preview with R |

Copyable things: platforms, crates, bridge pieces, springs (Bounce Pads), keys (pasted keys vanish after opening one door), anything Miko pulls out of the Code Layer.

#### Miko — Layer Shift
| Use | Input | Value |
| --- | --- | --- |
| **Shift** | Tool 1 (toggle) | 0.3 s transition; while shifted, Miko sees and can stand on Code Layer objects (green wireframe) and sees hidden wires, arrows and weak points; real-world colors desaturate for her |
| **Pull Out** | Tool 2 on a Code Layer object (while shifted) | Range 35; brings that one object into the real world so Kai can see, touch and copy it; only 1 pulled-out object at a time (pulling another sends the first back) |

Kai **cannot** see Code Layer objects at all. Miko must describe or ping them. This is the most communication-heavy world by design.

#### Signature combos
- Miko shifts, finds a hidden platform, pulls it out → Kai copies it and pastes a second one further along → they cross a gap neither could see.
- Miko reads a hidden code on a wall (only visible in the Code Layer) and tells Kai which of 4 doors to paste a key into.
- A path exists only in the Code Layer. Miko walks it while pulling out one platform at a time for Kai to follow on.

#### Hazards
| Hazard | Behavior | Counter |
| --- | --- | --- |
| Static Field | Damaging zone of flickering static | Miko finds the switch in the Code Layer; Kai pastes a platform over it |
| Glitch Echo | Ghost copies of earlier enemies that flicker in and out; only real (hittable) when pulled out by Miko | Pull out, then ground pound |
| Missing Floor | Sections of ground that disappear when looked at by Kai | Miko pulls out a replacement from the Code Layer |

#### Set piece: "Freefall" (1.5 min)
The core collapses and both fall through a long shaft of debris. Players steer while falling. Miko shifts layers to reveal safe openings in debris walls; Kai pastes copied platforms as brief landing spots to rest the fall timer. Hitting debris = respawn at the last landing.

---

## 5. Bosses

ITT bosses are cooperation-first with multiple phases; some alternate which player they target, and the final chapter's boss is cured rather than destroyed. Ours follow the same patterns.

### The Crusher King (World 1)
| Phase | Boss does | Players do |
| --- | --- | --- |
| 1 | Slams one fist at a time (targets alternate between Kai and Miko) | Kai freezes the fist; Miko grapples onto it and ground-pounds the crystal on his wrist (3 hits) |
| 2 | Floor tiles fall away every 3 s; boss throws blocks | Kai freezes falling floor tiles to stand on; Miko swings between them to reach his shoulders |
| 3 | Glitch shield around him; crown glows | Kai freezes the whole king for 4 s; Miko grapples up and **pulls** the crown off |

### The Hollow Dragon (World 2, top-down)
| Phase | Boss does | Players do |
| --- | --- | --- |
| 1 | Static breath beam aimed at one player | Miko blocks the beam with the shield while Kai burns 4 glowing scales on its sides |
| 2 | Flies, summons skeletons and archers, lands every 20 s | Miko charges minions into Flame Walls; Kai Meteors the dragon when it lands |
| 3 | Splits the arena with a static wall with one small gap | Miko stands at the gap with shield raised; Kai fires into the shield so reflections pass through the gap and hit the dragon's heart |

As built (Oct 10, 2026, `Bosses/HollowDragon.luau`, numbers in `Tuning.HollowDragon`): the dragon hovers over a hole the Glitch ate in the back of the throne hall (floor ends at z 1600). (1) breath windup line 1.4 s → beam 2.6 s tracking at 28°/s, 5 dmg / 0.35 s; a raised shield facing the mouth cuts it for everyone behind; the 4 scales (orbs on its legs, fireball height) open only while it breathes, 3 fireballs each. (2) flies a loop, summons Skeleton/StaticArcher (max 6, each fall +0.2 of Kai's Meteor), lands every 20 s (ring 2.2 s, 25 dmg, grounded 7 s); 2 Meteors. (3) wall at z 1575, 8-wide gap moving every 10 s, bombs every 3.5 s; it sinks 9 so the heart is at reflect height; plain fire is swallowed, 4 reflected hits. On defeat the floor knits a bridge over the hole to the hidden room (Memory 2).

### The Unfinished (final boss, World 3)
Each phase swaps **everyone's tools and camera** to a previous world's kit, like the genre shift at the end of ITT's Moon Baboon fight.

| Phase | Kit | Boss does | Players do |
| --- | --- | --- | --- |
| 1 | Pixel Plains (Pause Beam / Grapple Line) | Crusher King attacks, made of static | Freeze and grapple to break 3 crystals |
| 2 | Castle (Fire Mage / Shield Knight), top-down | Hollow Dragon attacks | Reflect fireballs into its heart |
| 3 | Glitched Core (Copy/Paste / Layer Shift) | Becomes a huge static shape. **Damage does nothing** | Pip: "It's not a monster. It's the level you never finished." |
| 4 | Glitched Core, no combat | Slowly stops attacking as the level fills in | Miko pulls out level pieces, Kai copies and pastes them into their slots (6 pieces). Final step: both ground-pound the giant **SAVE** button within 0.5 s |

No new tool appears in the final boss. Everything is something the players already mastered.

---

## 6. HUD and UI

| Element | Where | Notes |
| --- | --- | --- |
| Hearts / HP | Bottom-left (platforming) · over heads (castle) | |
| Tool icons + cooldowns | Bottom-right | Two icons, radial cooldown fill |
| Ultimate meter | Bottom-right (castle only) | Glows when ready |
| Partner outline | World | Kai orange, Miko teal, visible through walls |
| Partner off-screen arrow | Screen edge | Points to partner when not visible |
| Ping marker | World + edge arrow | 4 s life, shows who pinged |
| Partner Peek | Full screen while Tab is held | Your camera shows your partner's view, then snaps back |
| Pip hint | Top-center speech bubble | Auto at 20 s and 45 s stuck |
| Revive prompt | Over a Downed partner | Ring fills over 1.5 s |
| XP bar / level-up picker | Bottom-center (castle only) | Game pauses input for both until each picks |

---

## Sources

- [It Takes Two PC controls — Magic Game World](https://www.magicgameworld.com/it-takes-two-pc-controls/)
- [It Takes Two — Wikipedia](https://en.wikipedia.org/wiki/It_Takes_Two_(video_game)): respawn and boss mash rule
- [The Shed guide — Gamepur](https://www.gamepur.com/guides/it-takes-two-the-shed-gameplay-tips-and-walkthrough-guide): tutorial moves, fans reversed by ground pound
- [Powers and abilities — It Takes Two Wiki](https://ittakestwo.fandom.com/wiki/Power_and_Abilities/Weapons): per-chapter tools, castle mage and knight
- [Rose's Room walkthrough — Neoseeker](https://www.neoseeker.com/it-takes-two/walkthrough/Rose's_Room_(Part_2)): castle co-op puzzles
- [It Takes Two — TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/ItTakesTwo2021): dungeon crawler health bars and cooldowns
- [Moon Baboon fight — Game Rant](https://gamerant.com/takes-two-defeat-every-boss/) and [Neoseeker](https://www.neoseeker.com/it-takes-two/walkthrough/Rose's_Room_Bosses): alternating targets, genre shift
- [Chapter guide — hone.gg](https://hone.gg/blog/it-takes-two-chapters-list/): boss phases, Joy cured instead of destroyed
