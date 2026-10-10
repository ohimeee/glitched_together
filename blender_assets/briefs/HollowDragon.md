# Brief: The Hollow Dragon (World 2 boss)

**v2 (current, Oct 10, 2026):** the user found the scripted v1 below ugly and stiff and picked the Sketchfab **Celestial Dragon** by achrefrhm9 (CC BY 4.0, credited in CREDITS.md) over Starry Skies' Dragon and the red Stylized Dragon. Second head (AI artifact) removed on the user's call; split into body + wings; repainted plum with magenta static stars (`textures/make_hollow_dragon_tex.py`); hovers over a hole in the hall. Files `blender_assets/HollowDragon2.*`, skins `DragonBody/WingL/WingR` in ArtService/StarfallCastle.

---

**v1 (replaced):**

**Pick (user, Oct 10, 2026):** "Hollow storybook" (over a kid-drawing papercraft dragon or a stone-and-iron one).

**References (Oct 10, Brave/Google Images):** skeletal bone dragons with an exposed glowing heart, It Takes Two's Dungeon Crawler (the top-down mage + knight chapter our castle mirrors: warm light against deep shadow, chunky readable shapes), kid-drawing dragons made into 3D toys (big horns, big wings). Shape and mood only.

**Direction:** the dragon Kai and Miko drew as the castle's final boss: plum scales (DragonScales hide), gold dorsal ridge and wing claws, bone horns/teeth/claws, magenta Glitch eyes; its chest is eaten hollow (boolean cavity + magenta static shards) round the glowing heart (the phase-3 target). Seen top-down from the door side (the fight flips the castle camera), so the silhouette is horns + ridge + spread wings; the four flank scales (Kai's targets, Kai orange) show when the wings lift during a breath.

**Build:** `tools/hollow_dragon/kit.py` (Blender Skin-modifier tubes for trunk/legs/neck/head/tail, cones for spikes/horns/claws/teeth, solidified membranes with torn holes on the right wing), modeled in the boss pivot's space and split per grey-box part (`HD_<Part>_<Surface>`); `report()` gives each mesh's size + offset = the skin numbers in `ArtService/StarfallCastle.luau` (DRAGON). Hide: `textures/make_dragon_scales.py` (tileable roof-tile scales, color/normal/roughness) → MaterialVariant `DragonScales` in adventure.project.json.

**Tripo:** not used. The free web plan shows "Upgrade to unlock 3D model exports", so a generation (55 credits) couldn't be downloaded.
