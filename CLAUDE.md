# Glitched Together (Roblox, Luau, Rojo)

- Docs: `design.md` (why), `mechanics.md` (numbers), `implementation.md` (how), `art-direction.md` (**the art spec**: reserved owner colors, palette, shapes, Blender guide), `Glitched Together — Story Line.md`, `research.md` (It Takes Two art/feel research), `obstacles.md` (It Takes Two obstacle patterns → our obstacle catalog + engine pieces).
- **Any 3D / Blender / art task: read `BLENDER_PLAYBOOK.md` first** (tools, reference search, art rules, Roblox limits, Blender → Studio pipeline, asset backlog).
- Blender files (.blend sources, .fbx exports) live in `blender_assets/`; design briefs in `blender_assets/briefs/`.
- Every tuning number lives in `src/shared/Config/Tuning.luau`; don't hardcode numbers elsewhere.
- Code layout and run steps: `README.md`.
- **All tools we have** (Studio MCP, Blender, asset sources, browser, CLIs) + gotchas: `TOOLS.md`.
- **Knowledge graph (read first in every new session / context window):** `graphify-out/GRAPH_REPORT.md` (god nodes, communities, surprising links across code + docs). For "where is X / what touches Y" questions run `graphify query "<question>"` (or `graphify path "A" "B"`, `graphify explain "X"`) before grepping. Obsidian vault: `graphify-out/obsidian/`. The folder is gitignored and local: if it's missing run `/graphify . --obsidian`; after big code changes run `/graphify . --update`.

## Subagent rules (Oct 3, 2026, after the 14th session; user: "so they don't hinder you and the tokens")

- **Standing permission (user, Oct 10): spawn them on your own whenever a task fits; don't wait to be asked.** This rule is the user's ask, so the tool's "only when the user asks" default is already satisfied.
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
- **Art rules:** nothing may float (memory grounded-props); every obstacle belongs to the environment (memory obstacles-belong); when re-skinning, keep tested obstacle gameplay/layouts untouched and only dress around them. Owner colors are reserved (teal = Miko, magenta = Glitch; `Palette.luau`, art-direction §6/§16): never decoration. Look: "realistic but kinda It Takes Two" (real materials at doll scale). Hero creatures/bosses: start from a CC0/CC-BY Sketchfab model via Blender MCP (credit in CREDITS.md), not scripted primitives (user rejected the scripted dragon, Oct 10).
- **Studio debug (Studio only, server side):** `workspace:SetAttribute("DebugWorld", "PixelPlains")` jumps worlds; set `DebugCheckpoint` n first to start at checkpoint n; `DebugBossPhase` for the boss. Code reaches Studio by Rojo live sync: stop + start Play to run new server code.
- **Studio tooling:** `generate_mesh` only in Edit, never during Play. Screenshots without focus: `tools/screen/bgshot.ps1`; clicks need the user's OK (`tools/screen/ping.ps1`, memory mouse-ping); click scripts must be DPI-aware (Windows 125%). Scripted playtests can't press ProximityPrompts; emulated results must be labelled "emulated".
- **Sources:** only commercial-safe licenses (CC0 first, CC-BY with credit), never ripped game audio/assets; full list in `TOOLS.md` (§3b sound). Blend Swap: commercial use needs the Artist plan, check before shipping. Tripo free keys are out of credit.
- **Reach table** (studs, flat): jump ~9 walk / ~13 sprint; +double ~15 / ~22; +double+air dash ~34 / ~41; long jump ~18, +double ~24, +double+dash ~51. Height: jump 7.6, +double 13.5, +ledge assist ~16. Design gaps: plain jump ≤ 10, double 12–18, dash 24–27, tool/partner ≥ 55 or ≥ 18 up.
- **Shot rays:** shots skip parts tagged `ShotPass` (walk-only walls; a colliding part ignores CanQuery=false) and also cast against `BossHurt` parts (they don't collide). Grey-box holders carry a `Skin` attr: never change their Transparency in boss code.
- **Boss camera hooks (castle top-down):** workspace `TopDownZoom` (×), `TopDownFocus` (Vector3) + `TopDownFocusWeight`, `TopDownFlip` (look from the −Z side). Boss hurtboxes: tag `BossHurt` → `CombatService.BossHit(part, damage, owner, "Shot"|"Reflected"|"Area")`. In Studio, `require(CombatService)` from execute_luau is a separate copy (its shots never move): drive tools through the real `ToolUse` remote instead.
- **Before publishing:** fill place ids in `src/shared/Config/Places.luau`.

## Current status (19th session, Oct 10, 2026)

- **Built:** Lobby (doll-sized bedroom, capsules), Prologue (stage set), World 1 Pixel Plains (28 checkpoints incl. Glitch Chase + **Crusher King boss** + throne hall, voxel art pass), World 2 Starfall Castle (combat M3, set pieces incl. Siege Cart + Ember Fuse) + boss **Hollow Dragon** (Sketchfab Celestial Dragon), World 3 Glitched Core (13 checkpoints incl. Memory Lane) + **final boss The Unfinished** (Meteor Golem skins, 4 phases, `server/Bosses/Unfinished.luau`) + **Epilogue** (night walk, Pip goodbye, real-world ending, credits + CONTINUE? YES). Art passes, Blender skyboxes, UI themes, sound first pass everywhere. Overall ~78% (missing: Epilogue background art, 2P testing, publishing).
- **19th session:** final boss playable end to end + Epilogue built (solo/emulated; details in HISTORY.md).
- **Most of it is only solo/emulated-tested.** Nothing since the 6th session has been played with 2 players.

## Next steps (in order)

1. **User feel tests (user: "playtest later"):** The Unfinished (intro pan + all 4 phases: arm slams + climbing a frozen arm, breath + reflect into the core, ring jumps, the build phase with real Layer Shift pull + Copy/Paste onto slots); Hollow Dragon flight + whole fight; Crusher King throne hall + phase-2 crossing (tune `ThrowTime`/`ThrowArc` or lap height), pounding a resting fist, phase-3 swing; droppers + Coin Bonk steps (`CoinFallSpeed` 9); chase rails (speed 40, hops); reveal pans; swing.
2. **2-player run with the user** (everything since the 6th session). Must include the Hollow Dragon's and the Unfinished's reflected shots into the heart/core and the final SAVE double pound (can't be emulated solo).
3. **Final boss leftovers:** two identical `Bosses.Unfinished` ModuleScripts show in Edit (Rojo live-sync duplicate: reconnect the Rojo plugin); `W3_BossIntro` pan (walkway trigger) built but only data-checked, not watched; per-phase stage props (only the floor surface swaps now); `GrappleLine.swinging` isn't cleared on a kit change.
4. **Epilogue background (user, Oct 10: "leave the background for next session like the 4 worlds made from blender"):** a Blender-rendered night panorama skybox (starry sky over the whole finished kingdom) like the other worlds' skies (`tools/blender_sky.py`, BLENDER_PLAYBOOK §10); then replace or rework the far props in `buildEpilogue` (FarPlains/FarCrag/FarCore: grey-box silhouettes, the FarCore blocks float) and darken the Look (horizon reads cobalt, not night). Optional: post-credits Pip in an unfinished zone; the YES button click is untested.
5. Hollow Dragon leftovers: wing tips still clip the top of the screen while it rears for a breath; scale orbs read as embers at its claws.
6. Smaller open items: obstacles.md leftovers (Scroll Lock, Balance Scale, Shelf Shove, Echo Lure); a decor cloud crosses the WindmillHill reveal shot; corridor grass tint; Layer Shift cloak ghost question for the user; sound volumes by ear with the user.
7. User's calls: Kai/Miko outfits; monetization plan (no pay-to-win; check DevEx rules first).

## History (moved Oct 8, 2026)

- **The full session logs (1st–16th session) now live in `HISTORY.md`**, newest first. They were moved out of this file to save tokens: CLAUDE.md loads into every session and every subagent. Nothing was deleted.
- Read or grep `HISTORY.md` only when you need a past detail (why something was built a certain way, an old user quote, old test results).
- **Rule: CLAUDE.md holds only what is true now and what is still to do.** As soon as a feature, fix or next-step item is done (or a note is only about the past), take it out of this file and record it in `HISTORY.md` (top of the file, under a dated heading for the current session: what was done, where in the code, how it was verified). Don't wait for the end of the session.
- A finished item leaves "Next steps"; "Current status" gets at most a one-line summary of it. If the work created a rule that stays true (a gotcha, a convention, a number to respect), add that rule to "Still-true rules and gotchas" and keep the story in HISTORY.md.
- **At the end of each session:** re-check that "Current status" and "Next steps" are current. Keep this file short (~4k tokens): no session diaries, done lists or old plans here.
