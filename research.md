# Glitched Together — Research Notes (It Takes Two art, feel, co-op)

Short notes gathered before building. They feed `src/shared/Config/Worlds.luau` (lighting and palettes), `Tuning.luau` (movement) and the level-building rules in `design.md`.

## Art direction

- Hazelight's word during It Takes Two was **"Pixar-esque"**: big focus on **scale, shape and a stylized approach without losing realism**, with tiling textures selling the materials. It was a deliberate swing from the gritty realism of *A Way Out* to something "lively, vibrant and inviting".
- The tiny characters in a huge world are what make everyday places feel fantastic. For us: make players small against chunky, oversized level pieces (giant title-screen buttons, huge pixel blocks, towering castle doors).
- **Performance and visual clarity** were constant constraints, balanced against a world rich enough to invite exploration.
- Split Fiction gives each hero a **shape motif and a color set that survives every costume** (Mio: triangle, red/blue/magenta; Zoe: circle, green/yellow/turquoise). Ours: **Kai = orange + triangle**, **Miko = teal + circle**, on outfits, UI, ping markers and tool effects.

**What that means in Roblox**
- `Lighting.Technology = Future` (real-time point/spot shadows), `Atmosphere` for depth haze, `Bloom` with a high threshold so only Neon glows, `ColorCorrection` saturation +0.1 to +0.25 for a toy-like look.
- Bevelled, oversized, simple shapes; SmoothPlastic + a few materials; one accent color per interactable type (see design.md §5).

## Movement feel

- The base moveset (double jump + air dash) stays the same all game; it's the one constant.
- Forgiving: characters get **pulled onto a ledge** when they barely miss it. We add coyote time, jump buffer and a small ledge assist.
- Momentum matters: crouch-then-jump gives a long jump that keeps speed. We add a **long jump** (crouch + jump while moving).
- It Takes Two runs at about 8 m/s (Split Fiction 5 m/s). Roblox's 16 studs/s is about 4.5 m/s, so sprint (24) is where the speed feel lives.
- Characters animate "like dolls", exaggerated and theatrical, not realistic.

## Co-op design

- Co-op from day one. Test: **remove one player mid-activity; something must break.**
- Asymmetric mechanics are easy to invent; making them **equally fun** is the hard part (the sap/match fix: aim enemies at the less busy player).
- People are bad at communicating and will run ahead without noticing → forced sync points, no backtracking.
- With two cameras you **can't fake anything** (no teleport-behind-a-cut tricks). Our Partner Peek has the same rule: whatever a partner can see must hold up.
- Split Fiction's final level: encourage **screen peeking**; puzzle formula = split the information, split the execution, finish with timing.

## Camera

- ITT keeps both players in view with constrained, shared-logic cameras; no sudden pans or zooms. Ours: a follow camera slightly higher and wider than default, smoothed; top-down midpoint camera in the castle.

## Move animations (Oct 11, 2026)

- No public breakdown of It Takes Two's move animations; notes from gameplay footage (speedrun movement guide) + the game itself: jumps fling the arms wide into a star shape, the double jump is a quick tucked front flip, the slide/crouch sits very low, the long jump reads as a forward dive, the ground pound curls into a spin, then drops stretched straight down and squashes on impact. Doll-like and exaggerated, readable from behind at camera distance.
- Roblox: client-side `Motor6D.Transform` poses don't replicate (DevForum), but an `AnimationTrack` played on your own character's Animator does. So the clips are real animations: keyframe data in `Config/MoveAnims.luau`, played by `MoveAnimController`; in Studio from temporary `KeyframeSequenceProvider` ids, live from uploaded ids (`tools/anim/upload.py`, Open Cloud Assets API accepts Animation as `.rbxm`).
- Sources: [It Takes Two Speedrunning Movement Guide (YouTube)](https://www.youtube.com/watch?v=is6b8gf-afQ), [DevForum: Motor6D replication](https://devforum.roblox.com/t/replicate-motor6ds/3685283), [DevForum: animations replicate from the client](https://devforum.roblox.com/t/fe-player-animations/282776/16), [Open Cloud assets usage guide](https://create.roblox.com/docs/en-us/cloud/guides/usage-assets).

## Sources

- [Hazelight It Takes Two Art Blast — ArtStation Magazine](https://magazine.artstation.com/2021/04/hazelight-studios-it-takes-two-art-blast/)
- [Hazelight working culture and co-op challenges — 80.lv](https://80.lv/articles/hazelight-studios-working-culture-and-approach-to-creating-collaborative-gameplay)
- [Making of Split Fiction: character design and animation — 80.lv](https://80.lv/articles/the-making-of-split-fiction-behind-the-scenes-of-character-design-animation)
- [Facial animation on It Takes Two — Faceware](https://facewaretech.com/blog/interview-hazelight-studios-talks-facial-animation-on-it-takes-two/)
- [It Takes Two review — Game Informer](https://gameinformer.com/review/it-takes-two/it-takes-two-review-the-joys-and-heartbreak-of-love) and [Medium game analysis](https://medium.com/@sm9046/game-analysis-it-takes-two-eca7f3d7ecfc): ledge pull-in, long jump
- [Designing the Final Level of Split Fiction — GDC 2026](https://schedule.gdconf.com/session/designing-the-final-level-of-split-fiction/917468) and [Game Developer](https://www.gamedeveloper.com/design/split-fiction-s-final-level-concept-was-originally-meant-for-the-whole-game)
- [It Takes Two split-screen camera notes](https://ftp.prolabs.com/it-takes-two-local-co-op-gameplay-on-one-screen-splitscreen-magic-for-two-players)
- [Rose's Room walkthrough — Neoseeker](https://www.neoseeker.com/it-takes-two/walkthrough/Rose's_Room_(Part_2))
- [Enhance outdoor environments with lighting — Roblox Creator Hub](https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-outdoor-environments)
