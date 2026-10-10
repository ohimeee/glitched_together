# Brief: The Unfinished (final boss, World 3) + its morphing stage

User picks (Oct 10, 2026, 18th session): **Morphing stage** layout (over Crusher-style rooms / a tower) and a **new Sketchfab hero** body: "Meteor Golem - Cosmic Rock Creature" (s8819296, CC BY 4.0, CREDITS.md), picked from 3 opened in Brave (Ricky The Golem, Inferno Golem were the others).

## Body (done)
- Source: Tripo-made Sketchfab model, 1.88M tris, one 4K PBR material, 19 arbitrary chunks.
- Joined, decimated 0.08, split by region into `UF_Torso` (18k, incl. head + shoulder plates), `UF_ArmL`/`UF_ArmR` (10k each, shoulder to fist), `UF_LegL`/`UF_LegR` (8k), `UF_Rock` (1.5k, the floating chunk by its head). 55.5k tris total.
- 50 studs wide (arms), 22 deep, 49.5 tall at Blender 1 unit = 1 stud. Faces Blender −Y (→ Roblox −Z after import). L/R = Blender +x / −x.
- Texture: `textures/make_unfinished_tex.py` → `unfinished_color.png` (icy-blue seams → Glitch magenta #FF2BD6 because blue sat next to Miko's teal; rock plates → neutral primer grey). Uploaded: `rbxassetid://72059496177930`. Rough/metal/normal maps saved beside it (unused for now, like the dragon).
- Files: `blender_assets/Unfinished.blend`, `Unfinished.fbx`.
- Joints (Blender coords, for the boss module): shoulders ≈ (±12.5, 0, 31), hips ≈ (±7, 0, 18), chest core ≈ (0, −9, 33).

## Stage (to build)
One round grey-primer scale-model stage over the Core void after Memory 3 (r ≈ 55), the golem at the far (+Z) rim standing on a plinth below the stage edge so its chest is ~25 above the floor. Each phase the stage's top dressing swaps (the colliders stay):
1. Pixel Plains: voxel grass tiles + a few voxel trees on the rim; follow camera, Pause Beam / Grapple Line.
2. Castle: flagstones, braziers; top-down (TopDownFlip, the golem at the top of the screen), Fire Mage / Shield Knight.
3. Core: pencil grid, primer; Copy/Paste / Layer Shift. Damage does nothing.
4. Same kit, no combat: 6 empty slots light up on the rim, SAVE button rises in the middle.
Transitions: a static wipe (magenta/cyan checker flash) across the stage while the dressing swaps.

## Fight (mechanics.md §5, The Unfinished)
1. **Static King** (PP kit): fists slam at alternating targets (Crusher King rhythm); Kai freezes a resting fist, Miko grapples up onto it and pounds the wrist crystal; 3 crystals (both wrists + back of a hand again) = phase.
2. **Static Dragon** (castle kit): breath beam from its head at one player (shield blocks, as the Hollow Dragon); between breaths the chest core opens: only reflected fireballs count (4).
3. **True form** (Core kit): every hit shows it doing nothing; ~15 s of slow sweeps, then Pip's line "It's not a monster. It's the level you never finished." → phase 4.
4. **Finish it** (Core kit, no damage): 6 level pieces hidden in the Code Layer around the stage; Miko pulls one out, Kai copies it and pastes it into its glowing slot; each filled slot calms the golem (attacks slow, seams fade magenta → warm gold). Last: the giant SAVE button; both ground-pound within 0.5 s → the golem becomes the finished level (stars over the kingdom), ending.
