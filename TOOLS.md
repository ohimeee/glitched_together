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
| `search_asset` / `insert_asset` | Creator Store search/insert (models, audio…) | Audio: use only creator **ProSoundEffects** (licensed) or Roblox/APM music; many user uploads are ripped game sounds. Descriptive queries ("whoosh swoosh") work; long multi-word queries often return 0; `verifiedCreatorsOnly`/`facets` don't filter |
| `generate_texture`, `generate_procedural_model`, `inspect_instance`, `search_game_tree`, `script_read/grep/search`, `multi_edit`, `character_navigation`, `user_keyboard_input`, `user_mouse_input`, `segment_mesh`, `store_image`, `http_get`, `subagent`, `skill` | Available, rarely needed | |

**Can't do:** Studio UI clicks (File → Import 3D). MCPControl can't bring Studio to the front while VS Code holds focus → ask the user to import FBX files (batch them). Scripts can't set a MaterialVariant's maps at runtime → declare variants in `adventure.project.json` (MaterialService).

## 2. Blender

- **Blender 5.2.2** at `D:\Blender\blender.exe`. Start with the MCP server already running: `cmd //c start "" "D:\Blender\blender.exe" --python "C:\Users\User\tools\blender-mcp\autostart.py"` (port 9876, also enables Poly Haven, loads the Sketchfab key).
- **Blender MCP** (`mcp__blender__*`): `execute_blender_code` (main tool, bpy/bmesh), `get_scene_info`, `get_object_info`, `get_viewport_screenshot`, `bpy_api_lookup`, `describe_node_type`, `export_scene`, `set_texture`; Poly Haven (`search/download_polyhaven_asset`), Sketchfab (`search/download_sketchfab_model`, `get_sketchfab_model_preview`), Poly Pizza (needs a key, off), Hyper3D/Hunyuan/Tripo via add-on (paid, off). Add-on protocol is behind (11 vs 13) but works; `uvx mcp-for-blender install-addon` would update it.
- Pipeline and scripting rules: `BLENDER_PLAYBOOK.md` §6–7 (stud scale, Blender (x,y,z) → Roblox (−x,z,y), FBX export flags, offsets computed from bbox centers, save a `.blend` copy + `.fbx` in `blender_assets/`).

## 3. 3D / asset sources

| Source | How | Rules |
| --- | --- | --- |
| Studio `generate_mesh` | see above | First choice for characters, enemies, held items, organic props |
| **Tripo** REST API V3 | keys `TRIPO_API_KEY`, `_2..4` in `.env` (gitignored) | Free credits; never buy. For hero assets / when generate_mesh runs out |
| **Poly Haven** | Blender MCP | CC0 textures/HDRIs/models |
| **Sketchfab** | Blender MCP (token in `C:\Users\User\tools\blender-mcp\keys.env`) | Downloadable CC0 / CC-BY only (credit CC-BY) |
| **Blend Swap** | `mcp__blendswap__*` (`search_assets`, `get_asset`, `get_balance`, `download_asset`) | 7 free downloads/day; check `get_balance` first; CC0/CC-BY only; commercial use may need the Artist plan |
| Hand-made textures | Python + Pillow/numpy scripts in `textures/` | `make_pixelplains.py`, `make_toolfx.py`, `make_castlefx.py`; Beam textures run along the image's height |

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
| Studio world jump | `workspace:SetAttribute("DebugWorld", "<World>")` on the server during play |
