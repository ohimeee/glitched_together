# Brief: Lobby capsule pair

**Status (Sep 30, 2026): first pass modeled, not yet reviewed or imported.** Files: `blender_assets/LobbyCapsule.blend` (objects `LobbyCapsule`, `Capsule_Emblem_Tri`, `Capsule_Emblem_Circle`, `Capsule_Marquee`, plus `LobbyCapsule_MikoPreview` for looks only) and `LobbyCapsule.fbx` (the four real objects). Capsule 9.8 × 9.4 × 13.5 studs, **4,852 tris (over the 3k budget)**, marquee 212 tris. Materials `Cap_Plastic_Role` / `Cap_Glow_Role` are Kai orange placeholders, recolor per role in Studio. Next: refine (fewer segments, check silhouette from the lobby camera), then import.

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
