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
| Poly Haven: `search_polyhaven_assets`, `download_polyhaven_asset`, `get_polyhaven_asset_preview` | CC0 HDRIs, textures, models. **Currently disabled** → see §9 |
| Poly Pizza: `search_polypizza_models`, `download_polypizza_model` | Stylised low-poly models (credit CC-BY authors). **Disabled, needs free API key** |
| Sketchfab: `search_sketchfab_models`, `get_sketchfab_model_preview`, `download_sketchfab_model` | Specific real-world models. **Disabled, needs API key** |
| Hyper3D Rodin / Hunyuan3D / Tripo: `generate_*`, `poll_*`, `import_generated_asset*` | AI text/image → 3D, one object at a time. **Disabled** (API keys or paid Premium) |
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

From research.md (Hazelight: "Pixar-esque", scale and shape first, stylized but believable) and design.md §5/§8.

**Shape language**
- Big, chunky, readable silhouettes. Oversized everyday things (giant title-menu buttons, huge pixel blocks). Players are small against the world.
- Bevel everything a little (Bevel modifier, 1–2 segments). No razor edges except on "glitch" objects.
- Few, large details over many small ones. Detail must read from a third-person camera 20+ studs away.
- Pixel/voxel look is the game's signature: the Glitch, Pip and Pixel Plains lean voxel. Castle leans hand-built fantasy. Glitched Core mixes both plus wireframes.

**Player identity (never break)**
| Role | Color | Shape motif |
| --- | --- | --- |
| Kai | Orange `#FF8C28` | Triangle ▲ |
| Miko | Teal `#28D2C8` | Circle ● |

**Readable targets (same everywhere)**
| Interactable | Look |
| --- | --- |
| Freezable | Blue frame `#5AAAFF` |
| Grapple point | Orange ring `#FF9628` |
| Pullable | Yellow handle `#FFD23C` |
| Burnable | Cracked wood |
| Copyable | White outline |
| Code Layer | Green scanlines/wireframe `#3CFF78` (Miko only) |
| Glitch (danger) | Flickering static, RGB split, magenta/black "missing texture" checker |

**World palettes** (match `src/shared/Config/Worlds.luau`)
| World | Colors | Materials feel |
| --- | --- | --- |
| Prologue (Title Screen) | Navy `#14183A`, UI white `#F0F0FA`, glitch pink `#FF50AA` | Floating UI panels, glossy plastic |
| Pixel Plains | Green `#58C848`, sky `#6EBEFF`, coin gold `#FFCD28` | Chunky voxel blocks, flat colors, pixel clouds |
| Starfall Castle | Purple `#46286E`, torch orange `#FF8C28`, gold `#E6BE46` | Stone, banners, stained glass, torches |
| Glitched Core | Grey `#828287`, black `#0F0F12`, green `#3CFF78`, magenta `#FF28C8` | Untextured grey, wireframes, static |
| Epilogue | Night blue `#1E2D5F`, warm `#FFE196`, star `#A0BEFF` | Bedroom real-world, then starry kingdom |

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
8. **Hook up in code** (Rojo-friendly, no .rbxm to hand-save): store ids + offsets + look in a data module and create the parts at runtime with `AssetService:CreateMeshPartAsync(Content.fromUri(id), { CollisionFidelity = … })`, load each mesh once and `Clone()` it, keep a grey-box fallback. Example: `src/lobby/server/CapsuleMeshes.luau` + `LobbyBuilder`. Then delete the imported model from the place, playtest, and `screen_capture` to confirm.
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
| ✅ | **Pip** | All | Done: `blender_assets/Pip.fbx` (276 faces) |
| ✅ | **Lobby capsule** (Kai ▲ / Miko ●) + marquee | Lobby | Done and in game: `blender_assets/LobbyCapsule.blend/.fbx` (2,082 tris per capsule), ids in `src/lobby/server/CapsuleMeshes.luau`, brief `briefs/LobbyCapsule.md` |
| 1 | Kai / Miko identity accessories (hood with triangle, jacket with circle patch) | All | Roblox accessories: ≤ 4k tris |
| 2 | Giant title-menu buttons, Options slider, "CONTINUE?" card | Prologue | Floating UI-as-geometry |
| 2 | Coin block, pixel cloud, voxel tree, Pixel Crusher, grapple ring, crate | Pixel Plains | Crusher must read as dangerous |
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
