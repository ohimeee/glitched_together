# Glitched Together — Art Direction

**One-line theme:** *A game two kids made, seen from the inside.*

Every world, prop, color and effect should feel like something Kai and Miko imagined when they were 12, now made real and slowly falling apart. The Glitch is the only thing that ever looks wrong.

> **Graphics baseline (approved Sep 30, 2026):** stylized but believable, close to It Takes Two: rounded, slightly exaggerated shapes with real-feeling, textured surfaces (aged bone, worn leather, scratched metal, fabric). Not flat-colored primitive "toy" builds. Characters, enemies, bosses and organic props are made with Roblox Studio's AI mesh generator (textured) and themed per world (§8); Blender is for exact-size kit pieces, which must also get real surfaces. The Starfall Castle enemies are the reference.

Companion files: `design.md` (why the game plays this way) · `mechanics.md` (numbers) · `implementation.md` (how to build it). This file is about **how the game looks and feels**, and how to build its 3D assets in Blender (§16–18).

---

## 1. What we take from It Takes Two's look

| It Takes Two does | Glitched Together does |
| --- | --- |
| Pixar-inspired look: stylized scale and shapes without losing realism | Stylized, chunky shapes with believable materials (stone feels like stone, pixels feel like plastic blocks) |
| Aims to be lively, vibrant and **inviting**, because a huge world can feel intimidating | Bright, friendly, never dark for long; even the castle is warm, not scary |
| Familiar things at a new scale: the family's house, shed and garden seen at doll size | Familiar game things at a new scale: a title menu you can walk on, a giant pixel king, a castle drawn from a kid's notebook |
| Each chapter's world reflects the relationship at that point in the story | Each world's colors and light follow the friendship: cold and distant → warm → broken → whole |
| Two visual registers: a grounded real world and exaggerated, theatrical fantasy | Real-world scenes (bedrooms, cutscenes) are soft and muted; game worlds are saturated and bold |
| Expressive, theatrical characters so players bond with them | Big readable poses and faces, visible from far away and from a top-down camera |
| Clarity and innocence, like Nintendo and Pixar | Everything readable in one second; nothing grim or gory |

**What we don't copy:** It Takes Two's characters, doll designs, household environments, props, textures, UI, fonts or screenshots. We copy the *principles*, not the pictures.

---

## 2. Visual pillars

### Pillar 1: Made by two kids
The worlds are a mix of both friends' imaginations, and players should be able to *see* whose idea was whose.

| | Kai's side (the storyteller) | Miko's side (the builder) |
| --- | --- | --- |
| Signature color | **Orange** | **Teal** |
| Shapes | Stars, arches, flags, maps, runes, neat straight lines | Blocks, gears, springs, bolts, chunky rounded forms |
| Details | Hand-drawn map labels, lore scrolls, star doodles | Scribbled "TEST ME!" stickers, arrows, measurements, duct tape |
| Where you see it | Signs, banners, story props, the castle | Platforms, machines, traps, Pixel Plains mechanics |

Sprinkle childhood "tells" everywhere: marker doodles on walls, notebook-grid patterns on floors, sticker labels on props, spelling mistakes on signs ("DANJER"), a crayon sun in the sky. These make the world feel handmade and personal.

### Pillar 2: Stylized, not simplified
Big, chunky, slightly exaggerated shapes, with real-feeling surfaces. Use Roblox Materials and MaterialVariants with care (wood grain, brushed metal, stone) so the world looks crafted, not like default grey parts. Avoid thin, fiddly detail: it disappears on mobile and from the top-down camera.

### Pillar 3: Readable in one second
The player must always know three things at a glance: **where to go, what they can use, and what hurts.** Gameplay colors are reserved (see §6) and never used for decoration. Backgrounds are lower contrast than the play space. Important objects get a clean silhouette against their background.

### Pillar 4: Every world has a feeling
Color and light follow the story (see §3). The player should *feel* the friendship change before any dialogue says it.

### Pillar 5: The Glitch is the only thing that looks wrong
Everything in the kids' game is warm, round and handmade. The Glitch is the opposite: flat, cold, sharp, flickering, broken. Because nothing else in the world looks like that, players read it as danger instantly.

### Pillar 6: Inviting, even when it's scary
Like It Takes Two, keep danger fun rather than frightening. Enemies are goofy-menacing (a skeleton with a crooked grin, a slime with googly eyes). Dark rooms always have a warm light source to aim for.

---

## 3. Color script (the emotional arc)

| Part | Emotion | Dominant colors | Saturation | Light | Key image |
| --- | --- | --- | --- | --- | --- |
| Real world (opening) | Lonely, distant | Cold blue night, screen glow | Low | Dim, one light source per room | Two dark bedrooms, two glowing screens |
| Prologue: Title Screen | Awkward, stuck | Navy, white UI, pink glitch accents | Medium | Flat menu light | Two tiny players on a giant, broken "PRESS START" |
| World 1: Pixel Plains | Forced teamwork, bickering | Grass green, sky blue, coin gold | High | Bright noon, hard shadows | A crown-wearing pixel king over blocky hills |
| World 2: Starfall Castle | Old memories, first warmth | Deep purple, torch orange, gold | Medium-high | Night interior, warm pools of torchlight | Mage and knight back to back in a torchlit hall |
| World 3: Glitched Core | Truth, hurt, honesty | Grey, black, with sharp magenta and teal | Low (except glitch accents) | Cold, flickering | A half-built wireframe world with pieces of the earlier worlds floating in it |
| Final level (completed) | Repaired, whole | Every world's colors together under a starry sky | Highest in the game | Soft, warm starlight | The finished kingdom under shooting stars |
| Real world (ending) | Hopeful | Warm lamp orange + night blue | Medium | Warm, two lights on | The two split screens merging into one frame |

**Rules for the arc**
- Warmth grows across the game. The first truly warm light the players see is the castle's torches.
- Orange (Kai) and teal (Miko) appear separately early on and start appearing *together* in the same props as the story heals. The final level uses both in almost everything.
- World 3 drains color on purpose so the final completed level feels like a burst of joy.

---

## 4. Shape language

| Thing | Shapes | Feeling |
| --- | --- | --- |
| Kai | Tall rectangles, straight lines, stars | Careful, guarded, thoughtful |
| Miko | Circles, rounded blocks, springs | Loud, energetic, friendly |
| Pip | A perfect pixel circle with a few missing pixels | Cute, unfinished |
| Friendly world props | Rounded corners, thick outlines, soft bevels | Safe, handmade |
| Enemies | Rounded bodies with one sharp feature (teeth, spikes, blade) | Goofy but dangerous |
| The Glitch | Jagged triangles, broken edges, flat untextured planes, checkerboard "missing texture" | Wrong, cold, broken |

Test: squint at a screenshot. You should still be able to tell friendly (round) from dangerous (sharp) from glitched (jagged and flat).

---

## 5. Characters

### Kai and Miko
- **Silhouette first.** Each must be recognizable as a black shape, from the side *and* from the top-down castle camera. Kai: taller, hood up, scarf that trails behind. Miko: shorter, big jacket collar, ponytail and oversized goggles on her head.
- **Signature color on every outfit.** Whatever the world skin, Kai always has clear orange somewhere and Miko always has teal. Players should never lose track of who is who.
- **Outfits per world** (their appearance changes with the world, like their tools do):

| World | Kai | Miko |
| --- | --- | --- |
| Prologue | Real-world hoodie, jeans, sneakers | Real-world jacket, shorts, sneakers |
| Pixel Plains | Blocky pixel-textured version of his clothes | Blocky pixel version of hers, with a grapple belt |
| Starfall Castle | Fire Mage: star-patterned robe, pointed hat, orange trim | Shield Knight: rounded armor, big round shield, teal cape |
| Glitched Core | Real clothes again, flickering at the edges | Real clothes, with teal wireframe goggles for Layer Shift |
| Final level | A mix: hoodie with a small mage star pin | Jacket with a small knight shield patch |

- **Expressive faces and big poses.** It Takes Two made its characters' bodies and faces extra theatrical in fantasy scenes so players bond with them. Do the same: exaggerated idle animations (Kai crosses arms, Miko bounces), big reaction poses, clear eye direction in cutscenes. If Roblox dynamic (animated) heads fit your rig, use them for cutscene expressions.
- **Proportions:** slightly larger heads and hands than realistic, for readability. Keep proportions identical between the two so their tools and animations share rigs.

### Pip
A floating, glowing pixel sprite about the size of a character's head. A few pixels are always missing, and it "fills in" slowly across the game. Its glow color matches whoever it's talking to (orange for Kai, teal for Miko, white for both).

### Enemies
Every enemy is something a kid would draw for their first game: simple body, one gimmick, googly or dot eyes. When enemies are infected by The Glitch, they get the Glitch treatment (§7) on top.

### Bosses
Bosses are built at **huge scale** so the players feel tiny, the way It Takes Two uses scale. Each boss is the "best drawing" of its world: the Crusher King is the most detailed pixel art in Pixel Plains; the Hollow Dragon is the grandest thing in the castle.

---

## 6. Gameplay color language (reserved colors)

These colors mean one thing each, everywhere. They are **never used for decoration.**

| Color | Meaning |
| --- | --- |
| **Orange glow + icon** | Kai can use this (freeze targets, burnable objects, copyable objects) |
| **Teal glow + icon** | Miko can use this (grapple rings, pullables, Code Layer wireframes) |
| **White glow** | Both players are needed here (Duo Gates, Duo Pound buttons, Heavy Levers) |
| **Yellow** | Neutral interactable anyone can use (single pressure plates, doors, checkpoints) |
| **Red** | Damage, danger, enemy attacks, attack warning circles on the ground |
| **Magenta + static** | The Glitch, and only The Glitch |

**Owner colors are a co-op tool.** "The orange things are yours, the teal things are mine" gives players an instant shared language, and they naturally call out to each other ("there's an orange one above you!").

Each target also has an **icon** so the color is never the only signal (for colorblind players): pause symbol (freeze), flame (burn), clipboard (copy), ring (grapple), hand (pull), two hands (duo).

> **Note:** this replaces the per-tool target colors listed in `design.md` §5 (blue, orange, yellow, cracked wood, white, green). Update that line to point here.

---

## 7. The Glitch visual language

The Glitch looks the same in every world:

- **Static:** animated black-and-white noise texture on surfaces.
- **RGB split:** edges offset into magenta and cyan fringes.
- **Missing texture:** magenta-and-black checkerboard on "unfinished" surfaces.
- **Broken geometry:** flat, sharp, untextured planes; floating vertices; parts slightly out of place.
- **Motion:** stutters and small position jumps, never smooth movement.
- **Sound:** always paired with a short digital crackle, so players hear it before they see it.

**Spread levels** (use these to show how corrupted an area is):

| Level | Look |
| --- | --- |
| 1: Touched | Occasional flicker, a few checkerboard patches |
| 2: Infected | Static on surfaces, RGB edges, props jittering |
| 3: Consumed | Area mostly grey and flat, geometry breaking apart, color drained |

As the players complete each world, the areas they cleared **heal back** from Glitch level to full color in the end-of-world scene. That is the visual reward.

---

## 8. World style sheets

### Prologue: The Title Screen
- **Feel:** a giant, empty menu floating in the dark.
- **Build:** huge floating UI buttons as platforms ("NEW GAME", "OPTIONS" slider, "LOAD GAME"), a giant logo of *Starfall Kingdom* in kid handwriting, a cursor as big as a house.
- **Materials:** smooth plastic (buttons), neon (button edges), glass.
- **Lighting:** dark navy sky, soft glow from the buttons only.
- **Glitch level:** 1 at start, 3 during the escape.

### World 1: Pixel Plains
- **Feel:** the first level they ever built; bright, blocky, playful.
- **Build:** block terrain with stepped edges, "?"-style coin blocks (our own design, with a star not a question mark), chunky clouds, pixel flowers, conveyor factories.
- **Materials:** smooth plastic and SmoothPlastic with pixel-pattern textures, bright fabric for flags.
- **Lighting:** noon sun, strong shadows, blue sky, light atmosphere haze for depth.
- **Kid details:** hand-painted "START →" signs, a crayon sun on the skybox, a "BY KAI + MIKO" sign carved into a hill.
- **Side-on sections:** keep backgrounds simple and lower contrast, like a classic platformer.

### World 2: Starfall Castle
- **Feel:** a castle from a kid's fantasy notebook; grand but cozy.
- **Build:** stone halls with oversized arches, banners with star crests, stained glass in orange and teal, bookshelves in the Dark Library, a throne hall with a starry ceiling.
- **Materials:** slate and cobblestone, wood, fabric banners, gold trim, glass.
- **Lighting:** night interior; warm torch pools against cool purple shadows. Every room has one bright warm focal light.
- **Top-down rules:** floors carry the design (patterned tiles, rugs, paths), since players mostly see the ground. Walls are short enough not to hide players; use cutaway walls near the camera. Enemies and hazards must be readable from above (red attack circles on the floor).
- **Kid details:** doodled knight drawings as tapestries, a "NO DRAGONS ALLOWED" sign, Miko's secret hidden room decorated completely differently (teal, messy, personal).

### World 3: Glitched Core
- **Feel:** the level they never finished; half-built, honest, a little sad.
- **Build:** grey untextured blocks, wireframe outlines where things "should" be, floating chunks of Pixel Plains and the castle, placeholder signs ("TODO: ADD BOSS"), unfinished doodles.
- **Materials:** default-looking grey (on purpose), neon wireframes, glass.
- **Lighting:** cold, dim, flickering. The only strong colors are Glitch magenta and Code Layer teal.
- **Code Layer (Miko's view):** everything real desaturates, and hidden objects appear as bright teal wireframes with scanlines.
- **Memory Lane:** broken copies of earlier worlds at Glitch level 2, so players recognize them and feel how far they've come.

### Final level (completed)
- **Feel:** everything they imagined, finally finished.
- **Build:** Pixel Plains hills, the castle and the core pieces all fitted together into one kingdom, under a huge starry sky with shooting stars.
- **Lighting:** soft warm starlight, gentle bloom, full saturation.
- **The SAVE button:** giant, white (both players), glowing; it's the brightest object in the scene.

### Real world (cutscenes)
- **Feel:** grounded, quiet, real. The "realistic" register, like It Takes Two's real-world scenes.
- **Build:** two bedrooms with personal clutter (posters of their old game, sticky notes, a photo of the two of them as kids turned face down in Kai's room).
- **Lighting:** cold screen glow at the start; warm lamp light at the end.

---

## 9. Lighting and post-processing (Roblox starting values)

Use `Lighting.Technology = Future` where performance allows; test on mobile. Each world gets its own Lighting preset, swapped by `WorldService`.

| World | ClockTime | Ambient | ColorCorrection | Bloom | Atmosphere |
| --- | --- | --- | --- | --- | --- |
| Prologue | 0 (night) | Dark navy | Saturation −0.1, slight blue tint | Medium (buttons glow) | None |
| Pixel Plains | 12 | Light blue-grey | Saturation +0.15, Contrast +0.05 | Low | Light haze |
| Starfall Castle | 21 (night) | Dark purple | Warm tint, Saturation +0.1 | Medium (torches) | Thin, purple |
| Glitched Core | 0 | Cold grey | Saturation −0.4 | Low | Dense, grey |
| Final level | 22 | Deep blue | Saturation +0.25, warm tint | High, soft | Light, starry |

These are starting points. Tune on screen, and always check both PC and a phone.

---

## 10. Camera, composition and scale

- **Scale contrast is the "wow."** Put the players next to something enormous in every world: a menu button, a coin block, a castle gate, the boss.
- **Always show the goal.** Frame the next landmark (exit portal, boss arena, castle towers) in the distance so players know where they're going.
- **Leading lines:** paths, rails, banners and light pools point toward the way forward.
- **Keep the play space clear.** No big props between the camera and the players; fade or cut away anything that blocks the view.
- **Top-down castle:** the floor is the canvas. Use clear tile patterns to show paths and danger zones.

---

## 11. UI and fonts

The HUD looks like the UI of the game the kids made, and changes skin per world.

| Use | Roblox font | Notes |
| --- | --- | --- |
| Main HUD, menus | FredokaOne | Round, friendly, readable on mobile |
| Pixel Plains UI and signs | Arcade | Retro pixel feel |
| Starfall Castle UI and signs | Fantasy | Storybook feel |
| Glitched Core UI and signs | Code | Monospace "unfinished game" feel |
| Kid handwriting (notes, doodles, credits) | PermanentMarker | Handmade touch |

- UI panels have thick rounded outlines and a slight hand-drawn wobble, like stickers.
- Kai's UI elements use orange accents, Miko's teal, shared ones white.
- Keep the HUD minimal: hearts or HP, two tool icons, ping and peek hints. Nothing else on screen during gameplay.
- Lobby capsules: Kai capsule orange, Miko capsule teal, the pair's screen uses the same font and style as the main HUD.

---

## 12. VFX and animation feel

- **Chunky and readable:** big simple particles (squares in Pixel Plains, embers and stars in the castle, static and pixels in the Core).
- **Every tool use has three parts:** a wind-up, the effect, and an impact. Players must see and hear that their action worked.
- **Freeze:** a blue-white pause ripple and a ⏸ icon, the object held perfectly still.
- **Fire:** warm orange with star-shaped sparks (Kai's star motif).
- **Shield reflect:** a teal flash and a ring on the shield face.
- **Copy/Paste:** a white "scan" line on copy, a ghost outline that snaps solid on paste.
- **Layer Shift:** a teal scanline wipe across Miko's screen.
- **Squash and stretch** on jumps, landings and ground pounds; small camera shake on heavy hits only.

---

## 13. Roblox production rules

- **Performance first, especially mobile:** keep part counts low (use meshes for detailed props), reuse assets, keep textures modest in size, use StreamingEnabled. Test every world on a phone.
- **Materials:** build a small shared kit of MaterialVariants per world (e.g., "PixelPlastic", "CastleStone", "CoreGrey") and reuse it everywhere.
- **Modular kits:** each world has a kit of snapping pieces (floors, walls, platforms, props) so levels can be built fast and stay consistent.
- **Grey-box first:** build every area in plain grey blocks with gameplay colors only. Add art only after the co-op gameplay is fun (see `design.md` §10).
- **Concept art:** generate mood boards and concept images for each world before building, then use them as the reference for the kit.
- **Original only:** no It Takes Two screenshots, textures, characters or logos anywhere in the game, thumbnails or store page.

---

## 14. Do and don't

| Do | Don't |
| --- | --- |
| Big shapes, clear silhouettes, one focal point per room | Tiny fiddly detail, visual clutter |
| Orange for Kai, teal for Miko, white for both | Use those colors for decoration |
| Warm light to guide players | Pitch-black rooms with no direction |
| Kid doodles, stickers, handwritten signs | Grim, gory or realistic horror |
| Glitch = the only thing that looks broken | Glitchy effects on normal props "for style" |
| Test on a phone and from the top-down camera | Judge the look only on a PC monitor |

---

## 15. Art review checklist (use for every new area)

- [ ] Can you tell where to go within 3 seconds?
- [ ] Are all usable objects colored by owner (orange / teal / white) with an icon?
- [ ] Is red used only for danger, magenta only for The Glitch?
- [ ] Is there at least one "kid detail" (doodle, sticker, handwritten sign)?
- [ ] Is there one clear scale moment (something huge next to the players)?
- [ ] Does the color and light match this world's emotion in the color script?
- [ ] Are Kai and Miko easy to tell apart here, including from the top-down camera?
- [ ] Does it run smoothly on a phone?

---

## 16. Exact palette (hex codes)

Use these exact values in Blender materials, textures, Roblox part colors and UI.

### Reserved gameplay colors
Reserved means: **saturated emissive glows, outlines and icons on interactables**. World lighting and base materials may be warm or cool, but never use these as neon glows on decoration.

| Name | Hex | Use |
| --- | --- | --- |
| Kai Orange | `#FF8A2B` | Kai's targets, Kai's UI, Kai's outfit accent |
| Miko Teal | `#1FC7B6` | Miko's targets, Code Layer wireframes, Miko's UI, Miko's outfit accent |
| Duo White | `#F5F7FA` | Both-player objects |
| Neutral Yellow | `#FFD23F` | Plates, doors, checkpoints |
| Danger Red | `#E5383B` | Damage, attack warnings |
| Glitch Magenta | `#FF2BD6` | The Glitch |
| Glitch Cyan fringe | `#2BF2FF` | RGB-split edge only |
| Glitch Black | `#0B0B10` | Checkerboard with magenta |

### World palettes

| World | Colors |
| --- | --- |
| Real world | Night blue `#1C2742` · screen glow `#8FB8FF` · lamp warm `#FFB763` · wall beige `#CBBFA8` |
| Prologue | Navy `#111A3A` · deep navy `#0A0F24` · UI white `#EEF2FF` · accent pink `#FF5FA2` |
| Pixel Plains | Grass `#5BD15B` · grass shadow `#3FA34D` · sky `#6EC6FF` · coin gold `#FFC83D` · dirt `#B5773F` · cloud `#FFFFFF` |
| Starfall Castle | Night purple `#3B2A5A` · royal purple `#5A3E8C` · stone `#6E6A80` · torch amber `#FFB347` · trim gold `#E8B64C` · banner red-violet `#8C2F5A` |
| Glitched Core | Mid grey `#7A7D85` · dark grey `#3A3C42` · void `#141518` · (accents only: Glitch Magenta, Miko Teal) |
| Final level | Star sky `#1A2466` · starlight `#FFF3C4` · plus all world colors at full saturation |

---

## 17. Blender asset guide (for building 3D assets)

### Scene setup
- **Units:** Scene Properties → Units → Unit System **None**, Rotation **Degrees** (Roblox's recommended setup). Treat **1 Blender unit = 1 stud**.
- **Axes:** Blender is Z-up, Studio is Y-up. Export with the FBX defaults and check orientation on the first import.
- **Scale check (do this once before making any real asset):** export a 1×1×1 cube and a 5-unit-tall box, import both into Studio, and confirm they measure 1 stud and 5 studs. If the size is wrong, fix it in the FBX export Scale (setting it to 0.01 is a common fix) and keep that setting for every asset.
- **Keep a reference character in every file:** a 5-unit-tall box (about the height of a Roblox R15 character) so props are built at the right size.

### Level metrics (build to these)
| Thing | Size (studs) |
| --- | --- |
| Character height | ~5 |
| Grid snap | 1 (props), 4 (level kit pieces) |
| Floor tile (kit) | 8 × 8 |
| Standard wall height | 12 (castle top-down: 6, so walls don't hide players) |
| Doorway | 6 wide × 9 tall minimum |
| Corridor for two players | 10 wide minimum |
| Pressure plate | 4 × 4 |
| Swing point / grapple ring | 2–3 diameter, 6+ from any wall |
| Jump gaps | Measure in a grey-box test course; required gaps at 80% of the tested maximum |

### Modeling style
- **Chunky and soft:** thick shapes, exaggerated proportions, **Bevel modifier** on hard edges (width 0.1–0.25 studs, 2–3 segments) plus **Weighted Normal** so edges catch light. This is what makes props feel "handmade" instead of like default parts.
- **Silhouette first:** block out in simple shapes and check the silhouette from the gameplay camera angle (third-person and top-down) before adding detail.
- **Big details only:** anything smaller than about 0.5 studs won't read in play. Put small detail in the texture, not the geometry.
- **Slight imperfection:** tiny tilts, uneven planks, wobbly outlines. Kid-made, not machine-made. Never perfectly symmetrical props unless it's a Glitch piece.
- **Pixel Plains:** build from 1-stud cubes (voxel style) with a small bevel so blocks feel like plastic toys.
- **Starfall Castle:** oversized stones, thick arches, rounded battlements. Floors get the most detail because the camera looks down at them.
- **Glitched Core:** grey untextured blocks, deliberately flat-shaded, with a few pieces slightly offset or missing faces modeled as separate floating chunks.

### Roblox mesh rules (from Roblox's specifications)
- **Max 20,000 triangles per mesh** (hard limit). Our budgets are much lower:

| Asset | Triangle budget |
| --- | --- |
| Small prop (crate, coin block, torch) | 300–1,500 |
| Medium prop (arch, cart, machine) | 1,500–5,000 |
| Kit piece (wall, floor, platform) | 200–2,000 |
| Character | 5,000–10,000 |
| Boss (split into parts that animate) | up to 20,000 per part |

- Quads where possible, **no n-gons**.
- **Watertight**, with some thickness (no zero-thickness planes, no holes, no backfaces).
- **One material per mesh.** If a prop needs two materials, split it into two meshes.
- **One UV set**, inside the 0–1 space (overlapping UVs are fine).
- Rigged meshes: bones frozen (scale 1, rotation 0), root bone at 0,0,0, no more than **4 bone influences per vertex**, only one animation per export.
- **Apply all transforms** (Ctrl+A → All Transforms) and put the **origin at the bottom center** of the prop (so it sits on the floor when placed in Studio).

### Textures
- **Default approach: shared palette atlas.** One small gradient/color-swatch texture per world (e.g. 256×256) built from the palette in §16. UV each face onto the right swatch. Many meshes share one texture, which is cheap, consistent and very stylized.
- **Hero assets only get full PBR** (SurfaceAppearance): Albedo (RGB), Normal (**OpenGL** format only), Roughness and Metalness (grayscale). SurfaceAppearance maps max **1024×1024**.
- Size by object size: about 256 px for small (5×5 studs), 512 for medium (10×10), 1024 for large (20×20).
- Formats: PNG (preferred), JPG, TGA or BMP.
- **Kid details** (doodles, stickers, handwritten signs) go on **separate decal planes or decals in Studio**, so they can be reused and swapped.
- Keep textures hand-painted and simple: soft gradients, painted highlights, no photo textures.

### Export (FBX)
Roblox's recommended Blender FBX settings:
- Format **FBX**, **Selected Objects** only.
- **Path Mode: Copy**, **Embed Textures: on**.
- **Apply Scalings: FBX Unit Scale** (plus the scale fix from your scale check, if needed).
- **Add Leaf Bones: off**; **Bake Animation: off** unless exporting an animation.

### Naming
`<World>_<Type>_<Name>` using prefixes: `PR_` Prologue, `PP_` Pixel Plains, `SC_` Starfall Castle, `GC_` Glitched Core, `FL_` Final level, `RW_` Real world, `SH_` shared. Types: `Kit`, `Prop`, `Char`, `Boss`, `FX`.
Examples: `PP_Prop_CoinBlock`, `SC_Kit_Wall_Arch`, `GC_Prop_WireframeBridge`, `SH_Prop_PressurePlate`.

### In Studio after import
- Props that players don't stand on: `CanCollide` off or `CollisionFidelity = Box`.
- Walkable meshes: `CollisionFidelity = Hull` or `PreciseConvexDecomposition` only where needed; for complex shapes, add simple invisible collision parts instead.
- Save every finished asset as a package or in a shared `Assets` folder so all worlds reuse it.

### Asset checklist (before export)
- [ ] Built at stud scale, checked against the 5-stud reference character
- [ ] Silhouette readable from the gameplay camera
- [ ] Bevels + weighted normals on hard edges
- [ ] Under its triangle budget; no n-gons; watertight; one material
- [ ] Transforms applied, origin at bottom center
- [ ] Colors from §16 only; reserved colors only on interactables
- [ ] Named with the world/type prefix

---

## 18. Reference-search guide

When searching for references, look for **principles**, then build something original from at least **three different references** combined. Never trace or rebuild one image.

**Never use as a direct reference to copy:** It Takes Two (or any Hazelight game) screenshots, characters, props, levels, UI or logos. It's fine to *study* how they use scale, color and light, but no shape, prop or layout should come from them.

### Search terms by world

| World | Search for | Look for |
| --- | --- | --- |
| Overall style | "stylized low poly game props bevel", "hand painted stylized 3D", "toy-like 3D environment", "claymation set miniature" | Chunky shapes, soft bevels, painted materials |
| Kid details | "children's drawings", "notebook doodles", "sticker bomb texture", "crayon texture" | Wobbly lines, bright markers, handmade feel |
| Prologue | "retro game title screen", "floating UI in 3D space", "giant menu buttons concept art" | Big simple shapes in a dark void |
| Pixel Plains | "voxel landscape", "8-bit platformer level 3D", "blocky plastic toy terrain" | Stepped terrain, bright flat colors, cube clouds |
| Starfall Castle | "storybook castle interior", "stylized dungeon top-down", "medieval great hall torchlight", "fantasy library concept art" | Oversized arches, warm light pools, patterned floors |
| Glitched Core | "untextured 3D blockout", "wireframe environment", "digital glitch art", "datamosh", "missing texture checkerboard" | Grey unfinished geometry, magenta glitch accents |
| Final level | "starry night fantasy kingdom concept art", "night sky shooting stars stylized" | Warm starlight over a colorful world |
| Real world | "teenager bedroom at night lamp", "cozy messy desk with monitor glow" | Soft light, personal clutter |
| Characters | "stylized character turnaround chunky proportions", "game character silhouette sheet" | Clear silhouettes, big hands and heads |

### How to use a reference
1. Write down what the reference is teaching (for example: "warm light pool on a cold floor").
2. Take only that idea. Apply it with our shapes, our palette (§16) and our kid-made details.
3. Check the result against the art review checklist (§15).

---

## Sources

- [Hazelight Studios It Takes Two Art Blast — ArtStation Magazine](https://magazine.artstation.com/2021/04/hazelight-studios-it-takes-two-art-blast/): inviting and vibrant goal, Pixar-inspired stylized scale and shape without losing realism, visual clarity
- [Hazelight on facial animation in It Takes Two — Faceware](https://facewaretech.com/blog/interview-hazelight-studios-talks-facial-animation-on-it-takes-two/): theatrical, exaggerated fantasy performances vs. a realistic world, expressive faces to build a bond
- [It Takes Two — Wikipedia](https://en.wikipedia.org/wiki/It_Takes_Two_(video_game)): environments based on the family's home and relationship
- [Josef Fares interview — Pocket Tactics](https://www.pockettactics.com/it-takes-two/interview): Nintendo and Pixar clarity and innocence
- [Mesh specifications — Roblox Creator Hub](https://create.roblox.com/docs/art/modeling/specifications): 20,000-triangle limit, topology, rigging rules
- [Texture specifications — Roblox Creator Hub](https://create.roblox.com/docs/art/modeling/texture-specifications): PBR maps, OpenGL normals, sizes
- [Export settings — Roblox Creator Hub](https://create.roblox.com/docs/art/modeling/export-requirements) and [Blender setup — Roblox Creator Hub](https://create.roblox.com/docs/art/blender): FBX export and unit settings
- [1:1 scale from Blender to Roblox — DevForum](https://devforum.roblox.com/t/exporting-11-scale-models-from-blender-to-roblox-studio/3679265): 0.01 export scale fix
