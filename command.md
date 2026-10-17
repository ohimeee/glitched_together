# Studio commands (Glitched Together)

Paste these into the Studio **Command Bar** (View → Command Bar).

- **During Play:** switch to **Server** first, then paste. Test tab → click **"Current: Client"** so it reads **"Current: Server"** (the game view turns to a server view with a green border; click it again to go back and play). Lines pasted while it says Client do nothing: the server undoes them.
- **Before Play (Edit mode):** paste the same lines, then press Play. The game starts there.

These only work in Studio, never in the published game.

---

## Jump to a world

```lua
workspace:SetAttribute("DebugCheckpoint", nil) workspace:SetAttribute("DebugWorld", nil) workspace:SetAttribute("DebugWorld", "StarfallCastle")
```

World names: `Prologue`, `PixelPlains`, `StarfallCastle`, `GlitchedCore`, `Epilogue`

(The `nil` first makes it reload even if you're already in that world.)

## Jump to a checkpoint in a world

Change the number and the world name:

```lua
workspace:SetAttribute("DebugCheckpoint", 7) workspace:SetAttribute("DebugWorld", nil) workspace:SetAttribute("DebugWorld", "StarfallCastle")
```

Useful ones:

| Where | World | Checkpoint |
|---|---|---|
| Crusher King boss | `PixelPlains` | 28 |
| Castle Torch Run | `StarfallCastle` | 7 |
| Powder Hall / Ember Fuse | `StarfallCastle` | 11 |
| Hollow Dragon boss | `StarfallCastle` | 12 |
| Core: Paste Past the Door | `GlitchedCore` | 3 |
| The Unfinished (final boss) | `GlitchedCore` | 13 |

## Change character (Kai / Miko)

Solo: play as Miko (or put `"Kai"` to go back). Kit, held items and HUD switch on the spot:

```lua
workspace:SetAttribute("DebugRole", "Miko")
```

With 2 players: any change swaps them (Kai becomes Miko and Miko becomes Kai):

```lua
workspace:SetAttribute("DebugRole", tostring(os.clock()))
```

Set it in Edit mode before Play to start as that character.

## Skip a boss phase (during a boss fight)

```lua
workspace:SetAttribute("DebugBossPhase", 2)
```

A number bigger than the last phase ends the fight (beaten).

## Fake the device (UI check without a phone)

```lua
workspace:SetAttribute("DebugDevice", "Touch")
```

Options: `"Touch"`, `"Gamepad"`, `"Keyboard"`. Remove it with `nil`:

```lua
workspace:SetAttribute("DebugDevice", nil)
```

## Fill the ultimate (castle: Meteor / Rally)

```lua
for _, p in game.Players:GetPlayers() do p:SetAttribute("Ultimate", 1) end
```

## Clear all debug settings (go back to normal start)

Run this in **Edit mode** (not during Play) so the next Play starts normally:

```lua
for _, a in { "DebugWorld", "DebugCheckpoint", "DebugBossPhase", "DebugDevice", "DebugRole" } do workspace:SetAttribute(a, nil) end
```

---

# Play the real game on your phone

The Studio phone view is only a preview. To feel the real touch controls, publish the game privately and open it in the Roblox app.

## 1. Publish (on the PC, once)

1. In Studio, make sure **Play is stopped** (Edit mode) and Adventure.rbxl is the open place.
2. **File → Publish to Roblox As...**
   - First time: **Create new experience**. Name it e.g. `Glitched Together (test)`, Creator = you. Click **Create**.
   - Later times: just **File → Publish to Roblox** (Alt+P): it updates the same experience.
3. **Home → Game Settings**:
   - **Basic Info → Devices:** tick **Phone** and **Tablet** (and Computer). Save.
   - **Permissions → Playability:** leave it **Private** (only you can join). Save.
   - **Security:** turn on **Enable Studio Access to API Services** (saves need it). Save.

## 2. Play on the phone

1. Install the **Roblox** app and log in with the **same account** as Studio.
2. Open your experience:
   - In the app: **Profile → Creations**, tap `Glitched Together (test)`, then **Play**,
   - or on the PC open the experience page on roblox.com, copy the link and open it on the phone.
3. The game starts at the Prologue (the Debug commands only work in Studio).

## 3. What to check (write notes as you go)

- Buttons: easy to reach with the right thumb? Nothing too close or off the screen?
- Joystick (left thumb) + a button held at the same time (e.g. move while blocking as Miko).
- Text size: hints, signs and HUD readable?
- Castle: auto-aim on enemies, drag the METEOR / RALLY button to aim.
- Frame rate: does it stutter anywhere?

## 4b. Jump around on the phone (admin chat commands)

Type these in the game chat (works in the published game and in Studio). Only the owner (buldak0555) and ids in `src/shared/Config/Admins.luau` can use them; for anyone else they are plain chat.

| Command | Does |
|---|---|
| `/world pp 28` | load a world at a checkpoint (names: `prologue`, `pp`, `castle`, `core`, `epi`, or the full name; checkpoint optional = start) |
| `/cp 7` | reload the current world at checkpoint 7 |
| `/miko` or `/kai` | change character (solo); `/swap` swaps Kai and Miko with 2 players (`/role miko` works too) |
| `/phase 2` | jump the running boss fight to phase 2 (a number past the last phase = beaten) |
| `/ult` | fill both ultimates |

A jump saves the duo at that world/checkpoint like a normal checkpoint does.

## 4. After changing code

Rojo syncs code into Studio, but the phone runs the **published** version: publish again (**Alt+P**), then on the phone leave the game and join again.

## Notes

- 2 players: the second player needs their own account, and you add them under **Game Settings → Permissions** (Collaborators / friends) or set the game to Friends.
- The lobby → adventure teleport only works once both places are published in the same experience and their ids are in `src/shared/Config/Places.luau` (LAUNCH.md). For a phone test, publishing Adventure.rbxl alone is enough.
