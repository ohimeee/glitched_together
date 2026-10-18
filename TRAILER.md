# Trailer plan: Glitched Together

Status (Oct 18, 2026, 38th session): environment footage for Pixel Plains, Glitched Core, Starfall Castle, Epilogue
and all three boss intros recorded. Not done yet: lobby shots, gameplay clips (user plays), the edit, music.

Goal (user): a trailer so many players notice the game and come to playtest. Post it on TikTok / YouTube Shorts
(9:16) and YouTube / the Roblox experience page (16:9).

## 1. Where the idea came from (user's references)

- **TikTok the user sent (Oct 18):** https://vt.tiktok.com/ZSg6EkBXd/ (@storyboard.co.th, "2D animation on real footage
  using Claude + After Effects"). Split screen: plain travel footage underneath, the same shot with hand-drawn 2D
  characters and doodles on top. Their pipeline: Claude (prompts), Magnific/GPT (images), Seedance (AI video), Suno
  (music), Illustrator (vectors), After Effects + CapCut (edit).
  - **User's decision:** no doodles for now ("no need for doodle later"). Record the scenes, the environments and a bit
    of gameplay. Doodle overlays (Kai/Miko's childhood drawings over real gameplay) stay an idea for later.
  - **Editor:** the user wants the open-source **EffectCraft** instead of After Effects (installed, see §5).
- **Roblox dev tips the user shared (TikTok @bennettbenito, "ROBLOX TIPS #3", screenshots Oct 18)**, saved in memory
  `retention-tips`:
  1. The game must be understandable without reading: arrows, colors, icons show where to go / what to do.
  2. The first 30 seconds matter most; 90% of players leave within 5 minutes.
  3. Thumbnails (and trailers) must match the real gameplay: high CTR from a misleading image hurts the game; QPTR
     (qualified play-through rate) matters most.
  - Rule from tip 3: **the trailer is real in-game footage only** (no AI-generated gameplay, no fake scenes).

## 2. Research: what popular Roblox trailers do (watched Oct 18)

| Trailer | YouTube | Notes |
| --- | --- | --- |
| DOORS Extended Trailer (5.5M views) | https://youtu.be/p7NKqVJzH4E | slow dark push-ins down corridors, door "0013" hook, logo + date end card |
| DOORS Hotel+ Update (4.3M) | https://youtu.be/IlVShjKur0I | one-word cards between shots ("THE… HAVE… CHANGED"), long holds |
| RIVALS Ranked Official (4.8M) | https://youtu.be/RZqg9_snViY | low hero angles on the character, one mechanic per shot (scope, sword, dodge), logo + PLAY NOW |
| Pressure Trailer | https://youtu.be/VvM0-IcOxlY | dark mood, quick monster glimpses |
| Grow a Garden Spotlight (Roblox official) | https://youtu.be/ER5c9YOyCoA | logo in frame 1, ~1.9 s shots, comedy faces, top-down time-lapse |

What they all share:
1. ~30 s long; the last 3–5 s are an end card (logo + PLAY NOW / date).
2. 100% real in-game footage shot with a free cinematic camera, HUD/UI hidden.
3. Shots of 2–4 s (Grow a Garden ~1.9 s, DOORS ~4–5 s for mood), cut on the music beats.
4. One idea per shot: one mechanic, one place, or one character reaction.
5. Character close-ups with emotion sell it.
6. Almost no text (DOORS: 3 one-word cards).
7. A hook in the first 1.5 s.

## 3. Our 30 s trailer (plan)

| Time | Shot |
| --- | --- |
| 0–2 s | HOOK: Kai + Miko side by side, low angle (hero shot by the trial signs), glitch tear behind them |
| 2–6 s | card **TWO PLAYERS** → Pixel Plains flyover / islands → a co-op moment (grapple + freeze beam on a crusher) |
| 6–11 s | card **TWO POWERS** → castle wide (gatehouse at night) → shield reflects a fireball into a skeleton |
| 11–16 s | Glitched Core flythrough (overview, echo islands) → copy/paste platform bridge |
| 16–24 s | card **ONE UNFINISHED GAME** → bosses: Crusher King on the throne / slam, Hollow Dragon in the Shattered Cathedral, The Unfinished rising |
| 24–30 s | Title logo + **PLAY WITH A FRIEND** + Roblox |

- Formats: 16:9 (1920×1080, upscaled from the 1584–1890 px wide captures) and 9:16 (crop; frame the action center).
- Crop out Roblox's top-left menu buttons in the edit (scripts can't hide them).
- Music: must be cleared for YouTube/TikTok (the Roblox audio library only covers use inside Roblox): Pixabay Music,
  YouTube Audio Library, or Suno paid plan. No added roar/sting SFX on boss shots (user rejected them in-game too).
- Card text style: the game's title logo font (Luckiest Guy, `~/tools/fonts`), owner colors only where they mean
  Kai (orange) / Miko (teal) / Glitch (magenta).

## 4. Footage recorded so far (`C:\Users\User\Videos\GlitchedTrailer`)

| File | Content | Use |
| --- | --- | --- |
| 2026-10-18 23-50-07.mp4 | **Retake at max graphics (Level21), no cursor:** hook duo push-in (move 12.6–18.5 s, spawn flag hidden), PP flyover (25.8–33.5), grind rails up to the King (40.5–47.5), coin press blob lane (54.5–60.5) | keep: replaces the 3 cursor takes below in the cut |
| 2026-10-18 19-27-30.mp4 | Pixel Plains drone flyover over the floating islands | keep |
| 2026-10-18 19-28-29.mp4 | PP batch: duo hero shot (0–7 s), crusher (blocked), windmill bridges, fan, cloud tower, cannon, coin press wall (blocked), grind rails (~50 s), Crusher King on throne with light rays (~58 s) | keep duo, islands, rails, king |
| 2026-10-18 19-31-00.mp4 | PP batch 2: crusher, coin press lane with blob enemies (~8 s), windmill bridges, fan underside (bad), springs (meh), pipes (blocked) | keep press lane, bridges |
| 2026-10-18 19-42-35.mp4 | Glitched Core: overview flight, MissingTextures, PastePast, WireMaze, TitleEcho, PlainsEcho, CastleEcho, FinalStage | keep overview + echoes |
| 2026-10-18 19-53-29.mp4 | Starfall Castle (all textures): gatehouse under the moon, hall, library, cart ride, powder hall, throne hall, Hollow Dragon close | keep (orange aim marker dot visible bottom right in some frames) |
| 2026-10-18 19-59-19.mp4 | Hollow Dragon intro (drone flight into the Shattered Cathedral, dragon alive) | keep ~8–26 s |
| 2026-10-18 20-06-01.mp4 | Crusher King intro (retake: fly-up past the ruins to his face, light rays) | keep ~2–20 s |
| 2026-10-18 20-01-12.mp4 | The Unfinished intro, take 1 | keep (alt) |
| 2026-10-18 20-02-12.mp4 | The Unfinished intro, take 2 (golem moves more; 0–20 s = fight running, skip) | keep ~21–40 s |
| 2026-10-18 20-53-24.mp4 | **Gameplay (user):** Glitch Chase run on the rails with the wall (27–46 s, wall in shot 38 / 45 s), Crusher King fight start, fist slams (48–58 s); 0–22 s = caught by the wall | keep |
| 2026-10-18 20-54-50.mp4 | **Gameplay:** castle room fight as Kai, camera far + dark (fire bursts 14–16, 34–38 s) | spare |
| 2026-10-18 20-56-09.mp4 | **Gameplay:** castle room 2 fight, `TopDownZoom` 0.55 (held ~17 s only), fireballs 23–25 s, flame wall 32–35 s | keep |
| 2026-10-18 21-00-10.mp4 | **Gameplay:** Kai copy/pastes PlankBlock bridges between magenta glitch walls (MissingTextures, 5–15 s) | keep |
| 2026-10-18 20-03-52.mp4 | Epilogue: lantern path push-in, crane over the hilltop, trophy orbit, supporter wall push-in (last high wide = too dark) | keep first 4 shots |

Still to record:
- The lobby bedroom (capsules, train, bed): lobby place (Rojo 34873).
- Gameplay recorded Oct 18 (chase, King fist, castle fight, paste bridge). Still wanted: Miko's moves (grapple swing,
  shield reflect), a 2-player duo moment (puppet/ghost), lobby bedroom.
- A real-looking puppet: `/puppet miko <userId>` with an alt/friend avatar (ask the user; without an id it's a plain
  body with skin + teal shirt).

## 5. Tools and how to record

**In the game (admin chat, published Adventure place, Rojo 34872 connected):** see command.md "Trailer recording".
- `/trailer` = trailer mode (no UI, no cursor). End leaves, U shows the UI for a moment.
- V fly camera (WASD, E/Q, Shift, scroll speed, right mouse look, Z/X lens); 1–9 path slot, K add point, J drop,
  Delete clear, P play/stop (camera holds the last frame), `[` `]` path time, O print points, H hide own character,
  G ghost take. `/puppet kai|miko [userId]`, `/puppet clip <name>`, `/ghost rec|play|loop|stop`.
- Code: client `src/adventure/client/Controllers/TrailerController.luau`, server `Services/Trailer.luau`,
  numbers `Tuning.Trailer`.
- **Scripted shots (what I used):** from execute_luau on the Server: build keys `{ cf = CFrame.lookAt(pos, look),
  fov = n }`, `player:RequestStreamAroundAsync` each point first (StreamingEnabled), then
  `ReplicatedStorage.Net.Trailer:FireClient(player, "Path", { slot, keys, time, play = true })`. Batch: hold the
  first key 1 s, then fly, `task.wait(time + 0.3)`. Section bounds: `workspace.World[Section]:GetBoundingBox()`
  (PP / Core); castle rooms are parts named Gatehouse, Hall, LibraryHall, TorchHall, CartDock, PowderHall,
  ThroneHall, HollowDragon (z 0 → 1650). Chat commands typed with the MCP keyboard tool need a short pause
  before Return.

**OBS (recording):** OBS 32 at `C:\Program Files\obs-studio`, runs in the tray, obs-websocket on 4455 (password in
`%APPDATA%\obs-studio\plugin_config\obs-websocket\config.json`).
- `python tools/trailer/obsctl.py setup | shot out.png | crop L T R B | start | stop` (pip `obsws-python`).
- Profile **Trailer** (x264; NVENC fails to start on this laptop), scene **Trailer** = window capture of
  "Adventure - Roblox Studio" (class Qt5159QWindowIcon), 60 fps, mp4.
- After every Studio restart re-measure the viewport: `shot`, find the blue viewport border, `crop L T R B`
  (Explorer closed + ribbon collapsed: 3 85 26 72 → 1890×864; Explorer open: 4 93 332 64 → 1584×864).
- Check takes: `ffmpeg -vf fps=1/2,scale=320:-1` → contact sheet.

**EffectCraft 0.11.1 (the editor, user-installed):** `"C:\Program Files\EffectCraft\effectcraft-cli.exe"`.
- `script file.jsx --empty` runs After Effects-style JSX (app.project, addComp, layers, addText, addSolid,
  property().setValueAtTime, `app.project.save(new File("x.ecproj"))`); `render --project x.ecproj --comp C --out
  x.mp4 --format h264`; `render-frame ... --out f.png` to check frames; `mcp` = MCP server.
- Tested Oct 18: a 3 s 1080p title comp rendered in 2.3 s. Alpha software (crash risk); fallback editor: DaVinci
  Resolve (free, user installs).
- **The edit (38th, draft built):** `tools/trailer/edit.jsx` (shot list = `SHOTS` [take, source s, length, card]) +
  `tools/trailer/cards.py` (Luckiest Guy cards, navy extrusion + white sticker outline like the logo). Build:
  `python tools/trailer/cards.py`, `effectcraft-cli script tools/trailer/edit.jsx --empty` → `edit/trailer.ecproj`,
  then `render --project edit/trailer.ecproj --comp Trailer16x9|Trailer9x16 --out x.mp4 --format h264`. 31 s: hook
  duo → TWO PLAYERS (PP flyover, islands, blob lane, rails) → THREE WORLDS (castle, Core) → ONE UNFINISHED GAME
  (King, Dragon, The Unfinished, trophies) → logo + PLAY WITH A FRIEND + ON ROBLOX. 9:16 = the 16:9 cut as a band
  over a blown-up dark copy. Each shot pushes in 5 %; framing auto-zooms past the Roblox buttons.
- **Music + voice (38th):** first cut on "Time Flies_32Sec" (tape-echo) with the Kokoro voice (`am_michael`, user's pick
  from processed samples; raw Kokoro sounded "lousy, no impact" → `voice.py` FX chain). Then 4 music variants
  (`tools/trailer/variants.py`: beat grid + drop from the audio, same shots, end-line voice only).
  **User picked the chiptune version** ("Pixel Art Game Soundtrack Chiptune", echoes_of_lumen; song window from
  ~50.3 s, drop at 59.4 s, 112 BPM, 2.14 s shots, 34.4 s): `edit/trailer_chiptune.mp4` + `trailer_chiptune_9x16.mp4`.
  Still open: where the voice goes (end only now; intro lines were questioned by the user), gameplay clips.
- (superseded) Draft was silent before the music pass. Swap gameplay clips into `SHOTS` once recorded (TWO POWERS card then).
- Some takes have black bars inside the video (OBS crop off): `CONTENT` in edit.jsx lists their real picture size.

## 6. Gotchas met while recording (Oct 18)

- **Assets not loading:** the experience moved into the Night Owl Interactive group; images uploaded under
  buldak0555 failed. Fixed with `python tools/assets/grant_permissions.py` (747 granted). Studio caches a failed
  fetch for the whole process: restart Studio after granting before you judge.
- Stale `Lobby` / `LobbyClient` scripts + 11 `Lobby*` materials are in the published Adventure place until it is
  republished: remove them in Studio every time it opens (they build the lobby inside the adventure).
- The castle's orange aim ground marker hides in trailer mode (38th: client-only player attribute `TrailerMode`, read by `TopDownAim`).
- **Recording a boss intro:** jump with `DebugCheckpoint` + `DebugWorld`, anchor the HumanoidRootPart + god mode
  (MaxHealth = Health = math.huge: the running boss fight / magenta pads kill an idle character, and a death
  respawns it mid-take), re-arm the trigger (`BossIntroTrigger:SetAttribute("Once", false)`, `Played` nil; a world
  rebuild resets Once), then pivot into it and wait while the player's `InCutscene` is true (~20 s).
- **A played trailer path holds its last frame over everything, cutscene cameras too:** toggle trailer mode off/on
  (Trailer remote "Toggle" twice) before recording a cutscene after scripted shots.
- **Far scenery missing (sky islands, distant sections) = Graphics Quality "Automatic" cutting draw distance**, not
  streaming (Oct 18: every island was on the client, only the old take showed them). Before recording, on the Client:
  `settings().Rendering.QualityLevel = Enum.QualityLevel.Level21`, then compare a preview frame with an old take.
- **Mouse cursor in takes:** the 3 early 1888-wide takes (19-27-30, 19-28-29, 19-31-00) caught the resting Windows arrow at
  ~(935, 352). `python tools/trailer/decursor.py` paints it out (ffmpeg delogo) into `GlitchedTrailer/clean/`; edit.jsx
  reads those via `CLEAN`. For new takes: turn off "Capture Cursor" on the OBS window source, or park the mouse off the
  Studio window before `start`.
- OBS profile switches reset the capture transform (scale 0.8): run `crop` again after any profile change.
- **Gameplay recording with the user (38th):** trailer mode on (HUD hidden), god mode (`MaxHealth = Health = math.huge`),
  jump with `DebugRole` + `DebugCheckpoint` + `DebugWorld`, then OBS start; the user plays and says "next".
  PastePast can't be done solo (Miko must pull the crate out of the Code Layer first): Kai's solo copy source is the
  PlankBlock in MissingTextures (stand on KaiLedge). `TopDownZoom` 0.55 brings the castle camera closer but rooms
  override it after a while. OBS StartRecord right after a stop returns 500: retry after ~1.5 s.

## 8. Posting + closed beta (Oct 19, 2026)

Flow: viewers see the trailer → join the community + apply as a pair on the form → the owner checks they joined, gives both the **Beta Tester** role (rank 10) → the game lets them in (`Config/Beta`, `Util/BetaGate`; everyone else is kicked with the beta note).

- Community: https://www.roblox.com/communities/129463626
- YouTube: https://www.youtube.com/@NightOwlInteractiveStudio (studio account nightowlinteractive.studio@gmail.com; banner + profile in `marketing/social/`)
- Form ("Night Owl Interactive: Playtesters Wanted", owned by hi.me1052006@gmail.com): https://forms.gle/VvvVmpakSBST1FqZ7

**Description:**
> **Glitched Together** 👾 a 2-player co-op story adventure on Roblox.
> Two best friends made a game as kids and never finished it. Now it has pulled them inside.
>
> 🧪 **CLOSED BETA, playtesters wanted!**
> 1️⃣ Join our community: https://www.roblox.com/communities/129463626
> 2️⃣ Apply (with a friend, or we'll pair you): https://forms.gle/VvvVmpakSBST1FqZ7
> Picked testers get the Beta Tester role and a message on Roblox, then you can play!
>
> Made by Night Owl Interactive 🦉

**Pinned comment:** Want to play before everyone else? 🧪 Join the community → https://www.roblox.com/communities/129463626 then apply → https://forms.gle/VvvVmpakSBST1FqZ7 Bring a friend, it's 2-player!

**TikTok caption** (links in bio): 2-player co-op adventure on Roblox 👾 closed beta open! Link in bio to apply 🧪 #roblox #robloxdev #coop #indiegame
