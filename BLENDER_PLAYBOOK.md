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
| Surface look (stone, wood, pixel grass) | Studio `generate_material` / MaterialVariant, or Poly Haven textures |
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
| 1 | **Pixel Plains art pass 2** (new layout): cliff, dirt wall, conveyor kit (Blender, `PixelPlainsKit2.*`, awaiting import) + generated Glitch Blob, flowers, bush, bounce pad; still to make: Static Bat, tree, lever, fan, dropper chute, door, sign boards, "BY KAI + MIKO" sign | Pixel Plains | Brief + ids: `briefs/PixelPlains2.md` |
| 1 | Castle kit: floor tiles, 6-stud walls with arches, torch, brazier, banner, iron bars, cracked wall, wooden door, enemies (googly-eyed skeleton, slime, archer, shield guard, mage) | Starfall Castle | Top-down readable; floors carry the design |
| 2 | Castle gate, torch/brazier, banner, bookshelf, iron bars, Siege Cart | Starfall Castle | Top-down readable from above |
| 3 | Wireframe cubes, missing-texture blocks, SAVE button | Glitched Core | |
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
