# Brief: Lobby capsule pair

**Status (Sep 30, 2026): done and in the game.** Files: `blender_assets/LobbyCapsule.blend` and `LobbyCapsule.fbx`. Imported with Studio's 3D importer (meshes uploaded to the account); ids and offsets live in `src/lobby/server/CapsuleMeshes.luau`, and `LobbyBuilder` creates the MeshParts at runtime with `AssetService:CreateMeshPartAsync` (grey-box fallback if a mesh fails to load). Verified in a Studio playtest: all 6 pairs build, player walks in and out of the door, stands on the floor, back glass blocks, stepping in sets `Role = Kai` and the screen shows "WAITING FOR MIKO". If the FBX is re-exported, re-import it and update the ids in `CapsuleMeshes.luau`.

### What's in the file (second pass)

Laid out in the **pair frame** that `LobbyBuilder` uses: Kai capsule centered at x = −6, marquee at x = 0, Miko preview at x = +6. Front (open door) = Blender **−Y**. 1 BU = 1 stud.

One object per Roblox material zone, so each MeshPart gets its own Material/Color in Studio and both roles share the same meshes:

| Object | Tris | Roblox look | Notes |
| --- | --- | --- | --- |
| `Capsule_Base` | 284 | SmoothPlastic, navy `#14183A` | Plinth, r 4.8, 0 → 0.55 |
| `Capsule_Frame` | 700 | SmoothPlastic, white `#F0F0FA` | Floor disc (top at 0.9), 2 door-jamb pillars + 1 back pillar, rim band 9.8 → 11.2 |
| `Capsule_Glass` | 132 | Glass, role color, Transparency ~0.4 | 240° shell (back + sides), 0.14 thick; front 120° open (≈5.8 studs clear between jambs) |
| `Capsule_Glow_Role` | 384 | Neon, role color | Floor ring + ceiling ring (add a PointLight/SpotLight in Studio for the "light column") |
| `Capsule_Dome_Role` | 286 | SmoothPlastic, role color | Squashed dome, top at 13.9 |
| `Capsule_Knob_Role` | 296 | SmoothPlastic, role color | Gachapon twist knob on the rim. Modeled on Kai's **outer side (−X)**; for Miko place it on +X (rotate 180° about up) |
| `Capsule_Emblem_Tri` | 80 | SmoothPlastic, white | Kai ▲ crest standing on the dome, faces front |
| `Capsule_Emblem_Circle` | 284 | SmoothPlastic, white | Miko ● crest (placed on the Miko preview at x = +6) |
| `Marquee_Frame` | 188 | SmoothPlastic, white | 9 × 1.4 × 4.2 frame, bottom 14.4, recessed front, two legs resting on the domes |
| `Marquee_Screen` | 12 | SmoothPlastic, navy | Sits in the recess; put `SurfaceGui.Status` on its **front** face (or keep the `Screen` Part there) |
| `Marquee_Glitch` | 84 | Neon, pink `#FF50AA` | Razor-edged "missing pixel" cubes breaking out of two corners |

Capsule = **2,082 tris** (+80 with ▲, +284 with ●), marquee 284. All watertight, transforms applied, capsule parts share the pivot at the capsule's bottom center; marquee parts share a pivot at the bottom of the legs. `*_MikoPreview` objects (teal materials) are for looks only and are not exported.

**In Studio:** the importer brought it in at 100× (FBX cm) and mapped Blender (x, y, z) → Roblox (−x, z, y), so the door (Blender −Y) faces Roblox −Z as `LobbyBuilder` expects; `CapsuleMeshes.luau` stores sizes already divided by 100. Collision: Frame and Glass use PreciseConvexDecomposition (keeps the doorway open), Base/Dome/Marquee Hull, rings/crests/knob/glitch/screen don't collide. Each capsule keeps an invisible `Zone` (6.5 × 8 × 6.5 at y = 5) and the pair's `Screen` (the Marquee_Screen mesh) carries `SurfaceGui.Status`. A transparent `Sign` part on the rim shows "▲ KAI" / "● MIKO"; a PointLight in the glow rings lights the inside. Neon glow color is the role color darkened 30% (full orange blows out to yellow).

**Changes from the first pass:** 4,852 → 2,082 tris; origin was 0.4 above the bottom; 40 non-manifold edges (zero-thickness glass) fixed; ▲ emblem lay flat on the dome and couldn't be read, now both emblems are upright crests that flank the marquee (▲ [SCREEN] ●); marquee had no supports, now has legs; loose `Cube.00x` glitch pixels merged into `Marquee_Glitch`; 5-pillar "birdcage" cut to door jambs + back pillar so the glass reads.

**Where:** Lobby platform, 6 pairs (implementation.md §2). Replaces the grey-box `KaiCapsule` / `MikoCapsule` / `Screen` parts from `src/lobby/server/LobbyBuilder.luau`.

## References looked at (Sep 30, 2026, Google Images via Brave)

| Search | What was useful | What to avoid |
| --- | --- | --- |
| "stylized sci-fi capsule pod concept art game" | Cylindrical glass tube on a chunky base, glowing liquid/light inside, cap on top (cryo pods, healing chambers). The round pod shape reads as "step in here" instantly | Gritty, greebled, military detail; horror tank vibes |
| "cute stylized teleporter pad game asset pixar style" | Round stepped base with a glowing ring on the floor. The ring is the clearest "stand here" signal | Stone/rune fantasy teleporters (wrong world) |
| "stylized capsule booth two player select arcade concept" | Two-player arcade cabinets: side-by-side identity, one shared screen above. That's exactly our pair layout. A real "Giant Capsule Station" (giant gachapon) looked great | Busy licensed artwork |
| "stylized 3d gachapon capsule machine low poly" | Toy gachapon: a round clear dome on a body, big twist knob, candy pastel plastic. Fits "a game we made as kids" and Pip's toy look | Realistic vending machines with many small windows |

## Direction

**"Toy arcade teleporter":** each capsule is half **gachapon capsule** (round clear dome, plastic body, twist knob), half **teleporter pod** (glowing floor ring, light column inside). A pair shares an arcade-style marquee screen on top: "STEP IN TO PLAY", "LOCKING IN… 3".

- **Silhouette:** rounded pill shape, open front (players walk in), dome cap. Chunky, bevelled, oversized; readable from across the platform.
- **Size:** inside space ~7 × 8 × 7 studs (player ~5 studs tall). Capsule outer ~9 wide, ~13 tall with cap. Pair spacing 12 studs center to center; marquee ~12 × 4 above.
- **Identity:** Kai capsule orange `#FF8C28` with ▲ triangle emblem on the cap; Miko capsule teal `#28D2C8` with ● circle emblem. Shared parts in UI white `#F0F0FA` and navy `#14183A`; pink `#FF50AA` glitch accent trim.
- **Materials:** glossy plastic body (roughness ~0.35), clear glass half-shell at the back/sides (Roblox Glass), emissive floor ring and inner light column in the role color, a big twist knob on the side (decorative).
- **Glitch touch:** 2–3 small pixel "missing chunks" on the marquee edge in magenta/black.

## Build plan

1. Blender, 1 BU = 1 stud: `Capsule_Base` (stepped disc with ring groove), `Capsule_Shell` (open-front half cylinder + dome cap), `Capsule_Knob`, `Capsule_Emblem_Tri`, `Capsule_Emblem_Circle`, `Capsule_Marquee` (frame only; text stays a SurfaceGui in Roblox).
2. One neutral-colored mesh set; recolor per role in Studio (MeshPart.Color / separate emissive ring part) so Kai and Miko share geometry.
3. Budget: under 3k triangles per capsule.
4. Export `blender_assets/LobbyCapsule.fbx` → Studio → keep the invisible `Zone` part and `Screen.SurfaceGui.Status` label so `Capsules.server.luau` keeps working.
