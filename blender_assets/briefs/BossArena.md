# Brief: Crusher King throne hall (Pixel Plains boss arena)

**Ask (user, Oct 4, 2026):** the arena is too plain and tight; make it the grandest, most detailed place in Pixel Plains (throne room on a sky island, banners, pillars, voxel castle ruins, tree/flower crowds, a lighting moment). Keep the boss and his attacks as they are. **Pick (Oct 10):** "Throne hall island" (over a voxel colosseum or an enclosed castle courtyard).

**References (Oct 10):** Google Images "voxel castle ruins throne room magicavoxel" (warm sandstone, pointed arches, rows of banners between pillars, light through high windows) and It Takes Two's castle chapter (warm light pools against cool purple shadows, dust in the air, huge scale contrast). Shape and mood only.

**Direction:** the 6×7 fight floor + the king's rock are the raised dais of a ruined royal hall. Everything else stands 34 studs lower (under the 25-stud void line: never a landing or a safe spot) on a U of grass island terraces. Same voxel language as the PP trees (memory voxel-style-pp): grid voxels, only exposed faces, toon shading baked per face. Royal purple + gold = the king's robe colors; the Glitch's magenta static only where it eats a banner. No owner colors as decoration.

**Pieces** (`tools/boss_arena/kit.py`, atlas `textures/arena_palette.png` from `make_arena_palette.py`; FBX `BossArena.fbx`, gate redone in `BossArenaGate.fbx`):

| Piece | Size (studs) | Voxel | Notes |
| --- | --- | --- | --- |
| BA_Pillar / Broken / Stump | 12×75×12 / 52 / 27 | 1 | plinth, chamfered fluted shaft, bands, capital with gold band, ivy flush on the shaft |
| BA_Lintel | 28×7×8 | 1 | across pillar pairs, dentils, gold inlay, hanging ivy |
| BA_Banner / BannerTorn | 12×32×3.5 | 0.5 | gold rod on two iron arms (+Z, back to the pillar), border, stripe, pixel crown, swallowtail; torn = holes + Glitch static |
| BA_BackWall | 84×136×12 | 2 | rose window over his crown, two lancets, buttresses, collapsed end (Roblox −x), ivy curtains |
| BA_Tower / TowerBroken | 26×154×28 / 108 | 2 | corbelled walk, arrow slits, plum slate cone + pennant |
| BA_Gate | 32×41×8 | 1 | arch on the chase landing (posts collide), crown ON the arch (inside the opening it hid the king) |
| BA_Carpet, Rubble1/2, Brazier | | 0.5–1 | runner to the first row, fallen drums, braziers with small warm flames |

**Placement:** `bossHall` in `src/adventure/server/Services/ArtService/PixelPlains.luau` (section-local numbers measured from the BossTrigger). Sun shafts: Beams along the measured PP sun direction (−0.672, 0.672, 0.313) through the gaps of the sunny colonnade onto the floor (`textures/godray.png`); faint during the fight, gold once `Played`.
