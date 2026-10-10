# Glitched Together (Roblox, Luau, Rojo)

- Docs: `design.md` (why), `mechanics.md` (numbers), `implementation.md` (how), `art-direction.md` (**the art spec**: reserved owner colors, palette, shapes, Blender guide), `Glitched Together — Story Line.md`, `research.md` (It Takes Two art/feel research), `obstacles.md` (It Takes Two obstacle patterns → our obstacle catalog + engine pieces).
- **Any 3D / Blender / art task: read `BLENDER_PLAYBOOK.md` first** (tools, reference search, art rules, Roblox limits, Blender → Studio pipeline, asset backlog).
- Blender files (.blend sources, .fbx exports) live in `blender_assets/`; design briefs in `blender_assets/briefs/`.
- Every tuning number lives in `src/shared/Config/Tuning.luau`; don't hardcode numbers elsewhere.
- Code layout and run steps: `README.md`.
- **All tools we have** (Studio MCP, Blender, asset sources, browser, CLIs) + gotchas: `TOOLS.md`.
- **Knowledge graph (read first in every new session / context window):** `graphify-out/GRAPH_REPORT.md` (god nodes, communities, surprising links across code + docs). For "where is X / what touches Y" questions run `graphify query "<question>"` (or `graphify path "A" "B"`, `graphify explain "X"`) before grepping. Obsidian vault: `graphify-out/obsidian/`. The folder is gitignored and local: if it's missing run `/graphify . --obsidian`; after big code changes run `/graphify . --update`.

## Subagent rules (Oct 3, 2026, after the 14th session; user: "so they don't hinder you and the tokens")

- **Use them for:** playtests, measurements, screenshot checks (`studio-operator`); broad "find everything about X" research across many files/docs (`code-scout`). They keep screenshots and long reads out of the main context.
- **Don't use them for:** single greps, small edits, reading one file, Blender modelling, the final art look before showing the user (do those in main: a cold agent costs ~70–130k tokens to re-learn the project).
- **One operator per session:** spawn once, then `SendMessage` the same agent id for every later Studio check (a resumed agent keeps its context; much cheaper than a new spawn).
- **Retire it when it gets heavy** (user, Oct 4): once a resumed operator passes ~150–200k tokens per run (its whole history is re-read on every resume) or starts making mistakes, spawn a fresh one with a compact brief of what the old one learned (bgshot `-Title "Roblox Studio"`, world parts live under `World.<Section>` with section offsets, PP boss = checkpoint 28, emulate freezes with the `Frozen` attribute and pounds via the GroundPound remote from the client).
- **Tight briefs:** exact parts/coords/checkpoints, what to measure, expected values, report format (problems first, numbers, ≤40 lines). Batch several checks into one brief.
- **Known pitfalls to brief against:** stale code (check `curl localhost:34872/api/rojo` + that a new name exists in Edit before testing), leftover state between tests (respawn/reset the character between runs), its own broken scripts (keep scripts small, verify outputs), emulations aren't real input (say so; ask the user for a feel test).
- Agent types load only after a Claude Code restart; before that, spawn `general-purpose` with "read .claude/agents/<name>.md and follow it".

## Relaunch checklist (after a restart)

1. Rojo: `rojo serve adventure.project.json` (port 34872) and `rojo serve lobby.project.json` (port 34873), each as a background task. Check with `curl localhost:34872/api/rojo`.
2. Studio: newest `%LOCALAPPDATA%\Roblox\Versions\*\RobloxStudioBeta.exe -task EditFile -localPlaceFile "<repo>\build\Adventure.rbxl"`. Studio MCP server = `Roblox_Studio` (`list_roblox_studios` for the id). Rojo plugin connects to 34872.
3. Blender: `cmd //c start "" "D:\Blender\blender.exe" --python "C:\Users\User\tools\blender-mcp\autostart.py"` starts Blender with the MCP server on 9876 (no user click needed).
4. Browser: the user's browser is **Brave**. In this VS Code panel, browser tools (`mcp__claude-in-chrome__*`) only load when the user's message contains **`@browser`**.

## Still-true rules and gotchas (pulled out of the session logs)

- **Git:** remote https://github.com/ohimeee/glitched_together (private), branch `main`. Commit/push only when the user asks. `.gitattributes` forces LF endings (StyLua expects LF).
- **Art rules:** nothing may float (memory grounded-props); every obstacle belongs to the environment (memory obstacles-belong); when re-skinning, keep tested obstacle gameplay/layouts untouched and only dress around them. Owner colors are reserved (teal = Miko, magenta = Glitch; `Palette.luau`, art-direction §6/§16): never decoration. Look: "realistic but kinda It Takes Two" (real materials at doll scale).
- **Studio debug (Studio only, server side):** `workspace:SetAttribute("DebugWorld", "PixelPlains")` jumps worlds; set `DebugCheckpoint` n first to start at checkpoint n; `DebugBossPhase` for the boss. Code reaches Studio by Rojo live sync: stop + start Play to run new server code.
- **Studio tooling:** `generate_mesh` only in Edit, never during Play. Screenshots without focus: `tools/screen/bgshot.ps1`; clicks need the user's OK (`tools/screen/ping.ps1`, memory mouse-ping); click scripts must be DPI-aware (Windows 125%). Scripted playtests can't press ProximityPrompts; emulated results must be labelled "emulated".
- **Sources:** only commercial-safe licenses (CC0 first, CC-BY with credit), never ripped game audio/assets; full list in `TOOLS.md` (§3b sound). Blend Swap: commercial use needs the Artist plan, check before shipping. Tripo free keys are out of credit.
- **Reach table** (studs, flat): jump ~9 walk / ~13 sprint; +double ~15 / ~22; +double+air dash ~34 / ~41; long jump ~18, +double ~24, +double+dash ~51. Height: jump 7.6, +double 13.5, +ledge assist ~16. Design gaps: plain jump ≤ 10, double 12–18, dash 24–27, tool/partner ≥ 55 or ≥ 18 up.
- **Before publishing:** fill place ids in `src/shared/Config/Places.luau`.

## Current status (17th session, Oct 10, 2026)

- **Built:** Lobby (doll-sized bedroom, capsules), Prologue (stage set), World 1 Pixel Plains (28 checkpoints incl. Glitch Chase + **Crusher King boss**, voxel art pass), World 2 Starfall Castle (combat M3, set pieces incl. Siege Cart + Ember Fuse), World 3 Glitched Core (12 checkpoints incl. Memory Lane). Art passes, Blender-rendered skyboxes, UI themes and a sound first pass for every world. Overall ~55–60% (missing: Hollow Dragon + final boss, final level/Epilogue, ending cutscenes, 2P testing, publishing).
- **16th session (all pushed):** dropper blocks fall slow-then-fast and freeze in place; save disks animate; Prologue fan/gear streaming bugs fixed; options slider art; swing points read as grabbable + "[F] SWING" prompt; boss checkpoint inside the arena + 2.5 s spawn immunity; boss music persists through respawns.
- **17th session:** Crusher King throne hall built (voxel ruin kit `tools/boss_arena/kit.py`, `bossHall` in ArtService/PixelPlains; brief `blender_assets/briefs/BossArena.md`); checked in solo Play by screenshot, fight untouched.
- **Most of it is only solo/emulated-tested.** Nothing since the 6th session has been played with 2 players.

## Next steps (in order)

1. **User feel tests:** walk the new throne hall (gate, banners, sun shafts gold after the win), boss phase-2 crossing (tune `ThrowTime`/`ThrowArc` or lap height), pounding a resting fist, phase-3 swing, droppers' new speed + Coin Bonk steps (`CoinFallSpeed` 9), chase rails (speed 40, hops), reveal pans, swing.
2. **2-player run with the user** (everything since the 6th session).
3. **Hollow Dragon** (castle boss, same BossService pattern), then the final boss.
4. Smaller open items: obstacles.md leftovers (Scroll Lock, Balance Scale, Shelf Shove, Echo Lure); a decor cloud crosses the WindmillHill reveal shot; corridor grass tint; Layer Shift cloak ghost question for the user; sound volumes by ear with the user.
5. User's calls: Kai/Miko outfits; monetization plan (no pay-to-win; check DevEx rules first).

## History (moved Oct 8, 2026)

- **The full session logs (1st–16th session) now live in `HISTORY.md`**, newest first. They were moved out of this file to save tokens: CLAUDE.md loads into every session and every subagent. Nothing was deleted.
- Read or grep `HISTORY.md` only when you need a past detail (why something was built a certain way, an old user quote, old test results).
- **Rule: CLAUDE.md holds only what is true now and what is still to do.** As soon as a feature, fix or next-step item is done (or a note is only about the past), take it out of this file and record it in `HISTORY.md` (top of the file, under a dated heading for the current session: what was done, where in the code, how it was verified). Don't wait for the end of the session.
- A finished item leaves "Next steps"; "Current status" gets at most a one-line summary of it. If the work created a rule that stays true (a gotcha, a convention, a number to respect), add that rule to "Still-true rules and gotchas" and keep the story in HISTORY.md.
- **At the end of each session:** re-check that "Current status" and "Next steps" are current. Keep this file short (~4k tokens): no session diaries, done lists or old plans here.
