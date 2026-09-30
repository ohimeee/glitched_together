# Brief: Pixel Plains art pass 2 (new layout, graphics baseline)

**Status (Sep 30, 2026): in progress.** Meshes made, not wired into the game yet. Target: the rebuilt Pixel Plains grey-box (`Greybox/init.luau` buildPixelPlains) at the approved graphics baseline (memory: graphics-baseline), themed voxel toy-plastic (art-direction.md §8), owner colors only on gameplay targets (§6).

## 1. Blender kit (exact-size pieces) — `blender_assets/PixelPlainsKit2.blend / .fbx`

Built at stud scale, bevelled voxels, one mesh per material, cube-projected UVs, transforms applied. Each asset's pieces share a pivot at its bottom center. **Needs the user's Import 3D click in Studio** (File → Import 3D → `PixelPlainsKit2.fbx`), then read the MeshIds with `execute_luau` and compare bounding boxes (import scale varies, memory: studio-ui-clicks).

Sizes/offsets below are already in Roblox axes (Blender (x, y, z) → Roblox (−x, z, y)), offset = piece bbox center from the asset's bottom-center origin.

| Asset (Design size) | Piece | Tris | Size | Offset | Look |
| --- | --- | --- | --- | --- | --- |
| `PP_Kit_Cliff` (20 × 20 × 20) | `_Top` | 2,530 | 20.50, 5.00, 20.50 | 0, 17.5, 0 | grass `#5BD15B` cap + stepped pixel drips |
| | `_Dirt` | 108 | 20.00, 18.40, 20.00 | 0, 9.2, 0 | dirt `#B5773F` |
| | `_Strata` | 88 | 20.24, 6.20, 20.24 | 0, 8.6, 0 | dark dirt `#8A5A2E` bands |
| | `_Stones` | 1,512 | 21.49, 13.20, 21.62 | 0.099, 7.548, −0.039 | stone `#9A9AA6` |
| `PP_Kit_DirtWall` (2 × 20 × 20) | `_Bricks` | 4,840 | 2.00, 19.84, 20.00 | 0, 10, 0 | dirt bricks, running bond |
| | `_Core` | 44 | 1.60, 19.00, 20.00 | 0, 9.5, 0 | dark dirt |
| | `_Top` | 484 | 2.30, 1.80, 20.20 | 0, 19.1, 0 | grass tufts |
| `PP_Kit_Belt` (14 × 2.45 × 30) | `_Frame` | 688 | 14.00, 2.30, 30.00 | 0, 1.15, 0 | metal rails + end rollers |
| | `_Belt` | 924 | 12.00, 0.45, 30.00 | 0, 1.775, 0 | rubber slats (add a scrolling Texture in Roblox) |
| | `_Glow` | 88 | 14.10, 0.15, 30.00 | 0, 2.375, 0 | Kai orange stripe (freezable), Neon via `Palette.Glow.Kai` |

Where they go (ArtService/PixelPlains.luau `Skins` + `Dressing`): `PP_Kit_Cliff` on the tall cliffs (grey-box parts named `Grass` with height ≥ 20; give them a distinct name like `Cliff` in Greybox), `PP_Kit_DirtWall` on `DirtWall`/`DoorWall`, `PP_Kit_Belt` on `Conveyor`. Note the Greybox `Conveyor` part is 2 tall; the belt design box is 14 × 2.45 × 30 (scale Y to fit).

## 2. Studio `generate_mesh` (textured, already uploaded)

| Name | MeshId | TextureId | Generated size | Use |
| --- | --- | --- | --- | --- |
| Glitch Blob | `rbxassetid://111365424915916` | `rbxassetid://105026392006200` | 2.73 × 3 × 2.15 | skin for `GlitchBlob` enemy (collider 4 × 3 × 4); check facing (Yaw) |
| Flowers | `rbxassetid://97758112493229` | `rbxassetid://84236852470382` | 3.28 × 3 × 2.21 | Decor, scatter on meadow/plaza edges |
| Bush | `rbxassetid://97383134312851` | `rbxassetid://132624303942108` | 2.85 × 4 × 2.86 | Decor |
| Bounce pad | `rbxassetid://127413358129106` | `rbxassetid://86478495845252` | 2.72 × 3 × 2.72 | skin for `BouncePad` (8 × 1 × 8, Duo white) |

Failed, retry: **Static Bat** ("Moderation failed": reword without "fangs"/"menacing", e.g. "cute round purple voxel bat toy with blocky pixel wings and big googly eyes"), **voxel tree** ("Too Many Requests": run 2–3 generations at a time, not 6).

Still to generate: teal pull lever, fan/vent base, dropper chute pipe, timed door, wooden sign board with posts, "BY KAI + MIKO" hill sign, crayon sun (skybox), duo pound button.

## 3. Wiring plan (next session)

1. Import the FBX (user click), read ids, fill `Skins` entries in `ArtService/PixelPlains.luau` (MeshAssets.Skin pattern: `Design` + per-piece `Id/Offset/Size/Material/Color`).
2. Enemy skins like `ArtService/StarfallCastle.luau` (`enemy(design, id, tex, size, offsetY, yaw)`); decor via `Decor` (`{ skin, CFrame, scale }`).
3. Surfaces: Studio `generate_material` for a "PixelPlastic" MaterialVariant (glossy toy plastic with fine pixel bumps) and apply to the kit MeshParts, so they are not flat colors (graphics baseline).
4. Playtest + screenshots per section; then environment dressing (trees, flowers, bushes, clouds, coin blocks) along the route, leaving the play space clear (§10).
