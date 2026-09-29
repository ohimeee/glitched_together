# Glitched Together (Roblox, Luau, Rojo)

- Docs: `design.md` (why), `mechanics.md` (numbers), `implementation.md` (how), `Glitched Together — Story Line.md`, `research.md` (It Takes Two art/feel research).
- **Any 3D / Blender / art task: read `BLENDER_PLAYBOOK.md` first** (tools, reference search, art rules, Roblox limits, Blender → Studio pipeline, asset backlog).
- Blender files (.blend sources, .fbx exports) live in `blender_assets/`; design briefs in `blender_assets/briefs/`.
- Every tuning number lives in `src/shared/Config/Tuning.luau`; don't hardcode numbers elsewhere.
- Code layout and run steps: `README.md`.

## Relaunch checklist (after a restart)

1. Rojo: `rojo serve adventure.project.json` (port 34872) and `rojo serve lobby.project.json` (port 34873), each as a background task. Check with `curl localhost:34872/api/rojo`.
2. Studio: newest `%LOCALAPPDATA%\Roblox\Versions\*\RobloxStudioBeta.exe -task EditFile -localPlaceFile "<repo>\build\Adventure.rbxl"`. Studio MCP server = `Roblox_Studio` (`list_roblox_studios` for the id). Rojo plugin connects to 34872.
3. Blender: `cmd //c start "" "D:\Blender\blender.exe" --python "C:\Users\User\tools\blender-mcp\autostart.py"` starts Blender with the MCP server on 9876 (no user click needed).
4. Browser: the user's browser is **Brave**. In this VS Code panel, browser tools (`mcp__claude-in-chrome__*`) only load when the user's message contains **`@browser`**.

## Status (Sep 30, 2026)

- **Code:** M0–M2 (setup, moveset, duo core) + World 1 and World 3 tools implemented; grey-box levels built from code (`src/adventure/server/Greybox`). Verified in a solo Studio playtest: Prologue loads, roles/kit/cutscene work, Pause Beam freezes a mover. **Not yet tested with 2 players** (Test → Clients and Servers → 2). Castle combat (M3) and bosses (M6) are stubs.
- **Studio debug:** during play, `workspace:SetAttribute("DebugWorld", "PixelPlains")` jumps worlds (Studio only).
- **Before publishing:** fill place ids in `src/shared/Config/Places.luau`.
- **Art:** Lobby capsule done and in the Lobby place (mesh ids in `src/lobby/server/CapsuleMeshes.luau`, spawned at runtime by `LobbyBuilder`; verified in a solo Studio playtest). Prologue title-screen set (panels, giant buttons, title card) and Pip (floating companion) in the Adventure place via `ArtService` skins. Next art: backlog in `BLENDER_PLAYBOOK.md` §8.
- **Studio UI clicks** (e.g. Import 3D) need the user: Claude can't drive Studio's UI while VS Code is foreground. Everything else goes through Studio MCP.
- Git remote: https://github.com/ohimeee/glitched_together (private), branch `main`. Commit/push only when the user asks. `.gitattributes` forces LF endings (StyLua expects LF).
