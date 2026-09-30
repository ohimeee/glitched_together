# Brief: Pixel Plains art pass 2 (new layout, graphics baseline)

**Status (Sep 30, 2026): wired and verified in a Studio playtest.** Kit imported (user click) and every skin applies (4 cliffs, 8 walls, 3 belts, 2 Glitch Blobs, bat, bounce pad, 10 flowers, 8 bushes, 7 trees). Code: `ArtService/PixelPlains.luau`. Still to do: section 3 list below. Target: the rebuilt Pixel Plains grey-box (`Greybox/init.luau` buildPixelPlains) at the approved graphics baseline (memory: graphics-baseline), themed voxel toy-plastic (art-direction.md §8), owner colors only on gameplay targets (§6).

## 1. Blender kit (exact-size pieces) — `blender_assets/PixelPlainsKit2.blend / .fbx`

Built at stud scale, bevelled voxels, one mesh per material, cube-projected UVs, transforms applied. Each asset's pieces share a pivot at its bottom center. **Imported Sep 30.** Mesh ids: Cliff Top 73194612964423, Dirt 132715282506690, Strata 95695557584433, Stones 131737597349680; Wall Bricks 127532238967506, Core 88505239808610, Top 73396039066734; Belt Frame 131185547489554, Belt 104161523408844, Glow 134386850518263. (Original note: needs the user's Import 3D click in Studio (File → Import 3D → `PixelPlainsKit2.fbx`), then read the MeshIds with `execute_luau` and compare bounding boxes (import scale varies, memory: studio-ui-clicks).

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

Retried and done: Static Bat `rbxassetid://138838808176158` / tex `134256509753880` (4.7 × 2.5 × 2.25), voxel tree `rbxassetid://110637086239850` / tex `81380511005138` (12 × 15.9 × 12). Original failures: **Static Bat** ("Moderation failed": reword without "fangs"/"menacing", e.g. "cute round purple voxel bat toy with blocky pixel wings and big googly eyes"), **voxel tree** ("Too Many Requests": run 2–3 generations at a time, not 6).

Still to generate: duo pound button. (Lever, fan, chute, door, signs, hill sign and crayon sun are done: section 4.)

## 3. Wiring plan (next session)

1. Import the FBX (user click), read ids, fill `Skins` entries in `ArtService/PixelPlains.luau` (MeshAssets.Skin pattern: `Design` + per-piece `Id/Offset/Size/Material/Color`).
2. Enemy skins like `ArtService/StarfallCastle.luau` (`enemy(design, id, tex, size, offsetY, yaw)`); decor via `Decor` (`{ skin, CFrame, scale }`).
3. Surfaces: Studio `generate_material` for a "PixelPlastic" MaterialVariant (glossy toy plastic with fine pixel bumps) and apply to the kit MeshParts, so they are not flat colors (graphics baseline).
4. Playtest + screenshots per section; then environment dressing (trees, flowers, bushes, clouds, coin blocks) along the route, leaving the play space clear (§10).

## 4. Kit 3 + surfaces (Sep 30, 2026, second session) — wired and verified in a Studio playtest

References (Google Images in Brave): stylized wooden signs (uneven planks, big nail heads, posts at the ends poking above), cartoon wooden doors (strap hinges from the hinge side with rounded tabs, ring handle, rivets), cartoon lever switches (chunky base plate with slot, big knob). Shapes only; nothing copied.

**Blender kit 3** `blender_assets/PixelPlainsKit3.blend / .fbx` (imported; ids + offsets in `ArtService/PixelPlains.luau`). Roblox materials give the real surfaces (WoodPlanks / Wood / Metal), owner glow only on the gameplay piece:

| Skin (Design) | Pieces | Notes |
| --- | --- | --- |
| `Sign` (14 × 3 × 0.4) | Planks (WoodPlanks), Battens + nail heads (Wood) | stays thinner than the part so the SurfaceGui text on both faces shows; `Extras` adds `SignPost` skins at both board ends, raycast to the ground |
| `SignPost` (0.9 × 6 × 0.9) | one post | stretched to height |
| `TimedDoor` (8 × 12 × 1.5) | Frame (Neon Kai: freezable), Body (WoodPlanks), Bands (strap hinges, rivets, ring handle) | |
| `PullLever` (1 × 5 × 1) | Base (iron socket, slot, bolts), Shaft (steel), Grip (Neon Miko knob + socket band) | |
| `Chute` (8 × 16 × 8) | Pipe, Bands, Hole | decor over the dropper, pipe top hidden in a cloud |
| `HillSign` (75.55 × 8.79 × 1.6) | "BY KAI + MIKO" pixel letters, cream | decor on a scaled `Cliff` hill west of the meadow, faces the plaza; readable from its −Z side |

Generated: box fan `rbxassetid://75748223101068` / tex `128839206690973` (faces +Z as generated, placed pitched −90° under the jump vent, depth squashed). A generated chute came out as a U-pipe basin, so the chute is Blender-made instead.

**Dropper blocks** (`FallBlock`) get a coin-block cube skin with a Kai-orange Neon edge frame (ArtService dresses parts added to the world later via `DescendantAdded`).

**Textures** (`textures/make_pixelplains.py` makes all of them; re-upload after changes):
- `PixelPlastic` MaterialVariant (near-white glossy plastic, soft 1-stud pixel bevel grid, 8 studs/tile). **Runtime scripts can't set a variant's maps**, so it lives in `adventure.project.json` → MaterialService. Used on flat kit surfaces (grass/dirt/strata, cloud, coin and move blocks, fall blocks); left off bricks, stones, crusher teeth, letters (the grid made them look like chocolate bars). Studio's `generate_material` results were too heavy (black grout, brick patterns) for this palette.
- Belt tread (`PP_BeltTread3.png`, Texture on the belt's top face, U offset 6 centers it): on that face V runs along the belt and +V points back against its LookVector; `BeltController` scrolls −V at the belt's Speed and stops while Frozen.
- Crayon sun (`PP_CrayonSun2.png`): the sky adds the sun on top, so the texture is darkened to land on warm gold; `Worlds` Look `SunTexture` / `SunSize`.

Open: grass flat tops read pale mint at noon (same with the variant off, so it's lighting/haze, not the material); revisit in the environment lighting pass. The Glitch Chase wall is visible from far away across the level.
