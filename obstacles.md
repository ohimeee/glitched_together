# Glitched Together — Obstacle Design (It Takes Two research → our own obstacles)

Research done Oct 1, 2026: a full read of every It Takes Two (ITT) chapter walkthrough (Neoseeker, walkthroughs.games, VGTimes; sources at the end). Part 1 lists **how ITT builds its obstacles**: the reusable patterns behind every puzzle, with examples. Part 2 turns those patterns into **our own obstacles** for each world, built from our tools and themes. Part 3 lists the new engine pieces they need.

Rule (design.md §1): we copy the **pattern** (how two players depend on each other), never the **content** (ITT's objects, layouts, names, art). Every obstacle below is built from our own tools (Pause Beam, Grapple Line, Fire Mage, Shield Knight, Copy/Paste, Layer Shift) and our worlds' themes.

---

## Part 1 — How It Takes Two builds obstacles

### 1.1 The 14 patterns

Nearly every ITT obstacle is one of these, or two of them chained. The examples show how often each one comes back in a new form.

| # | Pattern | How it works | ITT examples |
| --- | --- | --- | --- |
| P1 | **Prop and cross** | One player holds something in a state (open, raised, lit); the other crosses while it holds. The state fades when released, slowly, so there is a little slack | Hammer raises a platform, nail locks it (Shed); Cody rewinds a wall and holds it while May passes; May sings to keep a gate up and has to keep singing as both walk under it (Attic); Cody holds a bulb open, and letting go kills May (Garden) |
| P2 | **The holder can't move** | The prop player is rooted while using the tool, which forces a split: one stays, one goes | Cody can't move while rewinding time; Cody grows into a giant to hold a wheel; holding a lever extends a platform that slides back |
| P3 | **Set, then use** | One player places or prepares something; the other uses it | Nails → hammer swing; sap → match explosion; Cody grows a vine and sprouts leaves for May to jump on; Cody fires magnet plates onto an ice wall for May to climb |
| P4 | **Partner launcher** | One player stands on something; the other triggers it and flings them | Statue smashes and flings May; catapult loaded with a magnet; size-change seesaw; mushroom bounce charge; air pump balloon; speaker blast; sap furnaces blast Cody up two levels |
| P5 | **Operator and runner** | One player works a station (crank, dial, crane, knobs, spotlight, mics); the other platforms through what it moves. The operator sees the whole course; the runner sees only the next step | Dino crane bites platforms for the dino rider; reel-to-reel knobs set platform heights; clock dial moves debris; wheel turned while the partner runs on top of it; spotlight in a dark room; four mics steer a hover platform; magnet-plate cannon |
| P6 | **Split information** | The player who can act can't see the answer; the other has to say it | Pinball (the operator can't see the walls far down the tube); clock symbols seen in one room, pounded in another; mirrored floor puzzle |
| P7 | **Exactly together** | Both press, pound, pull or fire at the same moment (or within a short window) | Two buttons pounded at once; both pull the breaker; both magnets on at once to meet in the middle; trapeze swing timed to throw a ball across |
| P8 | **Marker shortcut** | Leave a marker past a barrier, trigger it from this side, then jump to the marker before it closes | May's clone past a timed hatch; clone at the top of collapsing stairs; clone inside a key cage that moves up and down |
| P9 | **Cycle hazards** | Things move on a fixed rhythm and you learn the safe window | Saws, swinging lamps, flipping number blocks, platforms that solidify when a clock hand points at their color, platforms that move to the music's beat, sinking platforms |
| P10 | **Escort an object** | Move one thing along a route together: carried, rolled, tilted or launched | Cheese ball rolled on a tilt board that both players stand on; Rube Goldberg ball through hamster wheels; conductor poles carried and arranged; 3 coins into a slot |
| P11 | **Lure the enemy** | The enemy can't be hurt directly; bait it into the environment | Bull charges a pressure plate into a bust; troll smashes its own chains; beetle stampedes over sap holes; bombs lured to the lit clocks |
| P12 | **Partner as the floor** | One player's body or ability is the other player's ground | Grass-field Cody carries May over noisy shells; vine leaves; shrunken Cody inside a cube May drags |
| P13 | **Ride / vehicle split** | One drives, one shoots or clears | Raft (steer + shoot larvae); plane (fly + turret); beetle ride; pedal ship with two cannons; hover platform |
| P14 | **Chase / auto-scroll** | Something huge forces constant forward motion; short segments with checkpoints | Snake chase, mole chase, grinder in the dungeon, rolling disco ball, collapsing tower |

Less common but memorable: **stealth with a shared noise meter** (mole cave: sounds from either player fill one meter), **mini-genre rooms** (classroom math, memory cards, a two-person drawing toy), and **"meet in the middle"** (magnets pulling the two players together across a gap).

### 1.2 How a chapter escalates one mechanic

The Shed's Underpass shows the rhythm. One tool pair, each step adds exactly one thing:

1. Hammer raises a platform → nail holds it (P1).
2. Nails in a row → swing across (P3).
3. Two platforms at different heights, both set before climbing (P1 × 2).
4. A descending platform opens a door → nail the door (P1 with a timer).
5. Hammer launches Cody up (P4).
6. Saw cycle + hammer timing (P9 + P1).
7. Alternating vertical lifts, strict order (P5-lite).
8. Boss: nail the slamming hand, hammer the locks (the same P1, at boss scale).

Cuckoo Clock does the same with rewind + clone: rebuild → hold → clone past → statue launch (P4) → three plates with a clone (P7 via P8) → operator dial with color platforms (P5 + P9) → bull lured into a bust (P11).

**Takeaway:** a world uses 4–6 patterns, and the twist is usually **the same tool used for a different job** (rewind becomes a launcher; sap becomes a chain fuse; magnets attract each other).

### 1.3 Implementation details worth copying

- **Things fade instead of flipping off.** Released platforms slide back slowly; frozen lava melts; the sap gun dries out if held; May's song has a breath meter. That gives timing pressure without a visible timer.
- **The safe-side respawn rule.** In the laser hop, if one player reaches the far side, a player who dies respawns there. It stops a 2-player obstacle from being twice as hard.
- **Weight objects show their state.** Sap makes yellow objects heavier; the more sap, the further they tip. The amount is the readable state.
- **Everything is color coded.** Yellow = sap target, red/blue = magnet polarity, white walls = gravity boots. That matches our owner colors (art-direction.md §6).
- **Show the next piece.** The camera points at the debris the runner has to reach next ("camera-focused so you won't get lost").
- **Short chase segments.** Each segment has its own checkpoint, so a mistake costs seconds.
- **Optional toys everywhere** (a torture-chamber button, a swing, a photo booth). Cheap, funny, and they make a space feel alive. Ours: Pip-flavored toys (design.md Pillar 6).
- **The enemy is the key.** Most bosses and mini-bosses are puzzles with HP (P11). Damage alone rarely wins.

---

## Part 2 — Our obstacles

Each entry: **name** · pattern(s) · who does what · Hazelight formula (I = split information, E = split execution, T = finish with timing; design.md §4) · status. Gap and height numbers use the reach table in CLAUDE.md note 2 (no dash bypasses: tool-only gaps ≥ 55 or ≥ 18 up).

### 2.1 Already built (so we don't repeat them)

Pixel Plains: freeze pillars, crusher corridor, grapple chasm, crate climb, lever bridge, frozen falling block swing, windmill arm, frozen cloud crossing, bounce pad launch, frozen bat anchor, fan, elevator cloud, conveyor belts, dropper pit, crate + plate + timed door, coin press, Glitch blob yard, Glitch Chase rails. Castle: braziers, wooden door, cracked wall charge, blink bars + plate, two-plate gate. Core: one hidden bridge demo.

Patterns we already use: P1, P3, P4 (bounce pad), P7 (plates, Duo Pound, Heavy Lever), P9, P14. **Missing entirely: P5 (operator/runner), P6 in a strong form, P8, P10, P11, P12, P13.** Those are where the new obstacles come from.

### 2.2 World 1 — Pixel Plains (Pause Beam / Grapple Line)

The big unused idea: **Release is a launcher.** Today Release only unfreezes early. Paired with Grapple, it becomes ITT's statue fling (P4) and doubles Kai's job.

| Name | Pattern | Who does what | Formula | Fits |
| --- | --- | --- | --- | --- |
| **Spring Snap** ✅ | P4 | A spring pumps on a cycle. Kai freezes it squashed; Miko stands on it; Kai **Releases** → she's flung up a 26-stud cliff and pulls the lever for Kai's lift (Spring Yard). A Release never launches the releaser | E, T | 1-1 teach: "Release = launch" |
| **Crank Ferry** ✅ | P5 + P9 | A ferry crosses a 60-stud chasm under a crusher only while someone cranks. Miko cranks Kai over while he freezes the crusher; Kai cranks her over from his side (or freezes the crusher so she can swing on it) | E, T | Spring Yard |
| **Pendulum Fling** ✅ (Swing Works: swing cradle) | P4 + P9 | A pixel wrecking ball swings over a pit. Kai freezes it at the back of its swing; Miko grapples onto it; Kai Releases and the swing carries her across (jump off at the far peak) | E, T (jump at the peak) | 1-2 combine |
| **Crusher Elevator** (rejected for now: Kai can freeze it, step on and ride it up alone when the freeze runs out; needs a partner-only rule first) | P4 + P1 | Kai freezes a crusher at the bottom; Miko stands on its head; Release → it rises and carries her to a high pipe. The reverse of "freeze to run under" | E | 1-3 twist |
| **Switch Blocks** ✅ (Switch Towers, after Swing Works) | P6 + P5 | Retro ON/OFF blocks (gold ON / sky OFF, `SwitchBlock` tag, `Phase` + `Group`). A 70-stud wall splits two climbs; every safe pillar is 18 up from the last, so each step needs a flip. Miko's teal lever flips Kai's tower (she can't see it, he calls); up top Kai's plate flips Miko's tower (roles swap). Last hop of each needs a mid-air flip. Side-on camera per tower | I, E, T | 1-2 |
| **Scroll Lock** | P14 + P1 | A side-on auto-scroll section (the screen edge is a Glitch wall). Kai freezes **the scroll itself** for 4 s (a big ⏸ on the wall) to give Miko time for a 3-pull lever chain; Kai's freeze recharges only when Miko pulls a coin bell | E, T | Glitch Chase extension |
| **Spin Cannon** ✅ | P4 + P9 | A cannon turns on a turntable. Kai freezes it when it points at the island (Release launches along its aim), Miko rides it over; she pulls the lever for Kai's bridge | E, T | Swing Works |
| **Coin Bonk Stairs** ✅ (after Fire Bar Run, checkpoints 24–25; solo-verified, not 2P-tested) | P3 + P9 | Miko's Pull bonks a teal ? block (`BonkBlock`) and a coin step pops out and sinks at 9 studs/s; Kai freezes it at the height they need. Climb 1: one step up a 20-stud wall. Climb 2: a chain: from a frozen step Miko bonks the next block (only in range from there); Kai's new freeze drops the old step, so they jump as he freezes | E, T | 1-3 |
| **Firebar Spin** ✅ (Fire Bar Run, after Coin Press, checkpoints 22–23; solo-verified, not 2P-tested) | P9 + P5 | Four 16-tall red fire bars spin (±150°/s) down a corridor only Miko reaches (56-stud grapple chasm). Kai walks a glass gallery alongside (glass `CanQuery` off, so the beam aims through) and freezes the bar ahead of her when it points down the corridor. She swings up an 18-stud cliff and pulls the lever that lifts Kai; both plates | E, T | 1-3 |
| **Balance Scale** | P10 + P1 | A giant pixel seesaw over a pit. Miko pulls crates onto one side to tip it; Kai freezes it at the right angle; both run up the frozen beam. Wrong crate count = the wrong angle | E | 1-3 |
| **Warp Pipe Swap** | P7 | Two pipes, one each side of a wall: both pound their pipe within 0.5 s to swap places (the player each side needs the other's tool) | E, T | sync point |

### 2.3 World 2 — Starfall Castle (Fire Mage / Shield Knight, top-down)

ITT's dungeon used freeze-the-lava and blink-through-bars. We already have bars; our unique hook is **the shield reflects fire**, so we build a light-and-mirror world around it.

| Name | Pattern | Who does what | Formula | Fits |
| --- | --- | --- | --- | --- |
| **Ricochet Relay** ✅ (teal crystal: only reflected fire) | P3 + P6 | A switch sits around two corners. Kai fires at Miko's shield; she angles the shot (90° bounce) into wall mirrors and on to the switch. Kai can't see the switch from his side (dark corridor); Miko can | I, E | 2-1 teach |
| **Torch Run** ✅ (after Mirror Gate: Kai in a barred gallery lights `BurnOut` braziers over the wall, Miko walks a 5×14 spike-tile floor whose ✕ marks show only within 12 studs of a lit brazier; plate each side; verified solo in Studio Oct 1) | P1 + P9 | Dark Library: braziers burn out after 6 s. Kai lights them in a chain while Miko walks the floor that only shows its pressure-plate traps in firelight; Kai has to stay ahead of her | I, E | 2-2 |
| **Shelf Shove** | P10 | Library maze of sliding bookshelves (a top-down sliding puzzle). Miko Shield Charges shelves one tile; Kai sees the rune order on the ceiling map and calls the next shelf | I, E | 2-2 |
| **Ember Fuse** | P3 | A rope-bridge network over a chasm: Flame Wall burns ropes, and a burnt rope drops its bridge into place on the far side. Wrong rope = bridge lost; Miko blocks the archer volleys while Kai aims | E | 2-2 |
| **Golem Lure** ✅ (Golem Hall: Kai burns 3 pillars, Miko draws the charge into them) | P11 | An iron golem that weapons can't hurt. Miko's Taunt draws its charge; she sidesteps and it smashes a support pillar; Kai Meteors the falling ceiling onto it when it's stunned | E, T | 2-3 mini-boss |
| **Mirror Gate** ✅ (orange + teal crystals, 1.5 s windows, a corner mirror into the teal nook) | P7 + P3 | A door with two crystal eyes: one takes a straight fireball, the other a reflected one, within 1 s of each other | E, T | sync point |
| **Spike Roller Hall** ✅ (built as: the roller stalls on Miko's shield, Kai blinks through it to the plate that opens her side passage) | P9 + P12 | A spiked roller sweeps a corridor; the alcoves are too small for two. Miko holds Shield Block in front and the roller stalls on the shield for 2 s while Kai blinks past | E, T | 2-1 twist |
| **Siege Cart** ✅ (after Golem Hall, castle checkpoints 9–10; tuned with the user in solo play Oct 1) | P13 + P14 | Both board a cart (`SiegeRide`) that rolls a ~975-stud track over the void at 11 studs/s (~90 s). Kai burns 24 barricades ahead (Ignite); Miko shields arrows from ~41 rooted archers on posts (10 dmg every 1.4 s, led shots, every 25 mid-ride with pairs on both sides, every 30 on the last leg + 2 at the very end). Hitting a barricade or leaving the cart crashes it: back to the dock, or to the halfway STATION (s 600: 2.5 s stop, +50 HP each) once passed | E | set piece |

### 2.4 World 3 — Glitched Core (Copy/Paste / Layer Shift)

This is our Cuckoo Clock: the planning chapter. The unused idea: **Pull Out is a remote operator.** Miko changes what's real; Kai builds with it.

| Name | Pattern | Who does what | Formula | Fits |
| --- | --- | --- | --- | --- |
| **Paste Past the Door** ✅ (2P-tested Oct 1, then made harder after "kinda easy": the only crate is in the Code Layer behind the door, and one pull at a time forces the order crate → copy → plate → paste; verified solo) | P8 | Our clone-teleport. The door plate counts only players (`PlayersOnly`), so whoever holds it can't pass. Through the open door shifted Miko pulls out the code crate (Kai copies it), then the plate's twin (the crate drops back); Kai pastes his crate copy on it and the door (`AnyOf` P1,P2) stays open for her. `NoPaste` volumes stop paste stairs over the walls | E, T | 3-1 twist |
| **Wire Circuit** ✅ | P6 + P10 | Two sockets in the floor that only Miko sees (wires run to the door). Only pastes power them, and Kai has exactly two: she calls where, he pastes the conductor copies | I, E | 3-1 |
| **Phantom Steps** ✅ (Frame Counter) | P9 + P6 | Steps are solid on two of four frames (overlapping, so you hop every beat) and drawn only in the Code Layer, with a frame counter only Miko reads. Kai jumps blind on her calls | I, T | 3-2 |
| **Ghost Bridge** ✅ | P10 + P3 | Miko pulls a code plank out over gap 1 so Kai can cross; he copies it while it's out and pastes it mid-air over gap 2, which has no plank at all (neither crosses it alone) | E | 3-2 |
| **Split trials** ✅ | P3 | 3-1 opener: Kai leapfrogs two pastes over a 60-stud void; Miko walks code stones only she can stand on; both plates raise the bridges | E | 3-1 |
| **Layer Hop** | P12 | Alternating stepping stones: real ones (Kai) and code ones (Miko, shifted). Miko pulls out one code stone at a time so Kai can follow on it, then lets it drop back when she needs the next | I, E | 3-2 Wire Maze |
| **Counterweight** | P10 + P4 | A scale lift: Kai pastes copies of a heavy block on one side to lift Miko on the other; too many copies and she's flung off the top (max 2 pastes, so the third removes the first: real decisions) | E | 3-2 |
| **Unloaded Chunk** | P5 | A dark "unrendered" zone: the floor only loads inside the white scan cone of Kai's copier. Kai aims the cone (he stands at a terminal); Miko runs, shifted, and pulls out the missing floor pieces | I, E | 3-3 Memory Lane |
| **Echo Lure** | P11 | A Glitch Echo can't be hit until pulled out. Miko pulls it out into Kai's pasted cage, then both ground-pound the cage | E, T | mini-boss |

### 2.5 Whole game: cross-world beats

- **Shared noise meter** (stealth, P-extra): once in the castle Dark Library ("don't wake the Static Mages"): both players' footsteps on loose tiles fill one meter.
- **Meet in the middle** (P7): the final boss's SAVE approach. Both stand on opposite sides of a gap and Duo Pound at the same moment to slam a bridge together.
- **Optional toys** per world, with no reward except a laugh: a Pip "DO NOT PRESS" button (Pip gets launched), a coin-block drum kit, a castle bell rope that rings both players up, a Core "undo" sign that does nothing.

---

## Part 3 — New engine pieces (build these first, then the obstacles are level data)

| Piece | What | Unlocks |
| --- | --- | --- |
| **Release-launch** ✅ built Oct 1 (Spring Yard) | MoverService: when a frozen mover is Released, any character standing on or grappled to it gets that mover's current velocity × `Tuning.ReleaseLaunch`, plus a vertical floor | Spring Snap, Pendulum Fling, Crusher Elevator |
| **Station** (crank / dial / terminal) ✅ built Oct 1 (`StationService`, crank ferry) | InteractableService: hold E to occupy (you're rooted, P2); move input drives a linked mover's `t` or angle; let go and it eases back (P1 "fade") | Switch Blocks, Balance Scale, Unloaded Chunk, castle shelf maze |
| **Cycle part** | Generic on/off or rotate-on-a-beat part (`Period`, `Phase`, `OnTime`), freezable | Firebar, Frame Counter, Spring Snap, switch blocks |
| **Mirror / reflector** ✅ built Oct 1 | CombatService: tagged reflector parts bounce projectiles like the shield | Ricochet Relay, Mirror Gate |
| **Weight scale** | Two-pan lift whose height follows the mass on each pan | Balance Scale, Counterweight |
| **Switch blocks** ✅ built Oct 1 (`SwitchBlock`, `Group` + `Phase`) | Solid only while their group's state matches their phase; ghost otherwise | Switch Towers |
| **Gate AnyOf / PlayersOnly / NoPaste** ✅ built Oct 1 | Gate opens on any of several groups; plates that only count players; volumes where pastes are refused | Paste Past the Door |
| **Burn-out braziers + fire traps** ✅ built Oct 1 (`BurnOut`, `FireTrap`) | Braziers go dark after a few seconds; trap marks show only in firelight | Torch Run |
| **Siege ride** ✅ built Oct 1 (`SiegeRide`, `Cart` tag, archer `Rooted`) | A cart on a track that starts when both are aboard, crashes on unburned barricades or a rider leaving, resets everything | Siege Cart |
| **Bonk blocks** ✅ built Oct 1 (`BonkBlock`, ContraptionService.Bonk) | Miko's Pull pops a sinking, freezable coin step out of a ? block | Coin Bonk Stairs |
| **Safe-side respawn** | HealthService: if your partner crossed this obstacle's `SafeSide` part, you respawn there | every hard timing obstacle |
| **Next-piece camera hint** | CameraController: a short look-at toward a level-placed `Hint` part when you enter its zone | operator/runner rooms |

**Suggested build order:** Release-launch → Station → Cycle part (small, and they power most of the new obstacles) → Pixel Plains additions → Core lengthening with these (already the next task) → castle mirrors.

---

## Sources

- [Neoseeker It Takes Two walkthrough](https://www.neoseeker.com/it-takes-two/walkthrough/): The Tree, Rose's Room parts 1–2, Cuckoo Clock, Snow Globe, Garden, Attic (read in full)
- [walkthroughs.games mission list](https://walkthroughs.games/lorebase/it-takes-two/missions): Underpass, Under Voltage, Fresh Air/Captivity/Rooting, Wasp Queen, Escape, Tool Box
- [VGTimes complete walkthrough](https://vgtimes.com/guides/114022-complete-walkthrough-it-takes-two-bosses-and-puzzles-at-all-levels.html): The Shed
- [9Puz chapter overview](https://9puz.com/2374-it-takes-two-walkthrough/)
- [Hazelight on co-op mechanics — 80.lv](https://80.lv/articles/hazelight-studios-working-culture-and-approach-to-creating-collaborative-gameplay)
- [Game Maker's Toolkit: It Takes Two co-op level design (with Oliver Granlund)](https://x.com/gamemakerstk/status/1441068467000651776)
