# Lobby: the kids' desk at night (Oct 3, 2026)

User brief: "go all out in lobby so player see it wow this graphics is insane ill play these", "search for every reference you can ... like it takes two".

## References looked at (Google Images, principles only)
- **It Takes Two concept art / environments** (ArtStation): volumetric god rays, dense foreground framing, warm vs cool light, real materials at doll scale.
- **It Takes Two main menu:** a live 3D real-world scene (house + mailbox at golden hour), not a flat menu.
- **Rose's Room** (It Takes Two chapter): a kid's bedroom at night: purple-blue ambient, a glowing retro TV, wooden letter blocks, pillow fort, string lights, book towers.
- **Cozy night bedrooms** (concept art): big moon in the window, fairy lights draped over walls/window, desk lamp warm pool, posters, shelves.
- **Miniature / macro photography** (tiny figures on desks): giant pencils as bridges, book stacks, warm lamp, strong shallow depth of field (tilt-shift) sells the scale.

## Direction
Players are doll-sized on **Kai and Miko's shared childhood desk** at night: the desk where they made the game. 1 stud ≈ 1.5 cm.
- **Room (Blender panorama, scene LobbyRoom):** window with a big moon and a night town, curtains, fairy lights, posters and crayon drawings of Starfall Kingdom, shelves with toys/books, bed with quilt, rug, glow-in-the-dark stars on the ceiling, door with warm light under it. Desk top at z −8 (origin = player eye height), floor 50 below.
- **Desk (in game, real 3D):** wood top with Poly Haven grain, legs to the floor; giant props: CRT monitor showing the Starfall Kingdom title (glow), anglepoise desk lamp (warm SpotLight pool), book stacks, pencils, eraser, sticky notes, crayon box, a retro gamepad; capsules stay as toy pods in a ring.
- **Light:** day-clock trick aimed at the moon (cool key), warm lamp + fairy lights, purple ambient; strong tilt-shift DOF (near focus) for the miniature feel.
- Colors: Kai orange / Miko teal stay on the capsules only; props in natural colors.

## Status (end of Oct 3) and the fix to do next
Built (in game): room, desk, bed, shelf, books, toy blocks as plain Parts + 11 generated props. User feedback: "looks like Hide and Seek Extreme" (that Roblox game = tiny players in a giant room of flat box furniture). Fix (user's pick): keep the bedroom, rebuild every box as a sculpted Blender mesh (bevels, rounded cushions, cloth-sim quilt/curtains, book meshes, panelled drawers, turned legs), add much denser clutter, moodier light, close framing at spawn. Keep the invisible colliders in LobbyRoom.luau. Details: CLAUDE.md "Status (Oct 3, 11th session)" item 7.

## Rebuilt (Oct 3, 12th session)
Done: every box replaced by a sculpted Blender piece (BLENDER_PLAYBOOK §11, `tools/lobby_kit/`), denser clutter (bunting, mobile, cubbies, corkboard, train loop, beanbag, toy basket...), A-frame chalkboard sign, moodier ambient. Reference re-check (It Takes Two Rose's Room, ArtStation): pennant bunting + planet mobile + cubbies with fabric bins + toys on the floor were taken from that pass (principles only).
