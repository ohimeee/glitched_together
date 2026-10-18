# Launch plan: Glitched Together

Status: **PLAN** (decided Oct 12, 2026, 26th session). Nothing here is built yet unless it says so.

## 1. Experience page

| Field | Plan |
| --- | --- |
| Title | `[2 PLAYER] Glitched Together 👾` (user pick) |
| Genre | Adventure (sub: story / platformer). Check Roblox's current genre list when publishing |
| Max players per server | 2 (the duo); the lobby place can hold more |
| Devices | PC + mobile + console (user pick, see §3) |
| Private servers | Off at launch (decide with the monetization plan) |

**Description (draft):**

> Two best friends made a video game as kids... and never finished it. Now it has pulled them inside.
>
> 👾 A 2-player co-op story adventure. Bring a friend!
> 🧩 Every world gives you two different powers. Neither of you can finish alone.
> 🌍 3 worlds: Pixel Plains, Starfall Castle and the Glitched Core, plus a prologue and an epilogue.
> 🐉 Boss fights against the Crusher King, the Hollow Dragon and The Unfinished.
> 💾 Your progress saves at every checkpoint, for each partner you play with.
>
> Inspired by co-op story games. Made by two people who still finish what they start.

**Icon (512 × 512):** Kai (orange) and Miko (teal) back to back, split down the middle by a magenta glitch tear, the 👾 Glitch peeking through. Made in Blender from the game's own models (same pipeline as the loading paintings), bold silhouette that reads at small size, no small text.

**Thumbnails (1920 × 1080, up to 10):** first = the user's cover art (`marketing/glitched_together_thumbnail.png`, made by `tools/make_thumbnail.py`; done Oct 17). Then reuse the Blender loading paintings (one per world), plus 2–3 boss shots (Crusher King throne hall, Hollow Dragon in the Shattered Cathedral, The Unfinished). Each gets the title logo and a one-line hook ("2 PLAYERS. 2 POWERS. 1 UNFINISHED GAME."). Order: the co-op hook first, then worlds, then bosses.

**Title logo:** "GLITCHED TOGETHER" wordmark with a glitch split, needed for the thumbnails, the loading screens and the trailer.

## 1b. Opening splash (user, Oct 12: "launching the game animation, same as the rdr2... my company")

Plays in the **lobby place** on the first join of a session; any key / click / tap skips; ~5–6 s total.
1. **Studio logo (~2.5 s):** the studio name builds itself from small pixels on black, holds, then a quick magenta glitch flicker (ties the studio to the game's theme). Soft sound, no harsh sting (user rejected stings).
2. **Title (~3 s):** the GLITCHED TOGETHER wordmark splits open along a glitch tear (Kai orange one side, Miko teal the other), then fades into the lobby.
- Studio name: **Night Owl Interactive** (Roblox community 129463626, created Oct 18) (user, Oct 18; "Night Owl Studios" and close spellings were taken on Roblox; community creation costs Robux). Emblem + cover + splash lockup: `marketing/studio/` (Blender `blender_assets/StudioLogo.blend` concept 2 "the moon is the owl" → `tools/paint_style/studio_logo.py`).
- Between worlds the painted loading cards are used instead (CLAUDE.md plan).

## 2. Maturity & compliance questionnaire (draft answers, check in Creator Hub)

- Violence: fantasy / cartoon only (sword, fireballs, shield bash against skeletons, slimes and bosses), no blood, no gore, no realistic weapons. Characters "go down" and respawn by button mashing.
- Fear: mild (glitch static, a dragon, a giant golem); no jump scares.
- Romance, crude humor, alcohol, drugs, gambling: none.
- Paid random items (loot boxes): none.
- Social: Roblox text chat; voice chat off unless we decide otherwise.
- Purchases: developer products for optional tips only, nothing gameplay-related (no pay-to-win).
- Expected label: **Mild** (fantasy violence). Confirm when filling it in.

## 3. Devices (user pick: PC + mobile + console)

**Built Oct 17 (30th session, HISTORY.md):** touch rings (`TouchController`), per-device key names (`Util/Glyphs`), UI scaling (`Util/UiFit`), castle auto-aim, gamepad menu selection, low-end particles (`PerfController`). Checked in Studio with `DebugDevice` only: still to test on a real phone, tablet and console. The lists below were the plan.

**Mobile pass (to plan in detail):**
- On-screen buttons: jump, dash, ground pound, swing/grapple, Tool1/Tool2, ignite/rotate where a world uses them, mash-to-respawn.
- Castle top-down aiming by touch (`TopDownAim`): drag-to-aim or auto-aim at the nearest target.
- Key prompts (`KeyPromptController`) show touch icons instead of keys; ProximityPrompts are tappable.
- UI scale check on a small phone (HUD, dialogue, credits, support panel).
- Performance check on a low-end phone (mesh/texture counts, particle counts).

**Console pass:**
- Key prompts show gamepad buttons (B dash, R3 pound, R1 swing, R2/L2 tools, X ignite, Y rotate).
- Every menu and panel reachable with the gamepad (credits YES, support panel, level-up picker).
- 10-foot UI: text sizes readable on a TV.

## 4. Badges (user pick: worlds + bosses, 8)

| Badge | Awarded when | Code hook |
| --- | --- | --- |
| The Title Screen (Prologue) | leaving the Prologue | `WorldService.Advance` (world complete) |
| Pixel Plains | leaving Pixel Plains | `WorldService.Advance` |
| Starfall Castle | leaving Starfall Castle | `WorldService.Advance` |
| The Glitched Core | leaving the Glitched Core | `WorldService.Advance` |
| Glitched Together (game finished) | CONTINUE? YES at the end of the credits | `ContinueYes` handler (Main) |
| Crusher King | Crusher King beaten | `BossService.Finished("CrusherKing")` |
| Hollow Dragon | Hollow Dragon beaten | `BossService.Finished("HollowDragon")` |
| The Unfinished | The Unfinished beaten | `BossService.Finished("Unfinished")` |

Both players get every badge (award to `DuoService.Players()`). Badge ids go in a new `src/shared/Config/Badges.luau` (0 = not created yet: skip, like Products/Places). Each badge needs a 512 × 512 icon (Blender renders: world landmark or boss portrait in a round frame). Creating badges: Roblox allows a few free per day and charges Robux beyond that; check the current rule in Creator Hub before creating all 8.

## 5. Order of work

1. Mobile + console passes (they change how the game plays; test with real devices).
2. Studio logo + title logo (opening splash), then Blender paintings (loading screens, see CLAUDE.md), reused for thumbnails and the icon.
3. Badges code + icons.
4. Publish both places, fill `Places.luau`, `Products.luau`, `Badges.luau`; fill the questionnaire; set the experience page.
5. Live tests: lobby → adventure teleport, saved runs per partner, badges, tip jar purchase, favorite prompt, BACK TO LOBBY.
