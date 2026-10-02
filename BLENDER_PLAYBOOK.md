# Blender Playbook — Glitched Together

How Claude (and you) make 3D art for this game: what tools exist, how to find references, the art rules, Roblox limits, and the Blender → Studio pipeline. Read this before any modeling task.

Related: [research.md](research.md) (It Takes Two art notes) · [design.md](design.md) §5 and §8 (readability, palettes) · [BLENDER_SETUP.md](BLENDER_SETUP.md) (install steps).

---

## 1. Before every session

1. Blender is open with the MCP server on port 9876. If Blender isn't running, Claude can launch it with the server auto-started:
   `cmd //c start "" "D:\Blender\blender.exe" --python "C:\Users\User\tools\blender-mcp\autostart.py"` (Blender lives in `D:\Blender`). Otherwise the user clicks sidebar **N → MCP for Blender → Connect to MCP server**.
2. `get_addon_status` → confirm `up_to_date`, read `blender_version`, check `telemetry_consent` is **false** (the user wants it off).
3. `get_scene_info` → see what already exists. **Never delete or overwrite the user's objects**; only remove things Claude made, or the untouched default Cube.
4. Studio open too if the asset goes straight into the game (`list_roblox_studios` for the id).

Quick socket check without MCP (PowerShell): connect to `localhost:9876` and send `{"type":"get_scene_info","params":{}}`.

---

## 2. Tool inventory

### Blender MCP (`mcp__blender__*`)
| Tool | Use |
| --- | --- |
| `execute_blender_code` | Run Python (bpy/bmesh). The main modeling tool. Send small steps. |
| `get_scene_info`, `get_object_info` | What exists, bounds, materials |
| `get_viewport_screenshot` | **Check the look after every change** |
| `bpy_api_lookup`, `describe_node_type` | Look up API / shader node sockets instead of guessing |
| `export_scene` | Export helper (or use `bpy.ops.export_scene.fbx` directly) |
| `set_texture` | Apply a downloaded texture to an object |
| Poly Haven: `search_polyhaven_assets`, `download_polyhaven_asset`, `get_polyhaven_asset_preview` | CC0 HDRIs, PBR textures, models. **On** (autostart.py enables it; no key) |
| Poly Pizza: `search_polypizza_models`, `download_polypizza_model` | Stylised low-poly models (credit CC-BY authors). **Disabled, needs free API key** |
| Sketchfab: `search_sketchfab_models`, `get_sketchfab_model_preview`, `download_sketchfab_model` | Models for 3D/environments (user wants it later). Token goes in `C:\Users\User\tools\blender-mcp\keys.env` (`BLENDERMCP_SKETCHFAB_API_KEY=`); `autostart.py` loads it and switches Sketchfab on. Downloadable CC0 / CC-BY only (credit CC-BY) |
| Hyper3D Rodin / Hunyuan3D / Tripo: `generate_*`, `poll_*`, `import_generated_asset*` | AI text/image → 3D. **Disabled** (this add-on offers Tripo only via paid Premium; we call Tripo's REST API directly instead, see below) |
| `disable_telemetry` | Turns data collection off if it ever gets turned on |

### Roblox Studio MCP (`mcp__Roblox_Studio__*`), useful for art
| Tool | Use |
| --- | --- |
| `generate_mesh` | **Roblox Cube text-to-3D, runs on Roblox servers** (our GPU is too small to run Cube locally) |
| `generate_material`, `generate_texture` | AI MaterialVariants / textures inside Studio |
| `generate_procedural_model` | Procedural models in Studio |
| `search_asset`, `insert_asset` | Creator Store models |
| `upload_image`, `store_image` | Push reference or texture images into Studio |
| `execute_luau` (Edit) | Place / scale / tag imported meshes, set CollisionFidelity, build from parts |
| `screen_capture` | See the result in Studio |

### Tripo API (direct REST, not the Blender add-on)
AI text/image → textured 3D (GLB), plus retexture, smart low poly, rigging. Use when Studio `generate_mesh` runs out or a hero asset needs more quality/control. Keys in repo `.env` (gitignored): `TRIPO_API_KEY`, backups `TRIPO_API_KEY_2..4`, used in order when one runs out of credits. API **V3** (V2 retired Oct 2026). Docs: https://platform.tripo3d.ai/docs. Output → Blender cleanup (tri budget, split per material, origin bottom-center) → FBX → user Import click. Credit Tripo in `CREDITS.md` if its terms require it.

### Other
- **Claude in Chrome (`mcp__claude-in-chrome__*`), running in the user's Brave browser:** browse for reference pictures (§3A).
- **WebSearch / WebFetch:** research and finding reference image URLs.
- **MCPControl:** screenshot the desktop, drive any window (e.g. open an image search in Brave and look at it).
- **Read** tool shows images, so any downloaded reference can be viewed directly.

### Which tool for which job
| Need | Use |
| --- | --- |
| Hero asset with exact style (Pip, capsules, signature props, boss parts) | **Blender**, scripted |
| Generic filler prop (barrel, crate, tree) | Poly Pizza / Poly Haven (once enabled), or Studio `generate_mesh` |
| Quick grey-box piece or tag-driven level part | Plain Parts in code (see `src/adventure/server/Greybox`) |
| Surface look (stone, wood, pixel grass) | Roblox materials first (Wood, WoodPlanks, Metal, Rubber); a custom MaterialVariant from hand-made maps (`textures/make_*.py`) declared in the Rojo project (scripts can't set variant maps at runtime); Studio `generate_material` came out too heavy for Pixel Plains; Poly Haven textures |
| World environments (polish phase): textures, HDRIs, set dressing, filler props | **Poly Haven** (CC0) + **Blend Swap** (`blendswap` MCP: `search_assets` with CC0/CC-BY filter, `get_balance` before `download_asset`, then append in Blender, decimate to budget, restyle to the world palette) |

---

## 3. Reference images

The user allows searching anything for reference. Their browser is **Brave** (not Chrome; Chrome isn't used on this PC), with the **Claude in Chrome** extension installed in Brave and their sign-ins.

### A. Claude in Chrome, in Brave (preferred)

1. Check the tools exist: `ToolSearch("+claude-in-chrome")`. If only `enable__mcp__claude-in-chrome` shows, call it first. No match at all → in the **VS Code panel the browser connects only when the user's message contains `@browser`**: ask them to resend the request with `@browser` in it. Still missing → `/chrome` → **Reconnect extension**, or fully restart Brave. Use route B meanwhile.
2. Load the `anthropic-skills:chrome-browser` skill (tab rules) and, for picture hunting, `anthropic-skills:images-searching`.
3. Load the tools in ONE call:
   `select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__tabs_create_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__read_page,mcp__claude-in-chrome__tabs_close_mcp`
4. `tabs_context_mcp` first, then **open a new tab** (never take over the user's tabs). Close tabs you opened when done.
5. Where to look:
   | Need | Site / query |
   | --- | --- |
   | Silhouettes, mood | Google Images `https://www.google.com/search?tbm=isch&q=<query>` |
   | Stylized game art, breakdowns | ArtStation (`artstation.com/search?query=`), Pinterest |
   | Voxel / pixel style | "voxel <thing>", "MagicaVoxel <thing>", "pixel art <thing> sprite" |
   | Low-poly 3D reference | Sketchfab (`sketchfab.com/search?q=`), Poly Pizza (`poly.pizza`) |
   | Roblox-scale examples | "roblox <thing> build", Roblox Creator Store |
6. Look with `computer` screenshots; zoom/scroll as needed. Write a short brief (silhouette, proportions, palette, detail density) before modeling.
7. If a site asks permission, tell the user and wait. Stop and ask after 2–3 failed attempts.

### B. Fallback (no browser)

1. `WebSearch` for the idea (e.g. "voxel sprite character front view", "It Takes Two Rose's Room castle concept art", "chunky stylized castle gate").
2. From results, `WebFetch` a page and ask it for direct image URLs (`.png`/`.jpg`).
3. Download into the scratchpad: `curl -L -o <scratchpad>/refs/<name>.jpg "<url>"`.
4. `Read` the file to look at it. Summarise what to take: silhouette, proportions, palette, detail density.
5. Or open Google Images in the user's Brave (`start brave "https://www.google.com/search?tbm=isch&q=<query>"`) and look with `mcp__MCPControl__get_screenshot`.

### Rules (both routes) references are for **shape, proportion and mood only**. Never copy It Takes Two (or any game's) characters, logos, textures or layouts (design.md §1). Don't commit downloaded reference images to the repo; keep them in the scratchpad.

---

## 4. Art direction rules

**The spec is [art-direction.md](art-direction.md)** (theme, color script, shape language, reserved gameplay colors §6, exact palette §16, Blender asset guide §17, reference search §18). Colors in code come from `src/shared/Config/Palette.luau`, which mirrors §16. Short version:

- *A game two kids made, seen from the inside.* Chunky, soft, bevelled, handmade; kid details (doodles, stickers, misspelled signs). Only The Glitch looks wrong (flat, sharp, magenta, static).
- **Reserved gameplay colors, never decoration:** Kai's targets **orange** `#FF8A2B` (freeze, burn, copy) · Miko's **teal** `#1FC7B6` (grapple, pull, Code Layer) · both players **white** `#F5F7FA` · neutral **yellow** `#FFD23F` (plates, checkpoints) · danger **red** `#E5383B` · Glitch **magenta** `#FF2BD6` (+ cyan `#2BF2FF` fringe, black `#0B0B10` checker). Every target also gets an icon.
- **Shapes:** friendly = round and soft, enemies = round body + one sharp feature and googly/dot eyes, Glitch = jagged and flat. Kai = stars, straight lines; Miko = circles, blocks, springs.
- **Pixel Plains** voxels are 1-stud cubes with a small bevel (plastic toys). **Castle** floors carry the design (top-down camera), walls 6 studs. **Core** is deliberately flat grey.
- **Names:** `<World>_<Type>_<Name>` with `PR_ PP_ SC_ GC_ FL_ RW_ SH_` and `Kit / Prop / Char / Boss / FX` (e.g. `PP_Prop_CoinBlock`). Pieces split per material get a suffix (`PP_Prop_CoinBlock_Mark`).
- **Budgets:** small prop 300–1,500 tris, medium 1,500–5,000, kit piece 200–2,000, character 5–10k.

**Materials**
- Default: Principled BSDF, roughness 0.5–0.7, metallic 0. Flat color first; texture only when it adds readability.
- Glow only on Neon-style accents (Roblox Bloom threshold is high, so only emissive/neon parts bloom).
- Convert hex to linear for Blender base color: `c = (hex/255) ** 2.2`.

---

## 5. Roblox technical limits

Source: [Roblox mesh specifications](https://create.roblox.com/docs/art/modeling/specifications), [texture specifications](https://create.roblox.com/docs/art/modeling/texture-specifications).

| Rule | Value |
| --- | --- |
| Triangles per mesh | **≤ 20,000** (environment). Character/avatar meshes ≤ 10,000; UGC accessories ≤ 4,000. Aim 2k–10k for mobile |
| Geometry | Watertight, real volume (no zero-thickness planes), quads where possible, no loose/backface junk |
| Textures | Max 1024×1024 per map in Studio (4K on upload); 256 for ~5-stud props, 512 for ~10, 1024 for ~20 |
| PBR (SurfaceAppearance) | Albedo RGB · Normal RGB (**OpenGL**, tangent space) · Roughness, Metalness, Emissive mask: 8-bit grayscale |
| UVs | One UV set, inside 0–1, overlaps allowed |
| Rigs | Frozen transforms (scale 1, rotation 0), ≤ 4 bone influences per vertex, root at origin |
| Animation | One animation track per exported file |
| Formats | FBX, glTF/GLB, OBJ |

**Our conventions**
- **1 Blender unit = 1 stud.** Model at game size (a player is ~5 studs tall; a door ~8–10 studs).
- Origin at the **bottom center** of the object (so it sits on the ground when placed), transforms applied (Ctrl+A) before export.
- Separate meshes per material zone only when needed; prefer one mesh with multiple materials (≤ ~4).
- Collision: set `CollisionFidelity = Box` or `Hull` in Studio for props; only use `PreciseConvexDecomposition` for walkable complex shapes.
- **Verify scale on first import of each new asset type**: Pip should be about 3 studs tall. If it comes in 100× off, change the 3D Importer's scale unit (and note the correct setting here).

---

## 6. Pipeline: Blender → Studio

1. **Reference** (§3) → write a brief in `blender_assets/briefs/<Name>.md`: references looked at, direction, size in studs, silhouette, colors from §4, build plan. Example: `briefs/LobbyCapsule.md`.
2. **Block out** in Blender with scripted primitives/bmesh at game scale. Screenshot.
3. **Refine**: bevels, proportions, materials. Screenshot from the gameplay camera angle (slightly above, ~20 studs away).
4. **Check**: triangle count (`sum(len(p.vertices) - 2 for p in mesh.polygons)`), no non-manifold edges, transforms applied, origin bottom-center.
5. **Save** source + export into the repo:
   - `blender_assets/<Name>.blend` (save a *copy* so the user's open file isn't renamed: `bpy.ops.wm.save_as_mainfile(filepath=..., copy=True)`)
   - `blender_assets/<Name>.fbx` (`use_selection=True, object_types={"MESH"}, apply_unit_scale=True, bake_space_transform=True`)
6. **Import to Studio**: Home → **Import** → the `.fbx`. **The user has to click this** (Studio MCP has no FBX import tool, and MCPControl clicks don't reach Studio while VS Code holds the foreground; Windows has only one cursor). Import into any open place: it uploads each mesh as an asset.
7. **Read the ids** with `execute_luau` (Edit): each MeshPart's `MeshId`, `Size`, `Position`. Our FBX comes in at **100× (cm)** with Blender (x, y, z) → Roblox (−x, z, y), so divide sizes/offsets by 100; Blender −Y (front) ends up facing Roblox −Z.
8. **Hook up in code** (Rojo-friendly, no .rbxm to hand-save): store ids + offsets + look in a data module and create the parts at runtime with `AssetService:CreateMeshPartAsync(Content.fromUri(id), { CollisionFidelity = … })`, load each mesh once and `Clone()` it, keep a grey-box fallback. Loader: `src/shared/Util/MeshAssets.luau`. Examples: `src/lobby/server/CapsuleMeshes.luau` + `LobbyBuilder` (whole objects), `src/adventure/server/Services/ArtService.luau` ("skins": invisible grey-box collider + scaled mesh shell, gameplay untouched). The importer's scale isn't always the same (LobbyCapsule came in ×100, PrologueUI ×0.611, Pip ×1): compare each bounding box with the design size. Then delete the imported model from the place, playtest, and `screen_capture` to confirm.
9. **Testing a place:** `rojo build <project> -o build/<Place>.rbxl`, open it in a second Studio (`RobloxStudioBeta.exe -task EditFile -localPlaceFile …`); to reload after code changes, kill that Studio process and rebuild (Studio HTTP is off, so live-pushing source from the MCP isn't possible without the Rojo plugin click).

Naming: PascalCase, world prefix for world-specific assets: `Pip`, `Capsule_Kai`, `PP_CoinBlock`, `SC_CastleGate`, `GC_WireframeCube`.

---

## 7. Blender scripting rules

- Look up shader nodes **by type**, never by name: `next(n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED")`.
- Don't hardcode enum identifiers; read them from `bl_rna` first. Render engine: read the current value; wrap changes in `try/except TypeError`.
- With `use_nodes`, set colors on the node inputs (also set `diffuse_color` for the viewport).
- Small steps; one idea per `execute_blender_code` call; screenshot after each visible change.
- Build reusable helpers inside each call (`mat(name, rgb)`, `voxel(...)`) rather than relying on state from earlier calls.
- `bmesh` for voxel/generated geometry; skip faces between touching voxels so meshes stay light (see Pip).
- Frame the result: set the 3D view to Material Preview and `view3d.view_selected` via `bpy.context.temp_override(area=..., region=...)`.

### Recipes
- **Voxel sprite (Pip):** 2D pixel map per layer → cubes of size `V`, cull shared faces, material per symbol. Source: `blender_assets/Pip.blend`.
- **Chunky prop:** primitive → Bevel modifier (width 0.1–0.2, 2 segments) → apply → simple 2–3 color materials.
- **Glitch object:** duplicate mesh offset by ±0.05 in X with magenta and cyan emissive materials (RGB split), plus a black/magenta checker texture. Animate the flicker in Roblox code, not in Blender.
- **Wireframe (Glitched Core):** Wireframe modifier (thickness 0.05–0.1) on a low-poly shape, emissive green.
- **Pixel terrain block:** cube with top-face green, sides dirt, 2–3 voxel "grass tufts" on top edges.

---

## 8. Asset backlog

| Priority | Asset | World | Notes |
| --- | --- | --- | --- |
| ✅ | **Pip** | All | Redone Sep 30 to the graphics baseline with Studio `generate_mesh` (4 textured parts; ids in `ArtService/Pip.luau`); old Blender voxel version kept in `blender_assets/Pip.*` |
| 1 | **Redo to the graphics baseline** (art-direction.md top note): lobby capsule, Prologue set, Pixel Plains kit, role badges, castle kit (real stone / wood / metal surfaces before import) | All | Current versions are flat-colored primitive builds from before the baseline |
| ✅ | **Lobby capsule** (Kai ▲ / Miko ●) + marquee | Lobby | Done and in game: `blender_assets/LobbyCapsule.blend/.fbx` (2,082 tris per capsule), ids in `src/lobby/server/CapsuleMeshes.luau`, brief `briefs/LobbyCapsule.md` |
| ✅ | Kai / Miko role badges (▲ / ● back badge accessory) | All | In game: `Identity.*`, `ArtService/Badges.luau`. Full outfits per world (art-direction §5) still to do |
| ✅ | Giant title-menu buttons, UI panels, "CONTINUE?" title card | Prologue | In game: `blender_assets/PrologueUI.*`, brief `briefs/PrologueUI.md`, skins in `ArtService` |
| ✅ | Grass block, moving block, Pixel Crusher, grapple ring, crate, cloud, star coin block | Pixel Plains | In game: `PixelPlains.*`, brief `briefs/PixelPlains.md` |
| ✅ | **Pixel Plains art pass 2** (new layout): cliff, dirt wall, conveyor (`PixelPlainsKit2.*`), signs + posts, timed door, pull lever, dropper chute, "BY KAI + MIKO" letters (`PixelPlainsKit3.*`), generated Glitch Blob, Static Bat, tree, flowers, bush, bounce pad, fan; PixelPlastic variant, belt tread, crayon sun (`textures/`) | Pixel Plains | Brief + ids: `briefs/PixelPlains2.md` |
| ✅ | **Tool look, all 6 kits**: held items (generated: ray gun, grapple pistol, staff, sword, round shield, copier, goggles; `Config/ToolFx.luau` Held) + VFX textures (`textures/make_toolfx.py`, `make_castlefx.py`) | All | Particles/Beams in `ToolFxController` (client) and `Services/CombatFx.luau` (server) |
| 1 | Castle kit: floor tiles, 6-stud walls with arches, torch, brazier, banner, iron bars, cracked wall, wooden door, enemies (googly-eyed skeleton, slime, archer, shield guard, mage) | Starfall Castle | Top-down readable; floors carry the design |
| 2 | Castle gate, torch/brazier, banner, bookshelf, iron bars, Siege Cart | Starfall Castle | Top-down readable from above |
| 3 | Wireframe cubes, missing-texture blocks, SAVE button | Glitched Core | |
| 2 | Oct 1 grey-box pieces (after their 2-player test): ON/OFF switch blocks + lever sign (Pixel Plains), Torch Run braziers + spike trap tiles (castle), code plate + door frame (Core) | PP / SC / GC | Nothing floats (memory grounded-props): every prop needs a visible support |
| 1 | **Every obstacle gets real art** (user, Oct 1: "everything realistic like It Takes Two, not just blocks"). Oct 1 6th-session grey-box pieces: Fire Bar Run (spinning fire bars + center posts, glass gallery, cliff, lift), Coin Bonk Stairs (teal ? blocks, sinking coin steps), Siege Cart (mine cart, plank track bed + bends, wooden barricades, archer posts), PLAYERS ONLY door plate, Torch Run trap tiles | PP / SC / GC | Sources: Studio `generate_mesh` / Tripo for hero props (cart, ? block, fire bar), Blender kit pieces with Poly Haven PBR, Blend Swap / Sketchfab set dressing; then the world/environment fill pass (CLAUDE.md note 7) |
| ✅ | **Castle art pass (Oct 1, 7th session):** Poly Haven floor/wall/plank variants; generated torch, brazier, barricade, lookout post, arrow trap, keg, oak doors, iron bars + portcullis, mine cart, cracked wall, rune plate, checkpoint banner; foundations, trestles, rails + moonlit courtyard backdrop (8th session: lawn, curtain walls, towers, spruce/linden, lanterns, wells, carts; `courtyard()`) | SC | ids in `ArtService/StarfallCastle.luau`. Still grey-box in the castle: trap/safe tiles (Torch Run), rug, signs, fuse start post, golem pillars are skinned already |
| ✅ | **Pixel Plains art pass (Oct 2, 9th session):** generated fire-bar iron grate (red-hot core + flames) and cast-iron fire posts, white molded warp pipes, lemon-yellow button plates (green status inlay while held), yellow star checkpoint flags, white toy-fort gate panels tiled along every gate; reused kits: ? blocks (coin block in Miko teal), coin steps, gold/sky ON/OFF blocks (shells ghost); Poly Haven planks on bridges/lifts/windmill arms/crate shelves, corroded-metal factory roofs; every `grass()` floor carries a `Skin` attribute (cliff when ≥ 16 tall) | PP | ids in `ArtService/PixelPlains.luau`. Still plain: gallery glass, Duo Pound pad, Heavy Lever, jump vent, grind rails (metal only), world exit portal |
| ✅ | **Glitched Core art pass (Oct 2, 9th session):** the level as a real unfinished scale model: Poly Haven concrete pulled to primer grey with a baked pencil grid (`textures/make_core.py`, variants CoreFloor / CoreWall), generated beige CRT terminal (orange Highlight = Kai's), film-projector scanner, steel battery conductor; Blender kit `GlitchedCoreKit.blend` → floppy-disk save points ("SAVE" in marker), hand-bent wire cubes on wooden bases, brass scale pans on Beam chains (`textures/make_corefx.py` GC_Chain); foam-board "TODO: DOOR" gates, button plates, plank bridges; Memory Lane echoes in the earlier worlds' kits, faded; floating debris in the void | GC | ids in `ArtService/GlitchedCore.luau`. Code Layer pieces keep their teal look |
| ✅ | **Shared (Oct 2):** marble exit arch with brass stars around every WorldExit, white Duo Pound button, Heavy Lever, generic button plate (`ArtService/init.luau` SHARED, `StateInlay.luau`); Prologue checkpoints use the floppy save point; castle rug (Poly Haven jacquard) + velvet sign banners; Pixel Plains sky islands | All | |
| 2 | Core 3-2 additions: Layer Hop real/code steps, Counterweight balance (centre post, beam, two pans hung on chains from the beam, code anvil); Pixel Plains warp pipes (white, retro pipe shape) + the lane wall | GC / PP | Pans must visibly hang from the beam (nothing floats) |
| 2 | 3-3 Memory Lane pieces: faded menu buttons with labels (Title Echo), static wall segments, Kai's scanner terminal + projector head and cone, unloaded floor tiles (a "loading" look, wireframe edge), PathMark code marks | GC | Echo areas reuse the world kits faded toward grey (broken memories); the terminal needs a desk/stand (nothing floats) |
| 3 | Bosses: Crusher King (stacked blocks + crown), Hollow Dragon, The Unfinished | W1–W3 | Split into parts that the boss code can move |
| 3 | Kai's and Miko's bedrooms | Epilogue | |

---

## 9. Integrations the user can switch on

All in Blender: sidebar **N → MCP for Blender**, then reconnect.

| Integration | What it adds | Needs |
| --- | --- | --- |
| Poly Haven | CC0 HDRIs, PBR textures, models | Tick "Use assets from Poly Haven" (free, no key) |
| Poly Pizza | Stylised low-poly models | Free API key: https://poly.pizza/settings/api |
| Sketchfab | Huge model library | Sketchfab API key |
| Hyper3D Rodin / Hunyuan3D / Tripo | AI 3D generation | Their API keys, or paid MCP for Blender Premium |

Recommended first: **Poly Haven** (free, no key), useful for textures and lighting HDRIs.

## 10. It Takes Two environment pass: how it was done (Oct 2, 2026, 10th session)

**What the user asked (their words) → what it means for every future art task:**
- "search for it takes two environment ... every detail and the users think this is even roblox? ... render/animate the environment in blender" → the world around the level is rendered in Blender (Cycles) and shipped as the Roblox skybox; the level itself gets dense real-looking dressing.
- "not just environment but assets around it" → props on and around every platform (foliage, roots, supports), not only a backdrop.
- "the obstacles should naturally connected to the environment or it has purpose" (memory obstacles-belong) → every lever/bridge/lift/platform is part of a structure: posts, hoists, cranes, islands.
- "make the created environment match our design" + "we go with your plan" → never change obstacle gameplay or layout for art; re-skin and dress around it.
- "we can safely remove/replace the backgrounds of all 3 worlds" → old in-level backdrops (castle courtyard) may be deleted when the panorama replaces them.
- Rejected: the castle courtyard (clashed with the render), farmland/crop patchwork (Voronoi cells: "ugly, not realistic"). Keep ground natural: soft noise variation, no tiles/patterns.

**Reference pass (Brave, Google Images "it takes two environment screenshot garden level"):** warm low sun with god rays, cool purple shadows, layered depth (foreground foliage → midground set → hazy far backdrop), dense clustered props with wear, nothing flat-colored, huge scale contrast.

**Skybox pipeline (per world):**
1. Blender (MCP): one scene per world in `blender_assets/PixelPlainsSky.blend` (`Scene` = Pixel Plains, `CastleSky` = castle). Make a new scene with `bpy.data.scenes.new` + `bpy.context.window.scene = sc`; **never `read_factory_settings`/`read_homefile`** (kills the MCP server; relaunch Blender if it happens).
2. Build the world procedurally in Python (bmesh): terrain from `mathutils.noise` heights (Pixel Plains: 60-stud voxel columns, quantized 30; castle: smooth 100-stud grid), trees/houses/landmarks as boxes, cones, gables in one mesh per kind, material per face index. Camera at the origin = the level's height; ground ~420–650 below; mountains far out (r > 5k) so the skyline has peaks.
3. Materials: Principled BSDF in the world palette (art-direction §16; sRGB→linear), plus `tools/blender_sky.py add_haze` (camera-distance fade to a haze color) for aerial perspective; AgX view + "Punchy"/"Medium High Contrast" look. Sky: Pixel Plains = Sky Texture `MULTIPLE_SCATTERING`, sun disc OFF (Roblox draws the crayon sun), multiplied toward the palette's blue; castle = custom world shader (normalized Generated direction → color ramp, Voronoi stars, noise Milky Way band) + an emissive moon sphere.
4. Lights: a Sun lamp along the in-game sun direction. Get it in Studio: `Lighting:GetSunDirection()` at the world's ClockTime; Roblox (x,y,z) → Blender (−x,z,y); Sky Texture `sun_rotation = atan2(bx, by)` (rotation 0 = +Y). **Set `visible_shadow = False` on a moon/sun mesh that sits on the light's path** (it shadowed the whole castle valley).
5. Render with `tools/blender_sky.py render_faces` (cycles GPU OptiX, 1024², 128 samples, denoise; previews at 384²/24 samples with `faces=[...]`). Convert to RGB with Pillow (drop alpha), keep files in `textures/sky/`.
6. Upload: `python -m http.server 8765 --bind 127.0.0.1` in `textures/`, Studio MCP `upload_image` with `http://127.0.0.1:8765/sky/<file>.png`; put the 6 ids in `Worlds.luau` `Look.Skybox` (applyLook writes Sky.SkyboxBk..Dn, default sky when nil).
7. Night worlds: **Roblox dims custom skyboxes at night** (black at ClockTime 21). Keep a day clock and fake night with lighting: brute-force `GeographicLatitude` × `ClockTime` in Studio so `GetSunDirection()` points at the baked moon (castle: 8.9 at latitude 78), Brightness ~0.45, purple Ambient/OutdoorAmbient, `Look.Latitude`, `Look.BakedSky = true` (hides Roblox's sun/moon/stars). Atmosphere `Haze = 0` (it paints over the panorama).
8. Check in play from the real gameplay camera (castle is top-down: the Dn face is what players see most; keep it detailed and readable, no bright reflections right below). Lower the level's brightness/ambient until its colors sit in the render.
- Gotchas: camera `clip_end` default 100 hides everything; Generated coords in a world shader must be normalized (else cube seams); test-face mapping is in `tools/blender_sky.py`'s docstring.

**In-level dressing recipes (ArtService/PixelPlains.luau Extras, all non-colliding, CanQuery off):**
- `islandUndersides`: every `GrassBlock` slab ≥ 8 wide gets 3 shrinking dirt/dirt/stone tiers below, vines/roots off the edges, Flowers/Bush skins along free edges (an edge is "joined" if a ray 2.4 out hits floor). Skips slabs resting on something, and any tier overlapping a moving piece's sweep (Mover waypoints, DuoGate open offset, Pullables, dropper lanes) or solid level geometry; foliage keeps 7 studs from gameplay parts.
- `rigHoists`: DuoGate bridges/lifts with an upward `OpenOffset` that hang over nothing: bridges get posts + davit arms on both ledges and Beam ropes to the deck corners; lifts get a crane post on the ledge they rise to, a jib, a pulley, 4 ropes. Beams follow moving attachments, so ropes stay taut.
- Lever posts (`PullLever`), vent fans (`VentFan.luau` shared, client spin in `FanController`), gallery glass frame: see the code comments.
- Castle (`StarfallCastle.luau` fillEnvironment): foundations end at y −90 on 3 jittered rock tiers ("Crag"), trestles on rock piers.
