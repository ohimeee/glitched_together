# Brief: Prologue title-screen set (UI panel, giant menu button, title card)

**Status (Sep 30, 2026): done and in the game.** Files: `blender_assets/PrologueUI.blend` / `.fbx`. Code: `src/adventure/server/Services/ArtService.luau` (mesh ids + which grey-box part gets which skin) puts non-colliding MeshPart "shells" over the grey-box parts; the parts keep collision, tags and SurfaceGuis and just turn invisible. Verified in a Studio playtest: all 16 Prologue panels/buttons/title card skinned, PipModel published, Pip floats over the player.

Import note: this FBX came into Studio uniformly scaled ×0.611 (Pip came in 1:1), so the sizes in `ArtService` are normalized back to design size. Always read ids *and* check the bounding box against the design size after an import.

Panel bodies use a lighter slate navy `#2E3670` instead of `#14183A`: the darkest navy vanished against the Prologue's night sky.

**Where:** Prologue (the broken *Starfall Kingdom* title screen, Story Line → Prologue). Players hop across giant menu buttons, cross floating UI panels and start at a big "CONTINUE?" card.

## References looked at (Sep 30, 2026, Google Images in Brave)

| Search | Useful | Avoid |
| --- | --- | --- |
| "3d giant game menu buttons platform level stylized" | Candy/glossy 3D game buttons: rounded rect, a thick **darker bottom lip** under a lighter cap, one soft highlight. Reads "press me" instantly | Wood/stone fantasy buttons (castle world, not here), busy icon sets |
| "stylized 3d level floating ui panels platforms title screen game concept" | Sci-fi HUD panels: dark slab with a crisp light edge line; floating islands as stepping stones | Thin, flat, zero-thickness panels (need volume to stand on) |
| "3d render glitch pixel corruption game title card sign" | Glitch = blocky pixels breaking off edges, horizontal slices, RGB split | Noise/static textures (animate glitch in Roblox instead) |

## Direction

Everything is "UI turned into chunky toy geometry", palette from BLENDER_PLAYBOOK §4 Prologue: navy `#14183A`, UI white `#F0F0FA`, glitch pink `#FF50AA`.

| Asset | Design size (studs) | Pieces (one per Roblox material) | Tris |
| --- | --- | --- | --- |
| `PR_UIPanel` | 20 × 4 × 20 | `_Body` navy slab (rounded corners r 2.2, soft bottom bevel) · `_Trim` white edge band just under the top | 332 + 448 |
| `PR_MenuButton` | 10 × 4 × 10 | `_Base` navy lip · `_Cap` white puffy keycap (top flush with the collider top) | 332 + 276 |
| `PR_TitleCard` | 30 × 10 × 1 | `_Frame` white rounded frame · `_Screen` navy inset (text stays a SurfaceGui on the grey-box part) · `_Glitch` pink pixels breaking off two corners | 672 + 108 + 108 |

Each asset's bounding box equals its grey-box part, so `Skins.Apply(part, name)` just scales by `part.Size / DesignSize`. The panel is used for every navy Prologue platform (12 × 4 × 12 up to 44 × 4 × 44); the rounded corners stretch a little on non-square panels, which reads fine at these sizes.

## Pip (same import batch)

`blender_assets/Pip.fbx` re-exported split by material (Roblox MeshParts have one color): `Pip_Body`, `Pip_Face` (eyes + mouth), `Pip_Cheek`, `Pip_Wing`, `Pip_Star`, `Pip_Antenna`; 644 tris, watertight. `ArtService.Init` builds `ReplicatedStorage.PipModel` (with a small warm PointLight so Pip reads in dark worlds); `PipController` (client) clones it, floats it between the duo facing the camera, and flies it to your shoulder for `Tuning.Pip.HintTime` when a hint arrives. Numbers in `Tuning.Pip`.
