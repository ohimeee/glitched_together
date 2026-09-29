# [2 PLAYER] Glitched Together 👾

Two-player co-op Roblox adventure. Design docs: [design.md](design.md) (why), [art-direction.md](art-direction.md) (look), [mechanics.md](mechanics.md) (numbers), [implementation.md](implementation.md) (how), [Story Line](Glitched%20Together%20—%20Story%20Line.md), [research.md](research.md) (It Takes Two art/feel notes).

## Layout

| Path | What |
| --- | --- |
| `lobby.project.json` | Lobby place: capsule pairs, lock-in, teleport (Rojo port 34873) |
| `adventure.project.json` | Adventure place: the game (Rojo port 34872) |
| `src/shared` | Net remotes, Config (Tuning, Kits, Worlds, Roles, Dialogue, Places), Util |
| `src/lobby` | LobbyBuilder (lobby + capsule pairs from Blender meshes, grey-box fallback), CapsuleMeshes (mesh ids), Capsules, Lobby UI |
| `src/adventure/server` | `Main` + Services (Duo, Save, World, Checkpoint, Health, Interactable, Mover, Ability, Relay, Hint, Cutscene, Enemy, Boss, Collision) + `Greybox` level builder |
| `src/adventure/client` | Input (Input Action System with fallback), Aim, Controllers, AbilitiesClient |
| `blender_assets/` | Blender sources (.blend) and FBX exports for Studio (Pip, LobbyCapsule, PrologueUI); `briefs/` = design briefs. Imported mesh ids live in `src/lobby/server/CapsuleMeshes.luau` and `src/adventure/server/Services/ArtService.luau` |

## Run it

```sh
rokit install                          # rojo, stylua, luau-lsp
rojo serve adventure.project.json      # port 34872
rojo serve lobby.project.json          # port 34873 (second terminal)
rojo build adventure.project.json -o build/Adventure.rbxl
```

Open `build/Adventure.rbxl` in Studio → Plugins → Rojo → Connect (34872). Press Play.
Two players: Test → Clients and Servers → 2 players (first = Kai, second = Miko).
Studio only: `workspace:SetAttribute("DebugWorld", "PixelPlains")` in the command bar during play jumps worlds.

Before publishing: create one experience with both places, then fill in the ids in `src/shared/Config/Places.luau`. Teleports and MemoryStore only work in a published game.

## Milestone status (implementation.md §13)

- M0 Setup, M1 Moveset, M2 Duo core: implemented, grey-boxed in the Prologue test course.
- M4 Pixel Plains tools (Pause Beam, Grapple Line, MoverService): implemented + grey-box playground.
- M5 Glitched Core tools (Copy/Paste, Layer Shift, Code Layer): implemented + small demo.
- M3 Starfall Castle: Fire Mage / Shield Knight kits, 5 enemy types, projectiles + shield reflect, XP and level-up upgrades, grey-box 2-1 Castle Gates. Implemented, tested solo.
- M6 bosses, M7 story content: stubs/TODO.
