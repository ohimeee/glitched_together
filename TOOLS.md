# Tools — Glitched Together

Everything Claude can use on this project, what each is for, and the gotchas learned so far. Read with `CLAUDE.md` (status, relaunch checklist) and `BLENDER_PLAYBOOK.md` (art pipeline). PC: Windows 11, shells = Bash (Git Bash) and PowerShell 5.1.

## 1. Roblox Studio + Rojo

| Tool | Use | Notes |
| --- | --- | --- |
| **Rojo 7.7** (`rojo` on PATH via Rokit) | `rojo build adventure.project.json -o build/Adventure.rbxl`, `rojo serve` (34872 adventure, 34873 lobby) | Studio isn't live-synced (the Rojo plugin needs a user click), so code changes = rebuild + reopen the place |
| **StyLua 2.5** | `stylua src` before every build/commit | `.gitattributes` forces LF |
| **luau-lsp 1.69** | type checking (Roblox defs `~/.rokit/globalTypes.d.luau`) | VS Code extension shows diagnostics |
| **Roblox Studio** | open: newest `%LOCALAPPDATA%\Roblox\Versions\*\RobloxStudioBeta.exe -task EditFile -localPlaceFile "<repo>\build\Adventure.rbxl"` | After `taskkill //F //IM RobloxStudioBeta.exe` + rebuild + start: `sleep 5`, then poll `list_roblox_studios`. If it opens an `_AutoRecovery` file, relaunch once |

### Roblox Studio MCP (`mcp__Roblox_Studio__*`, server `Roblox_Studio`)
Every call needs `studio_id` from `list_roblox_studios`.

| Tool | Use | Gotchas |
| --- | --- | --- |
| `execute_luau` | Run Luau in `Edit`, `Server` or `Client` (during play) | Its `require` makes a separate copy of a module (Init never ran), so call game code through events/attributes, not by requiring services |
| `start_stop_play` | Solo play test | Only 1 player; 2-player test needs the user (Test → Clients and Servers → 2) |
| `screen_capture` | Screenshot | During play, camera params are ignored: on the client, `RunService:BindToRenderStep("ShotCam", Enum.RenderPriority.Last.Value + 10, …)` to set the camera, hide ScreenGuis, and move the character near the target (StreamingEnabled) |
| `get_console_output` | Output log | |
| `generate_mesh` | AI textured mesh (the graphics baseline) | **Only in Edit mode** (fails while playing). 2–3 at a time (`async: true` + `wait_job_finished`). Avoid words like "fangs"/"menacing" (moderation). Result is a Model tagged `Assistant-…`: read its MeshPart `MeshId`/`TextureID`/`Size`, check facing, then delete it |
| `generate_material` | AI MaterialVariant | Results were too heavy for Pixel Plains; we hand-make maps instead (`textures/make_pixelplains.py`) |
| `upload_image` | Upload PNGs, returns `rbxassetid://` (Image type) | Needs **http URLs**: run `python -m http.server 8765 --bind 127.0.0.1` in `textures/` (background) and pass `http://127.0.0.1:8765/<file>.png`. New uploads can take a few seconds to render |
| `search_asset` / `insert_asset` | Creator Store search/insert (models, audio…) | Audio rules and every other sound source: §3b |
| `generate_texture`, `generate_procedural_model`, `inspect_instance`, `search_game_tree`, `script_read/grep/search`, `multi_edit`, `character_navigation`, `user_keyboard_input`, `user_mouse_input`, `segment_mesh`, `store_image`, `http_get`, `subagent`, `skill` | Available, rarely needed | |

**Hot-patch code without a restart:** serve the repo (`python -m http.server 8766 --bind 127.0.0.1`, background), then run `tools/hotpatch.luau` through `execute_luau` (Edit) with its `FILES` list set to the changed paths (`git status --short`). It turns Studio's HttpService on just for the fetch, sets each script's `Source` (creating new ones), and restores the setting. Then Play again.

**Can't do:** Studio UI clicks (File → Import 3D). MCPControl can't bring Studio to the front while VS Code holds focus → ask the user to import FBX files (batch them). Scripts can't set a MaterialVariant's maps at runtime → declare variants in `adventure.project.json` (MaterialService).

## 2. Blender

- **Blender 5.2.2** at `D:\Blender\blender.exe`. Start with the MCP server already running: `cmd //c start "" "D:\Blender\blender.exe" --python "C:\Users\User\tools\blender-mcp\autostart.py"` (port 9876, also enables Poly Haven, loads the Sketchfab key).
- **Blender MCP** (`mcp__blender__*`): `execute_blender_code` (main tool, bpy/bmesh), `get_scene_info`, `get_object_info`, `get_viewport_screenshot`, `bpy_api_lookup`, `describe_node_type`, `export_scene`, `set_texture`, `get_addon_status`, `disable_telemetry` (keep telemetry off). Asset integrations: §3 (Poly Haven and Sketchfab on; Poly Pizza, Hyper3D, Hunyuan and add-on Tripo off). Add-on protocol is behind (11 vs 13) but works; `uvx mcp-for-blender install-addon` would update it.
- Pipeline and scripting rules: `BLENDER_PLAYBOOK.md` §6–7 (stud scale, Blender (x,y,z) → Roblox (−x,z,y), FBX export flags, offsets computed from bbox centers, save a `.blend` copy + `.fbx` in `blender_assets/`).

## 3. 3D / asset sources (props, environments, textures)

**Which one for what:**

| Need | First choice | Then |
| --- | --- | --- |
| Characters, enemies, bosses, held items, organic props (stylized, textured) | Studio `generate_mesh` | Tripo (hero quality, image-to-3D, rigging) |
| Exact-size kit pieces (platforms, walls, doors, signs) | Blender, scripted (BLENDER_PLAYBOOK §6–7) | real surfaces from Roblox materials / Poly Haven textures |
| Environment surfaces (stone, wood, dirt, metal), skies | **Poly Haven** textures/HDRIs | hand-made maps in `textures/` |
| Set dressing / filler props for environments (barrels, bookshelves, rocks, plants, furniture) | **Blend Swap**, **Sketchfab** | Poly Haven models, generate_mesh |
| Anything downloaded | restyle to the world's palette (art-direction §16), decimate to budget (≤20k tris/mesh, props 300–5k), bottom-center origin, export FBX, user imports | |

Environment polish plan (CLAUDE.md note 7): It Takes Two–level detail per world from these sources: dense prop clusters, layered foreground/background, real PBR surfaces, warm light pools. Study It Takes Two for principles only, never copy its assets or layouts.

### Studio `generate_mesh` (Roblox Cube, textured)
See §1. Prompt pattern that matches the graphics baseline: *"stylized Pixar-like chunky <thing>, <world colors/materials>, believable <material> textures, It Takes Two art style"*. Name owner colors in words ("aqua turquoise", "bright orange trim") and check the result: generations sometimes pick the wrong color (a first grapple gun came out green with an orange rope) or shape (a chute came out as a U-pipe). Regenerate, or build it in Blender.

### Tripo (REST API v3, called directly, not through the Blender add-on)
- **Keys:** repo `.env` (gitignored): `TRIPO_API_KEY`, backups `TRIPO_API_KEY_2`, `_3`, `_4` (they start with `tsk_`). Use key 1, move to the next when one runs out. Free credits only: **never buy or top up**; tell the user when all 4 are empty. Never print or commit key values.
- **API:** base `https://openapi.tripo3d.ai/v3`, header `Authorization: Bearer <key>`, JSON bodies.
  - `POST /generation/text-to-model` `{ "prompt": "...", "model": "v3.1-20260211" }` (or `v3.0-20250812`; texture/PBR options) → `data.task_id`
  - `POST /generation/image-to-model` (one image; upload it first with `POST /upload`)
  - `GET /tasks/{task_id}`: poll until `status` is `"success"`, then read `model_url` (GLB) and `rendered_image_url`. **Model URLs expire after ~5 minutes: download at once.**
  - Rigging: `/animations/rig-check`, `/animations/rig`, `/animations/retarget` (a full game-ready character pipeline costs about 85 credits).
  - Docs: https://developers.tripo3d.ai/en/docs/quick-start and https://docs.tripo3d.ai
- **Pipeline:** download the GLB to the scratchpad → import into Blender → clean up (tri budget, one mesh per material, bottom-center origin, stud scale) → export FBX into `blender_assets/` → the user imports it in Studio. Credit Tripo in a credits file if their terms ask for it.
- No Tripo script exists in the repo yet: write one in Python (read `.env`, `urllib`/`requests`) the first time it's needed.

### Poly Haven (CC0: free for anything, no credit needed)
- Through Blender MCP (switched on by `autostart.py`, no key): `get_polyhaven_status`, `get_polyhaven_categories(asset_type)`, `search_polyhaven_assets(asset_type, categories)`, `get_polyhaven_asset_preview`, `download_polyhaven_asset(asset_id, asset_type, resolution, file_format)`, `set_texture(object_name, texture_id)`.
- `asset_type`: `hdris` (skies, lighting), `textures` (PBR sets: diffuse, normal, roughness, displacement), `models` (rocks, plants, furniture, …).
- Use for: real stone, wood, dirt, metal and fabric surfaces on Blender kit pieces (keep maps ≤1024 for Roblox SurfaceAppearance; normal maps must be OpenGL), environment props, lighting reference. Restyle to the world (e.g. castle stone tinted toward `#6E6A80`).
- Site: https://polyhaven.com

### Sketchfab (huge model library; license per model)
- Through Blender MCP (token in `C:\Users\User\tools\blender-mcp\keys.env` as `BLENDERMCP_SKETCHFAB_API_KEY`, loaded by `autostart.py`): `get_sketchfab_status`, `search_sketchfab_models(query, categories, count, downloadable)`, `get_sketchfab_model_preview(uid)`, `download_sketchfab_model(uid)` (imports into Blender; check `world_bounding_box` and rescale).
- **Only downloadable models under CC0 or CC-BY** (CC-BY: put author + link in a credits file). Skip NC (non-commercial), ND and SA. Check each model's license before using it.
- Use for: specific real-world props and environment pieces generate_mesh can't make; restyle (materials, colors) and decimate.

### Blend Swap (MCP `blendswap`, HTTP server, key in `~/.claude.json`)
- Tools: `search_assets` (free), `get_asset` (free: details + license), `get_balance` (free: credits and today's free downloads), `download_asset` (**7 free downloads a day**, then 10 credits each). Paid cloud rendering tools `list_studio_tools`, `quote_generation`, `create_generation`, `get_generation`: don't use without the user's OK.
- **Rules:** `get_balance` before downloading; only **CC0 / CC-BY** assets (credit CC-BY), skip NC and SA; licenses are declared by uploaders and not verified, so show the license before relying on a file. Their plan list says commercial use needs the Artist plan: check before shipping anything from Blend Swap. Never buy a plan or credits.
- Use for: ready-made props and set dressing (.blend files) → append in Blender, decimate, restyle, export FBX.
- Site: https://blendswap.com

### Poly Pizza, Hyper3D Rodin, Hunyuan3D (Blender add-on)
Off. Poly Pizza (stylized low-poly, CC-BY credit) needs a free API key from https://poly.pizza/settings/api; the add-on's Hyper3D / Hunyuan / Tripo generators are paid Premium only (we call Tripo directly instead).

### Hand-made textures
Python + Pillow/numpy scripts in `textures/`: `make_pixelplains.py` (PixelPlastic maps, belt tread, crayon sun), `make_toolfx.py` (freeze ring, pause glyph, pixel spark, pause beam, rope, scanlines), `make_castlefx.py` (flame, star spark, slash, smoke, area ring). Beam textures run along the image's **height**; particles are drawn white where the emitter's Color tints them. Upload with `upload_image` (§1).

## 3b. Sound and music sources

Goal (CLAUDE.md note 5): movement, every tool use (wind-up / effect / impact), enemies, a crackle whenever the Glitch appears, Pip bleeps, UI, and music per world. The user approved searching the whole internet: pick the best-sounding option from any source below, as long as the license allows commercial use in a game. **Check the license on every file**, keep `sounds/CREDITS.md` (file, source, author, license, link), and never use ripped game/movie audio.

| Source | License | Notes |
| --- | --- | --- |
| **Roblox Creator Store: ProSoundEffects** | Pro Sound Effects' catalog, licensed for Roblox experiences | No download or upload needed: use the id directly. **Search with `python sounds/find_sounds.py "<query>"`** (public toolbox API, keeps only ProSoundEffects / APMOfficial / Roblox / Monstercat, prints length + description; `"q@2"` = max 2 s, `MIN=90` env = min length, `OK=APMOfficial` env = creators). Much faster and more compact than Studio MCP `search_asset` (which can't filter by creator). PSE is a realistic library: search by material/action ("fire whoosh", "metal hits", "magic poof", "electricity static"); cartoon words ("boing", "cartoon jump") find nothing useful. Ignore other uploaders (many are ripped) |
| Roblox's own sounds (creator **Roblox**) | Roblox's | UI set `Roblox_UI_*` / `RBLX UI *` (clicks, hover, select, whooshes, stinger) |
| Roblox Creator Store: Roblox / APM Music | licensed for Roblox experiences | music tracks, same search |
| **Kenney.nl** audio packs | CC0 | Interface, Impact, Digital, RPG, Sci-fi, Casino, Music Jingles… clean game SFX |
| **Freesound.org** | per sound (CC0 / CC-BY / CC-BY-NC) | 700k+ sounds; filter License = CC0 (or CC-BY with credit); skip NC |
| **Sonniss GameAudioGDC** bundles | royalty-free, commercial, no attribution | yearly multi-GB professional libraries (sonniss.com/gameaudiogdc) |
| **OpenGameArt.org** | per file (CC0 / CC-BY / GPL…) | game SFX and chiptune music; prefer CC0, CC-BY with credit; skip GPL/NC |
| **Pixabay** sound effects + music | Pixabay Content License | commercial OK, no attribution; can't resell the raw files |
| **Mixkit** (Envato) | Mixkit free license | check the license page per category (SFX and music differ) |
| **ZapSplat** | free with credit (Gold removes credit) | big pro library; add credit |
| **Incompetech** (Kevin MacLeod) | CC-BY 4.0 | music; credit required |
| **FreePD** | CC0 / public domain | music |
| **Soundimage.org** (Eric Matyas) | free with attribution | game music loops and SFX |
| AI sound generation | varies | for unique sounds (Pip's voice, Glitch crackle) if a connected audio AI is available |

**Getting non-Roblox files into the game:** downloading is needed (state file, source, size; the user approved CC0/commercial-safe downloads for this). Put files in `sounds/` (WAV/OGG/MP3, trimmed, normalized), log them in `sounds/CREDITS.md`, then the **user bulk-imports** them in Studio's Asset Manager (audio uploads need the user; ≤7 min per file), and the ids go into `src/shared/Config/Sounds.luau`.

**Built (Oct 1, 2026):** `Config/Sounds.luau` (Sfx / Music / BossMusic / Ambience: ids + Volume/Pitch/PitchVar/Range/Group), `Util/Audio.luau` (`Audio.play(name, part | position | nil)`; server plays replicate to everyone, client plays are local; SoundGroups Music / Ambience / SFX / UI, made by the server), `AudioController` (music + ambience per `workspace.World`, boss music on `BossFight`, crossfade, cutscene duck), hooks in MovementController, ToolFxController, CodeLayerController, HUD (Pip bleeps + chirp, level-up), CutsceneController (Pip bleeps, crackle on "???" lines), CombatService, FireMage, InteractableService, HealthService, CheckpointService, XpService, ContraptionService (Glitch wall crackle + hum). Plain jump / land / footsteps are Roblox's default character sounds. All ids verified loading in Studio.

## 4. Browser (references)

- The user's browser is **Brave** with the Claude in Chrome extension: tools `mcp__claude-in-chrome__*` (`tabs_context_mcp`, `tabs_create_mcp`, `navigate`, `computer`, `browser_batch`, `read_page`, `tabs_close_mcp`, …). In the VS Code panel they only load when the user's message contains **`@browser`**; load them in one `ToolSearch select:` call.
- Reference search: Google Images `https://www.google.com/search?tbm=isch&q=<query>`, screenshot at `scale: 0.6`, write down shape/proportion/color takeaways, never copy It Takes Two assets (art-direction.md §1, §18). Open your own tab and close it when done.
- Fallback without the browser: `WebSearch` / `WebFetch`.

## 5. Desktop / general

- **MCPControl** (`mcp__MCPControl__*`): mouse/keyboard/screenshot for Windows (can't reach Studio while VS Code is focused).
- **Python 3.13** (user site): Pillow, numpy, reportlab, pypdf, pypdfium2, pdfplumber, python-docx, python-pptx, openpyxl, pandas, markitdown. Scripts dir not on PATH → `python -m <tool>`.
- **Node 24 / npm 11** globals: typescript, tsx, sharp, playwright, … (`NODE_PATH="$(npm root -g)"` to require them).
- **git + gh** (logged in as ohimeee). Remote `https://github.com/ohimeee/glitched_together`, branch `main`; commit + push finished work without asking (memory autonomy), no Co-Authored-By lines.
- **uv / uvx**, **pandoc**, **psql**, LibreOffice (`"C:\Program Files\LibreOffice\program\soffice.exe"`).

## 6. Where things live in the code

| What | File |
| --- | --- |
| Tuning numbers (incl. `ToolFx` timings) | `src/shared/Config/Tuning.luau` |
| Colors (art-direction §16) | `src/shared/Config/Palette.luau` |
| World lighting (`Look`: sun texture, `EnvSpecular`, …) | `src/shared/Config/Worlds.luau` |
| Held items + FX texture ids | `src/shared/Config/ToolFx.luau` |
| Mesh skins / decor per world | `src/adventure/server/Services/ArtService/*.luau` (+ `MeshAssets.luau` loader: `Variant`, `Texture`) |
| Castle combat FX | `src/adventure/server/Services/CombatFx.luau` |
| Tool VFX (client) | `src/adventure/client/Controllers/ToolFxController.luau` |
| MaterialVariants | `adventure.project.json` → MaterialService |
| Sound ids, volumes, music per world | `src/shared/Config/Sounds.luau` (player: `src/shared/Util/Audio.luau`; music/ambience/duck: `client/Controllers/AudioController.luau`; credits: `sounds/CREDITS.md`) |
| Studio world jump | `workspace:SetAttribute("DebugWorld", "<World>")` on the server during play |
