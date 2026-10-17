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
