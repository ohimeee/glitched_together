# Brief: Pixel Plains kit + role badges

**Status (Sep 30, 2026): in the game.** Files: `blender_assets/PixelPlains.blend/.fbx`, `blender_assets/Identity.blend/.fbx`. Code: `src/adventure/server/Services/ArtService/PixelPlains.luau` (skins, dressing, decor), `ArtService/Badges.luau`. Verified in a Studio playtest: all 9 grey-box parts skinned, 9 decor pieces placed, moving shells stay welded to their movers, Kai wears the ▲ badge.

## References (Sep 30, 2026, Google Images in Brave)

| Search | Took | Avoided |
| --- | --- | --- |
| "voxel grass block platform stylized game asset dripping grass edge" | Thick grass cap with **stepped pixel drips** down the dirt sides; a few darker dirt pixels | Minecraft's exact block texture and proportions |
| "stylized 3d crusher … block hazard platformer" | Heavy slab, side ridges, readable teeth underneath | Nintendo's Thwomp face and spikes (no face on ours; red warning blocks instead) |
| "voxel cloud magicavoxel low poly" | Stacked, stepped boxes with soft edges | Smooth puffy clouds (wrong world) |

## Direction (art-direction.md §8 Pixel Plains, §6 reserved colors, §17 metrics)

1-stud voxels with a small bevel so everything reads as plastic toys. Palette §16: grass `#5BD15B`, dirt `#B5773F`, coin gold `#FFC83D`, cloud white. Gameplay pieces wear their **owner's** color (on Neon, via `Palette.Glow`, because Neon washes orange into yellow):

| Asset | Design (studs) | Pieces | Tris | Owner color |
| --- | --- | --- | --- | --- |
| `PP_Kit_GrassBlock` | 20 × 6 × 20 | Top (cap + voxel drips), Dirt, Spots | 3,384 + 108 + 144 | — |
| `PP_Kit_MoveBlock` | 10 × 2 × 10 | Body (cream), Frame | 108 + 528 | Kai orange frame (freezable) |
| `PP_Prop_Crusher` | 9 × 8 × 12 | Body, Hazard (danger red), Teeth, Frame | 196 + 352 + 1,120 + 176 | Kai orange frame (freezable) |
| `PP_Prop_GrappleRing` | 1 × 3 × 3 (axis X) | one octagon ring | 64 | Miko teal |
| `PP_Prop_Crate` | 4 × 4 × 4 | Wood, Edge, Handle | 44 + 528 + 176 | Miko teal handles (pullable) |
| `PP_Prop_Cloud` | 22 × 8 × 7 | one mesh (decor) | 756 | — |
| `PP_Prop_CoinBlock` | 4 × 4 × 4 | Body, Frame, Mark (white pixel **star**, not a "?") | 108 + 528 + 1,056 | — |
| `SH_Prop_Badge` | 1.8 plate | Plate (white), Tri (Kai), Circle (Miko) | 284 + 80 + 236 | Kai orange ▲ / Miko teal ● |

The grass block is over the 2k kit guideline because every drip is its own bevelled voxel (the seams are what sell the toy look); it is one shared mesh reused per platform, so the cost is small.

## Pipeline notes

- Offsets and sizes in the data modules are **generated in Blender** (object bbox center relative to the asset's design box, mapped Blender (x, y, z) → Roblox (−x, z, y)). After an import only the MeshIds are copied; the importer's auto-scale (this batch came in fitted to 2048) doesn't matter.
- Moving or pullable parts (tags `Mover`, `Pullable`, or unanchored) get **welded, unanchored, massless** shells so they ride along.

## Next

- Crusher side walls and other plain grey-box pillars: a stone/dirt pillar kit piece.
- Pixel flowers, "START →" sign and the "BY KAI + MIKO" hill sign (kid details, §8).
- Enemies: Glitch Blob with googly eyes, Static Bat.
