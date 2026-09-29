# Glitched Together — Design Document

**Roblox listing:** [2 PLAYER] Glitched Together 👾
**Platform:** Roblox (Luau) · **Players:** exactly 2, online · **Target length:** 1.5–2.5 hours
**Companion files:** `mechanics.md` (every move, tool, enemy and boss in numbers) · `implementation.md` (how to build it in Roblox) · Story Bible (plot, characters, scenes)

This document explains *why* the game works the way it does. It takes the design rules that made It Takes Two great, keeps the ones that fit a Roblox game, and changes the ones that don't.

---

## 1. What we take from It Takes Two, and what we change

| It Takes Two does | Glitched Together does | Why |
| --- | --- | --- |
| Co-op only, no single-player mode | Same: exactly 2 players, no solo | The whole game is built around two people needing each other |
| Married couple turned into dolls, guided by a talking love book (Dr. Hakim) | Two ex-best friends pulled into the unfinished game they made as kids, guided by Pip, the tutorial sprite they never finished | Same emotional shape (repairing a relationship), completely original story |
| 7 chapters, each with new abilities | 3 worlds + prologue + epilogue, each with new abilities | Realistic scope for a solo Roblox developer |
| Each player gets one tool per chapter with two uses (for example, throw nails and recall them) | Same: one tool per player per world, two uses | Easy to learn, still asymmetric |
| Rose's Room turns into a top-down dungeon crawler (Cody = ice mage, May = fire knight) | Starfall Castle is a top-down dungeon crawler (Kai = **fire** mage, Miko = **shield** knight) | Keeps the genre switch players love, with our own class kits |
| Shared moveset: jump, double jump, dash, ground pound, wall jump, swing, grind, sprint | Same shared moveset | This is the "feel" of the game and it stays constant everywhere |
| Split-screen, even online | Each player has their own full screen, plus **Partner Peek** (hold to see through your partner's camera) and an always-on partner outline | Roblox gives each player their own screen; peek keeps the "see what your partner sees" benefit |
| Dead player respawns quickly; in boss fights they can mash a button to come back faster | Same, plus the partner can **revive** you on the spot | Keeps flow fast and adds one more small co-op moment |
| Optional competitive minigames | **None** | Cut on purpose to keep focus and scope tight |
| Friend's Pass (partner plays free) | Game is free on Roblox. Everyone loads onto one **lobby platform** with **6 capsule pairs** (one Kai capsule, one Miko capsule each). Step in to pick your character; when both capsules of a pair are filled, a **5-second lock-in** starts (stepping out resets it), then the pair teleports together to their own main-world server | Same goal: make finding Player Two effortless, and picking a character physical and fun |
| Chapter select after unlocking | Same: world select after unlocking, saved per duo | Lets duos replay favorite worlds |

**Rule of thumb for "like It Takes Two but not exactly":** copy the *structure and feel* (asymmetric pairs, mechanic churn, shared moveset, genre switches, fast respawns, boss phases); never copy the *content* (characters, story, items, level layouts, art, music, names).

---

## 2. Design pillars

These come directly from how Hazelight describes its own design, adapted to us.

### Pillar 1: Built for two from the first line
Hazelight designs co-op from day one instead of bolting it onto a single-player game, and treats communication between players as essential to progress. Every room in Glitched Together must fail this test: *"Can one player finish this alone?"* If yes, redesign it.

### Pillar 2: Two different tools, equally fun
Hazelight insists on asymmetric mechanics and says the hard part is not inventing two mechanics but making them *equally fun*. In the Tree chapter, the sap player had more to do than the match player, so they made enemies attack the match player more to balance engagement.

Our rule: in every world, measure who is "doing something" each 10 seconds of a playtest. If one player is idle more than about a third of the time, rebalance (add threats aimed at them, give their tool a second job, or move a key action to their side).

| World | Kai's role | Miko's role | Balance watch-out |
| --- | --- | --- | --- |
| Pixel Plains | Planner: freezes the world (Pause Beam) | Mover: swings and pulls (Grapple Line) | Kai can feel passive → give him enemies to freeze and timing-critical freezes |
| Starfall Castle | Ranged damage and fire control (Fire Mage) | Frontline, blocking, reflecting (Shield Knight) | Knight can feel like "just a wall" → enemies ignore Kai until Miko draws aggro, reflected fireballs do bonus damage |
| Glitched Core | Builder: copies and pastes objects | Scout: sees the hidden Code Layer and pulls things out | Miko carries the information → Kai must execute the hard timing parts |

### Pillar 3: Mechanics change constantly
Hazelight deliberately avoids repeating major mechanics from level to level, and ties each new mechanic to the story of that chapter. Fares calls variety a design focus he has pushed since 2010 because it drives pacing.

Our rule: every world swaps the tool pair and at least one of: camera style, enemy set, music genre. Within a world, introduce a new *twist* on the tools every 5–8 minutes (for example: freezing a platform → freezing a falling block mid-air → freezing an enemy → freezing a boss fist).

### Pillar 4: The mechanic *is* the story
Fares says the mechanics should reflect what is happening in the story. Ours are chosen that way:

- **Pixel Plains:** the two refuse to talk, so the tools work in sequence (one freezes, *then* the other moves). Cooperation is forced but not yet warm.
- **Starfall Castle:** they become the heroes they designed for themselves as kids. Miko literally shields Kai while he attacks; protection is the theme of Miko's secret.
- **Glitched Core:** only Miko can see the hidden layer, so she has to *tell* Kai what's there. The world is built around talking, right as they finally start to talk.
- **Final boss:** the villain is "completed," not killed, using the same World 3 tools they just mastered.

### Pillar 5: Short, polished, then gone
Hazelight spends months polishing mechanics that players use for only a few minutes, and Fares has said the challenge is polish, not ideas. For a solo dev, the lesson is: **fewer ideas, each one fully polished.** Better 3 great worlds than 5 rough ones.

### Pillar 6: Clarity and innocence
Fares describes It Takes Two as a love letter to Nintendo, crediting 90s games like Mario 64 and Banjo-Kazooie, and praises the clarity and innocence Nintendo and Pixar share. Our read for Roblox: bright readable colors, obvious interactables (every tool target has a consistent color and icon), jokes from Pip, and emotional beats that land without being heavy.

---

## 3. Game structure

```
Lobby (capsule lock-in) → Prologue → World 1: Pixel Plains → World 2: Starfall Castle → World 3: Glitched Core → Epilogue
```

| Part | Length | Camera | Tool pair | Boss | Story payoff |
| --- | --- | --- | --- | --- | --- |
| Prologue: Title Screen | 5–10 min | Third-person | Base moves only | none | They're stuck together and refuse to talk |
| World 1: Pixel Plains | 25–35 min | Third-person, some side-on | Pause Beam / Grapple Line | The Crusher King | Memory 1 "Level One": the pinky promise |
| World 2: Starfall Castle | 30–40 min | Top-down | Fire Mage kit / Shield Knight kit | The Hollow Dragon | Memory 2 "The Hidden Room": Miko's side |
| World 3: Glitched Core | 30–40 min | Third-person | Copy/Paste / Layer Shift | The Unfinished | Memory 3 "Launch Day": Kai's side, the letter |
| Epilogue | 3–5 min | Cutscene | none | none | They talk again in the real world |

### Anatomy of a world
Every world follows the same beat pattern (loosely based on how It Takes Two chapters introduce a tool, build on it, and end on big set pieces and bosses):

1. **Arrival cutscene** (under 60 s): new look, new tools, one story line.
2. **Teach (section X-1):** each tool alone, in a safe space. Pip gives one hint line if a player is stuck for 20 s.
3. **Combine (section X-2):** puzzles that need both tools in sequence.
4. **Twist (section X-3):** a new use of the tools, harder timing, enemies.
5. **Set piece:** a 1–3 minute scripted high-energy sequence (chase, ride, fall). It Takes Two is full of these: rail chases, flying, shooting.
6. **Boss:** 3 phases, each teaching or remixing one idea.
7. **Memory cutscene + end scene:** the story payoff and a hook into the next world.

---

## 4. Puzzle design rules

### The Hazelight formula
Hazelight's designer on Split Fiction's final level described a puzzle formula at GDC 2026: **split the information, split the execution, finish with timing.** Use it for every multi-step puzzle:

1. **Split the information:** one player can see or know something the other can't (Miko sees the Code Layer; Kai sees a platform's rhythm from above).
2. **Split the execution:** the solution needs both tools (Kai freezes, Miko swings).
3. **Finish with timing:** the last step needs both players to act together (both ground-pound the plate, release within a window).

### People are bad at talking; design for it
Hazelight found that two players often each hold half a puzzle on their screens and say nothing, so information gets lost more easily than in single-player. They also found that if one player *can* run ahead and leave the other behind, they usually will without noticing.

So:

- **Put the clue on the screen of the player who can't use it.** The player who needs to act should have to ask.
- **Give a voiceless way to communicate:** the Ping key (Q) and Partner Peek (Tab). Many Roblox players don't use voice chat.
- **Sync points everywhere.** Every section ends with a two-player gate (both plates, both ground-pound, both pull a lever). No section can be skipped by one player.
- **No backtracking.** Doors lock behind the pair once both pass a gate, so neither can wander back.
- **Pip nudges, never solves.** Hint 1 at 20 s stuck: a general nudge. Hint 2 at 45 s: points at the object. Never the full answer.

### Teaching without text
Each tool is taught in three rooms: (1) a room where only that tool works, (2) a room where it obviously combines with the partner's tool, (3) a room where it's used in a surprising new way. Tutorial text is at most one short line per tool, shown once.

---

## 5. Level design rules

- **Readable targets:** every object a tool can affect has a consistent look everywhere in the world. Freezable = blue frame. Grapple points = orange rings. Pullable = yellow handles. Burnable = cracked wood texture. Copyable = white outline. Code Layer = green scanlines (Miko only).
- **Both players always have something to do.** No "wait here while I do the puzzle" moments longer than 10 seconds.
- **Checkpoints every 60–90 seconds of play**, always right after a sync gate and right before any hard jump sequence.
- **Death is cheap.** Falls respawn in under 2 seconds. Frustration kills co-op faster than difficulty.
- **Short sections, clear end.** Each section is 5–10 minutes and ends at a visible landmark (a door, a portal, a staircase).
- **Show the next goal early.** Let players see the boss arena or the exit from far away before they get there.

---

## 6. Boss design rules

It Takes Two's bosses emphasize cooperation over reflexes, and the biggest ones have three or four phases. Some patterns worth keeping:

- **Phases teach, then combine.** Phase 1 uses one tool idea, phase 2 adds pressure, phase 3 combines everything.
- **Alternate the target.** Bosses like the Moon Baboon switch which player they focus. Our bosses do the same so both players get "hero" moments and both get "save your partner" moments.
- **Change the genre in the last phase.** The Moon Baboon fight ends in a flying section. Our Unfinished fight swaps the tool kits per phase (World 1 kit → castle kit → World 3 kit).
- **The ending can be non-violent.** In the Garden, the final boss is cured rather than destroyed. Our final boss is *completed*, not killed.

### A warning from It Takes Two's ending
Fares said the original ending was scrapped because it switched up the game mechanics too much and felt out of context. That's why our last phase uses the World 3 tools the players already mastered, not a brand-new mechanic. Do not add a new tool in the final 10 minutes.

---

## 7. Camera and presentation

- **Default:** third-person follow camera, slightly higher and wider than Roblox's default so players see more of the level.
- **Side-on sections:** in some Pixel Plains parts the camera locks to the side like a classic platformer.
- **Top-down (castle):** one shared overhead camera logic, centered on the midpoint of both players, zooming out as they separate (max distance enforced).
- **Partner Peek (Tab / on-screen button):** hold to see through your partner's camera; release to snap back. Replaces It Takes Two's always-on split screen.
- **Partner outline:** your partner is always visible through walls with their color (Kai = orange, Miko = teal).
- **Cutscenes:** letterboxed, under 60 seconds, skippable only when *both* players press skip.

---

## 8. Art and audio direction

| World | Visual style | Palette | Music |
| --- | --- | --- | --- |
| Prologue | Giant broken title menu, floating UI buttons | Dark navy, white UI, pink glitch accents | Title theme, slow, lonely |
| Pixel Plains | Chunky blocks, flat colors, pixel clouds | Bright greens, sky blue, coin gold | Chiptune, upbeat |
| Starfall Castle | Stone halls, banners, torches, stained glass | Deep purple, torch orange, gold | Orchestral fantasy |
| Glitched Core | Untextured grey blocks, wireframes, static | Grey, black, glitch green and magenta | World 1 + 2 themes, broken and remixed |
| Epilogue | Real-world bedrooms, then a starry kingdom | Warm night blues | Title theme, now full and hopeful |

**Glitch as a visual language:** The Glitch always looks the same everywhere: flickering static, RGB split edges, a "missing texture" checker pattern. Players learn to read it as "danger" in minutes.

**Pip's voice:** short bleeps with text, never long lines. Pip has placeholder lines ("INSERT JOKE HERE") that become real lines as the game is completed.

---

## 9. Playtesting

Hazelight tests with fresh players and watches for specific co-op problems: are players solving puzzles without realizing they helped each other, do they understand the co-op design, and did they finish a section without ever communicating? Use the same questions.

**Per session checklist**

- [ ] Did either player get stuck for more than 60 s? Where?
- [ ] Did either player sit idle for more than 10 s at a time? Where?
- [ ] Did they finish any section without talking or pinging? (If yes, that section isn't co-op enough.)
- [ ] Did one player run ahead and leave the other? (Add a sync gate.)
- [ ] Did they understand what each tool does within 1 minute of getting it?
- [ ] Which moment made them laugh or shout? Protect it.
- [ ] Which moment did they complain about? Fix it before adding anything new.

**Test with:** at least one pair who knows each other and one pair of strangers who met at the lobby capsules. Also test with one player on mobile.

---

## 10. Scope guardrails

- 3 worlds, 3 bosses, 1 set piece per world. Anything more goes on the "after launch" list.
- No minigames.
- No new tools in the final boss.
- Every new mechanic must be playable as a grey-box prototype with both players before any art is made for it.

---

## Sources

- [It Takes Two — Wikipedia](https://en.wikipedia.org/wiki/It_Takes_Two_(video_game)): co-op-only design, respawn rules, mechanics changing every level
- [Hazelight on co-op mechanics — 80.lv](https://80.lv/articles/hazelight-studios-working-culture-and-approach-to-creating-collaborative-gameplay): asymmetric balance (sap/match), communication, syncing players, playtesting
- [Josef Fares interview — The Ringer](https://www.theringer.com/2021/04/22/video-games/josef-fares-it-takes-two-interview-co-op-gaming): variety, mechanics reflecting story, polish
- [Josef Fares interview — AV Club](https://www.avclub.com/josef-fares-it-takes-two-interview): variety of mechanics and pacing
- [Josef Fares interview — Game Rant](https://gamerant.com/it-takes-two-interview-josef-fares-turn-me-up-switch-port/): why the original ending was cut
- [Josef Fares interview — Pocket Tactics](https://www.pockettactics.com/it-takes-two/interview): Nintendo influence, clarity and innocence
- [GDC 2026 recap — Invisible Friends](https://www.invisiblefriends.net/gdc-2026-a-personal-account/): Hazelight puzzle formula (split information, split execution, finish with timing)
- [It Takes Two chapter guide — hone.gg](https://hone.gg/blog/it-takes-two-chapters-list/): chapter mechanics and bosses
- [It Takes Two — TV Tropes](https://tvtropes.org/pmwiki/pmwiki.php/VideoGame/ItTakesTwo2021): castle dungeon-crawler section, cooldowns
