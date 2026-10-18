# Glitched Together — Implementation Guide (Roblox / Luau)

How to build the game in Roblox. Read `design.md` for the *why* and `mechanics.md` for exact numbers. Code snippets are starting points written in Luau; test and adjust them.

---

## 1. Big picture

The game is **two places in one Roblox experience**:

| Place | What happens there | Server type |
| --- | --- | --- |
| **Lobby** (start place) | Everyone loads onto one lobby platform. Players step into capsules to become Kai or Miko. A locked-in pair is teleported together. | Normal public servers |
| **Adventure** (main world) | Prologue, 3 worlds, epilogue for exactly one duo | **Reserved server** per duo (nobody else can join) |

```
Lobby server ──(pair locks in)──► ReserveServer(Adventure) ──► TeleportAsync(both players)
                                        │
                                        └─► MemoryStore: serverId → { kai = userId, miko = userId }
Adventure server reads the duo from MemoryStore, loads their save, spawns them in the right world.
```

Why a reserved server: it guarantees the two locked-in players end up in the same private server with nobody else.

---

## 2. Lobby: the capsule system

### How it works (player view)
1. Everyone spawns on one big **Lobby platform**.
2. The platform has **6 capsule pairs**. Each pair = one **Kai capsule** (orange) + one **Miko capsule** (teal), side by side, with a shared display screen above them.
3. Step into a Kai capsule → you become **Kai** (name tag "KAI", optional Kai outfit preview). Step into a Miko capsule → you become **Miko**.
4. When **both** capsules of the same pair are filled, a **5-second lock-in countdown** starts on the pair's screen: 5 → 4 → 3 → 2 → 1.
5. If **either** player steps out before it finishes, the countdown **resets** and waits again.
6. When it reaches 0, both are frozen in place, the screen shows "LOADING…", and they are **teleported together** to their own Adventure server (the main world).
7. A capsule already holding someone can't be taken by a second player; the first one in keeps it.

### Lobby build (Studio)
```
Workspace
  Lobby
    Platform
    CapsulePairs
      Pair1 (Model)
        KaiCapsule (Model)
          Zone (Part: Transparent, CanCollide false, Anchored, sized to the capsule's inside)
        MikoCapsule (Model)
          Zone (Part: same as above)
        Screen (Part with a SurfaceGui > TextLabel named "Status")
      Pair2 … Pair6 (same structure)
```
Tag each pair model **`CapsulePair`** with the Tag Editor (or `CollectionService:AddTag`).

### Capsule server script
Checks zones 5 times a second with `GetPartBoundsInBox` (more reliable than `Touched`/`TouchEnded` for "is someone standing in here").

```lua
-- ServerScriptService/Lobby/Capsules.server.lua
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local MemoryStoreService = game:GetService("MemoryStoreService")

local ADVENTURE_PLACE_ID = 0 -- TODO: the Adventure place's id (Asset Manager > Places)
local LOCK_TIME = 5
local CHECK_INTERVAL = 0.2
local DUO_TTL = 60 * 60 -- seconds the duo record lives in MemoryStore

local duoMap = MemoryStoreService:GetHashMap("Duos")

type Pair = {
	model: Model,
	zones: { kai: BasePart, miko: BasePart },
	seats: { kai: Player?, miko: Player? },
	countdown: number?,
	sending: boolean,
	status: TextLabel,
}

local allPairs: { Pair } = {}
local seatedIn: { [Player]: Pair } = {}

local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include

-- Returns the set of players whose characters are inside the zone.
local function occupants(zone: BasePart): { [Player]: boolean }
	local chars = {}
	for _, p in Players:GetPlayers() do
		if p.Character then
			table.insert(chars, p.Character)
		end
	end
	overlap.FilterDescendantsInstances = chars

	local found = {}
	for _, part in workspace:GetPartBoundsInBox(zone.CFrame, zone.Size, overlap) do
		local character = part:FindFirstAncestorOfClass("Model")
		local p = character and Players:GetPlayerFromCharacter(character)
		if p then
			found[p] = true
		end
	end
	return found
end

local function setRole(p: Player, role: string?)
	p:SetAttribute("Role", role) -- "Kai" / "Miko" / nil; clients read this for name tags and outfit preview
end

local function refreshSeat(pair: Pair, seat: "kai" | "miko")
	local inside = occupants(pair.zones[seat])
	local current = pair.seats[seat]

	if current and inside[current] then
		return -- still standing in the capsule
	end
	if current then -- they stepped out
		pair.seats[seat] = nil
		seatedIn[current] = nil
		setRole(current, nil)
	end
	for p in inside do
		if not seatedIn[p] then -- first free player inside takes the seat
			pair.seats[seat] = p
			seatedIn[p] = pair
			setRole(p, if seat == "kai" then "Kai" else "Miko")
			break
		end
	end
end

local function setFrozen(p: Player, frozen: boolean)
	local humanoid = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = if frozen then 0 else 16
		humanoid.JumpHeight = if frozen then 0 else 7.5
	end
end

local function sendPair(pair: Pair)
	local kai, miko = pair.seats.kai, pair.seats.miko
	if not (kai and miko) then
		return
	end
	pair.sending = true
	pair.status.Text = "LOADING..."
	setFrozen(kai, true)
	setFrozen(miko, true)

	local ok, err = pcall(function()
		local accessCode, privateServerId = TeleportService:ReserveServer(ADVENTURE_PLACE_ID)
		duoMap:SetAsync(privateServerId, { kai = kai.UserId, miko = miko.UserId }, DUO_TTL)

		local options = Instance.new("TeleportOptions")
		options.ReservedServerAccessCode = accessCode
		TeleportService:TeleportAsync(ADVENTURE_PLACE_ID, { kai, miko }, options)
	end)

	if not ok then
		warn("Duo teleport failed:", err)
		setFrozen(kai, false)
		setFrozen(miko, false)
		pair.sending = false
		pair.countdown = nil
		pair.status.Text = "TRY AGAIN"
	end
end

local function statusText(pair: Pair): string
	if pair.sending then
		return "LOADING..."
	elseif pair.seats.kai and pair.seats.miko then
		return `LOCKING IN... {math.max(1, math.ceil(pair.countdown or LOCK_TIME))}`
	elseif pair.seats.kai then
		return "WAITING FOR MIKO"
	elseif pair.seats.miko then
		return "WAITING FOR KAI"
	end
	return "STEP IN TO PLAY"
end

local function registerPair(model: Model)
	table.insert(allPairs, {
		model = model,
		zones = { kai = model.KaiCapsule.Zone, miko = model.MikoCapsule.Zone },
		seats = {},
		countdown = nil,
		sending = false,
		status = model.Screen.SurfaceGui.Status,
	})
end

for _, model in CollectionService:GetTagged("CapsulePair") do
	registerPair(model)
end

-- If a teleport fails after it started (e.g. a player's client failed), unfreeze and free the pair.
TeleportService.TeleportInitFailed:Connect(function(p: Player)
	local pair = seatedIn[p]
	if pair then
		if pair.seats.kai then setFrozen(pair.seats.kai, false) end
		if pair.seats.miko then setFrozen(pair.seats.miko, false) end
		pair.sending = false
		pair.countdown = nil
	end
end)

Players.PlayerRemoving:Connect(function(p: Player)
	local pair = seatedIn[p]
	if not pair then
		return
	end
	seatedIn[p] = nil
	if pair.seats.kai == p then pair.seats.kai = nil end
	if pair.seats.miko == p then pair.seats.miko = nil end
	pair.countdown = nil
	if not pair.seats.kai and not pair.seats.miko then
		pair.sending = false -- both have left (teleported): the pair is free again
	end
end)

while true do
	local dt = task.wait(CHECK_INTERVAL)
	for _, pair in allPairs do
		if not pair.sending then
			local beforeKai, beforeMiko = pair.seats.kai, pair.seats.miko
			refreshSeat(pair, "kai")
			refreshSeat(pair, "miko")

			if pair.seats.kai and pair.seats.miko then
				local changed = pair.seats.kai ~= beforeKai or pair.seats.miko ~= beforeMiko
				if changed or pair.countdown == nil then
					pair.countdown = LOCK_TIME -- someone new sat down: start (or restart) the 5 s
				else
					pair.countdown -= dt
					if pair.countdown <= 0 then
						task.spawn(sendPair, pair)
					end
				end
			else
				pair.countdown = nil -- someone stepped out: reset
			end
		end
		pair.status.Text = statusText(pair)
	end
end
```

**Notes**

- Teleports don't work inside Studio. Test the capsule logic in Studio (watch the countdown and roles), then test the teleport in a published game with a friend.
- The Adventure place must be in the **same experience** as the Lobby.
- "Becomes Kai": the `Role` attribute drives a client name tag and, optionally, a costume preview with `Humanoid:ApplyDescription()` on the server. The real Kai/Miko look is applied in the Adventure place.
- Optional later: an **Invite Friend** button (`SocialService:PromptGameInvite(player)` from a LocalScript) so a player can pull a friend into their lobby server.

---

## 3. Adventure place: who is who

```lua
-- ServerScriptService/Services/DuoService.lua (Adventure place)
local Players = game:GetService("Players")
local MemoryStoreService = game:GetService("MemoryStoreService")

local DuoService = {}
DuoService.Kai = nil :: Player?
DuoService.Miko = nil :: Player?

local duo -- { kai = userId, miko = userId }

function DuoService.Init()
	if game.PrivateServerId ~= "" then
		local ok, data = pcall(function()
			return MemoryStoreService:GetHashMap("Duos"):GetAsync(game.PrivateServerId)
		end)
		if ok then duo = data end
	end

	local function assign(p: Player)
		if duo and p.UserId == duo.kai then
			DuoService.Kai = p
			p:SetAttribute("Role", "Kai")
		elseif duo and p.UserId == duo.miko then
			DuoService.Miko = p
			p:SetAttribute("Role", "Miko")
		elseif not duo then
			-- Studio testing fallback: first player is Kai, second is Miko
			if not DuoService.Kai then DuoService.Kai = p; p:SetAttribute("Role", "Kai")
			else DuoService.Miko = p; p:SetAttribute("Role", "Miko") end
		else
			p:Kick("This is a private duo server.")
		end
	end

	for _, p in Players:GetPlayers() do assign(p) end
	Players.PlayerAdded:Connect(assign)
end

function DuoService.PartnerOf(p: Player): Player?
	if p == DuoService.Kai then return DuoService.Miko end
	if p == DuoService.Miko then return DuoService.Kai end
	return nil
end

return DuoService
```

**If a player disconnects:** pause the game for the other player with a "Waiting for your partner… (reconnect)" screen for up to 2 minutes, then return them to the Lobby with `TeleportService:TeleportAsync(LOBBY_PLACE_ID, { player })`. Progress is saved at the last checkpoint.

---

## 4. Project setup

- **Rojo + Git:** keep all scripts as files in a Git repo on your GitHub and sync them into Studio with Rojo. Build worlds (parts, models) in Studio.
- **Two places**, one experience: `Lobby` (start place) and `Adventure`.
- **Adventure place settings:**
  - `Workspace.StreamingEnabled = true`; puzzle models set to `ModelStreamingMode = Atomic` so a puzzle never half-loads.
  - `StarterPlayer.EnableMouseLockOption = false` (Shift is dash).
  - `Players.CharacterAutoLoads = true`, but death is handled by our own Downed system (see §9).
- **Server Authority** (released to all creators in July 2026) adds server-validated movement with client prediction. This is a co-op game with no competitive stakes and a custom moveset, so **start without it** and revisit after the moveset feels good.

### Folder layout (Adventure place)
```
ReplicatedStorage
  Shared
    Net.lua                    -- creates/looks up RemoteEvents
    Config
      Tuning.lua               -- every number from mechanics.md
      Kits.lua                 -- which tool each role gets in each world
      Worlds.lua               -- world order, spawn points, music
    AbilitiesClient            -- client halves of each tool (aim, VFX, input)
      PauseBeam.lua  GrappleLine.lua  FireMage.lua  ShieldKnight.lua  CopyPaste.lua  LayerShift.lua
    Util
      Trove.lua                -- cleanup helper (or your own)
  InputContexts                -- Input Action System
    BaseContext  W1Tools  CastleTools  W3Tools  MenuContext

ServerScriptService
  Main.server.lua              -- requires and Init()s services in order
  Services
    DuoService.lua  SaveService.lua  WorldService.lua  CheckpointService.lua
    HealthService.lua  AbilityService.lua  MoverService.lua  InteractableService.lua
    EnemyService.lua  BossService.lua  CutsceneService.lua  HintService.lua  RelayService.lua
    AbilitiesServer            -- server validators for each tool
      PauseBeam.lua  GrappleLine.lua  FireMage.lua  ShieldKnight.lua  CopyPaste.lua  LayerShift.lua

ServerStorage
  Worlds   Prologue  PixelPlains  StarfallCastle  GlitchedCore  Epilogue
  Enemies  Bosses  Projectiles

StarterPlayer > StarterPlayerScripts
  Client.client.lua            -- requires and Init()s controllers
  Controllers
    MovementController  CameraController  KitController  HUDController
    PingController  PeekController  CutsceneController  CodeLayerController
```

### Tags (CollectionService)
Tag level parts in Studio; services find them with `CollectionService:GetTagged()` and `GetInstanceAddedSignal()` (important with streaming).

| Tag | Used by | Attributes |
| --- | --- | --- |
| `Checkpoint` | CheckpointService | `Order` (number), `World` |
| `KillZone` | HealthService | — |
| `SwingPoint`, `GrindRail`, `BouncePad`, `JumpVent` | MovementController | rail: `Next` (ObjectValue chain) |
| `PressurePlate`, `DuoGate`, `DuoPound`, `HeavyLever` | InteractableService | `Group` (links plates to a gate) |
| `Mover` | MoverService | `Period`, path in child `Waypoints` folder |
| `Freezable` | Pause Beam | — |
| `GrappleRing`, `Pullable` | Grapple Line | `Mass` |
| `Brazier`, `Burnable` | Fire Mage | — |
| `Copyable` | Copy/Paste | — |
| `CodeLayer` | Layer Shift | — |
| `Enemy` | EnemyService | `Type` |

---

## 5. Networking

One module creates all remotes so names never drift.

```lua
-- ReplicatedStorage/Shared/Net.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()
local folder: Folder

if IS_SERVER then
	folder = Instance.new("Folder")
	folder.Name = "Net"
	folder.Parent = ReplicatedStorage
else
	folder = ReplicatedStorage:WaitForChild("Net") :: Folder
end

local Net = {}

function Net.event(name: string, unreliable: boolean?): RemoteEvent
	if IS_SERVER then
		local existing = folder:FindFirstChild(name)
		if existing then return existing :: any end
		local e = Instance.new(if unreliable then "UnreliableRemoteEvent" else "RemoteEvent")
		e.Name = name
		e.Parent = folder
		return e :: any
	end
	return folder:WaitForChild(name) :: any
end

return Net
```

| Remote | Direction | Reliable? | Payload |
| --- | --- | --- | --- |
| `ToolUse` | client → server | yes | `(useIndex: 1 or 2, target: Instance?, aimPos: Vector3?)` |
| `ToolResult` | server → clients | yes | effects to play (freeze started, pull, paste…) |
| `GroundPound` | client → server | yes | landing position |
| `Ping` | client → server → partner | yes | world position |
| `CamSync` | client → server → partner | **unreliable** | camera CFrame, 10 times a second (for Partner Peek) |
| `Cutscene` | server → clients | yes | cutscene id; `SkipVote` back |
| `Hint` | server → clients | yes | Pip line id |

**Trust rule:** the client asks, the server decides. Every `ToolUse` is checked on the server: right role, right world kit, cooldown ready, target has the right tag, target within range (+5 studs of slack for lag).

---

## 6. Input (Input Action System)

Use Roblox's **Input Action System**: an `InputContext` holds `InputAction`s (Jump, Dash, Tool1…), each with `InputBinding`s for keyboard/mouse, gamepad and touch. Contexts can be enabled/disabled and given priorities at runtime, which makes swapping tool kits per world clean:

- `BaseContext`: always on (Dash, GroundPound, Swing, Sprint, Interact, Ping, Peek).
- `W1Tools`, `CastleTools`, `W3Tools`: only the current world's context is enabled.
- `MenuContext`: high priority with `Sink` on during cutscenes and the level-up picker, so gameplay input is blocked.

Jump itself stays on Roblox's default controls; use `UserInputService.JumpRequest` for the double jump so it works on every device.

---

## 7. Movement controller (client)

The character is owned by its player's client, so movement runs locally for good feel. Sketch of double jump, dash and ground pound:

```lua
-- StarterPlayerScripts/Controllers/MovementController.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Net = require(ReplicatedStorage.Shared.Net)
local Base = ReplicatedStorage.InputContexts.BaseContext

local player = Players.LocalPlayer
local groundPoundEvent = Net.event("GroundPound")

local MovementController = {}

local function inAir(humanoid: Humanoid): boolean
	local s = humanoid:GetState()
	return s == Enum.HumanoidStateType.Freefall or s == Enum.HumanoidStateType.Jumping
end

local function onCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	local attachment = root:WaitForChild("RootAttachment") :: Attachment
	local connections = {}
	local airJumps, airDashes, lastGroundDash, pounding = 0, 0, 0, false

	local function burst(velocity: Vector3, duration: number)
		local lv = Instance.new("LinearVelocity")
		lv.Attachment0 = attachment
		lv.MaxForce = math.huge
		lv.VectorVelocity = velocity
		lv.Parent = root
		task.delay(duration, function() lv:Destroy() end)
	end

	table.insert(connections, humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			airJumps, airDashes = 0, 0
			if pounding then
				pounding = false
				groundPoundEvent:FireServer(root.Position)
			end
		end
	end))

	table.insert(connections, UserInputService.JumpRequest:Connect(function()
		if inAir(humanoid) and airJumps < 1 and not pounding then
			airJumps += 1
			local v = root.AssemblyLinearVelocity
			root.AssemblyLinearVelocity = Vector3.new(v.X, Tuning.DoubleJumpVelocity, v.Z)
		end
	end))

	table.insert(connections, Base.Dash.Pressed:Connect(function()
		local airborne = inAir(humanoid)
		if airborne and airDashes >= 1 then return end
		if not airborne and os.clock() - lastGroundDash < Tuning.GroundDashCooldown then return end
		if airborne then airDashes += 1 else lastGroundDash = os.clock() end

		local dir = if humanoid.MoveDirection.Magnitude > 0 then humanoid.MoveDirection else root.CFrame.LookVector
		burst(dir.Unit * (Tuning.DashDistance / Tuning.DashTime), Tuning.DashTime)
	end))

	table.insert(connections, Base.GroundPound.Pressed:Connect(function()
		if not inAir(humanoid) or pounding then return end
		pounding = true
		burst(Vector3.zero, Tuning.PoundHang) -- brief hang in the air
		task.delay(Tuning.PoundHang, function()
			if pounding then
				root.AssemblyLinearVelocity = Vector3.new(0, -Tuning.PoundFallSpeed, 0)
			end
		end)
	end))

	player.CharacterRemoving:Once(function()
		for _, c in connections do c:Disconnect() end
	end)
end

function MovementController.Init()
	if player.Character then task.spawn(onCharacter, player.Character) end
	player.CharacterAdded:Connect(onCharacter)
end

return MovementController
```

Still to add on top of this sketch: sprint toggle, crouch, wall cling/wall jump (raycast sideways for `Clingable` walls), coyote time, jump buffer, swing points, grind rails. Build and tune the moveset **before** any world content; it's the one thing used everywhere.

- **Swing points:** on F, attach a `RopeConstraint` between the root attachment and the point, set the humanoid to `Physics` state, add a small steering force from move input; on Jump, remove the rope, switch to `Freefall`, multiply velocity by the boost. If ropes feel janky, fall back to a scripted arc (move the root along a circle each frame).
- **Grind rails:** rails are chains of parts (`Next` ObjectValue). While grinding, move the root along the chain at the rail speed each `Heartbeat` and play a grind animation; Jump leaves the rail with the current velocity.

---

## 8. Tools ("capabilities")

Hazelight built its games on custom systems and talked at GDC 2025 about a gameplay framework they call **capabilities**. Ours is a simple version of that idea: each tool is a small self-contained module that can be switched on and off, and knows what blocks it.

### Kit config
```lua
-- ReplicatedStorage/Shared/Config/Kits.lua
return {
	Prologue       = { Kai = nil,           Miko = nil,            Context = nil,           Camera = "Follow" },
	PixelPlains    = { Kai = "PauseBeam",   Miko = "GrappleLine",  Context = "W1Tools",     Camera = "Follow" },
	StarfallCastle = { Kai = "FireMage",    Miko = "ShieldKnight", Context = "CastleTools", Camera = "TopDown" },
	GlitchedCore   = { Kai = "CopyPaste",   Miko = "LayerShift",   Context = "W3Tools",     Camera = "Follow" },
}
```
The server sets `player:SetAttribute("Kit", "PauseBeam")` when a world (or a boss phase) starts. The client `KitController` watches that attribute, destroys the old client module, loads the new one, and enables the matching `InputContext`. The final boss swaps kits per phase just by changing this attribute.

### Tool module shape
```lua
-- Client half (AbilitiesClient/*.lua)
export type ClientTool = {
	Start: (self: ClientTool) -> (),        -- create aim UI, connect InputActions
	Stop: (self: ClientTool) -> (),         -- clean up everything
}

-- Server half (AbilitiesServer/*.lua)
export type ServerTool = {
	BlockedBy: { string },                   -- player attributes that block use, e.g. { "Downed", "InCutscene" }
	Use: (player: Player, useIndex: number, target: Instance?, aimPos: Vector3?) -> (),
}
```
`AbilityService` receives `ToolUse`, checks role, current kit, `BlockedBy` attributes and cooldown, then calls the right server module's `Use`.

### Movers and the Pause Beam
All moving level pieces go through **MoverService**, which is what makes freezing possible.

- Moving platforms are **unanchored**, owned by the server (`part:SetNetworkOwner(nil)`), and driven by `AlignPosition` + `AlignOrientation` towards a target that MoverService updates every `Heartbeat` along the waypoint path. Physics-driven platforms carry standing characters better than `PivotTo`-teleported anchored parts.
- Each mover keeps its own time value `t`. **Freezing = MoverService stops advancing `t`** for 4 s, so the object resumes exactly where it paused.
- Physics objects (falling blocks, thrown objects) freeze by storing their velocity and setting `Anchored = true`; release restores `Anchored = false` and the stored velocity.
- A frozen object gets attributes `Frozen = true` and `FrozenUntil = <time>` so clients can show the blue pause effect and Miko's Grapple Line can target it.

```lua
-- ServerScriptService/Services/AbilitiesServer/PauseBeam.lua
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local MoverService = require(script.Parent.Parent.MoverService)

local PauseBeam = { BlockedBy = { "Downed", "InCutscene" } }
local frozenBy: { [Player]: PVInstance } = {}

function PauseBeam.Use(player: Player, useIndex: number, target: Instance?)
	if useIndex == 2 then -- Release
		local current = frozenBy[player]
		if current then
			MoverService.Resume(current)
			frozenBy[player] = nil
		end
		return
	end

	if not (target and target:IsA("PVInstance") and CollectionService:HasTag(target, "Freezable")) then return end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	if (target:GetPivot().Position - root.Position).Magnitude > Tuning.PauseBeam.Range + 5 then return end

	local old = frozenBy[player]
	if old and old ~= target then MoverService.Resume(old) end
	frozenBy[player] = target
	MoverService.Pause(target, Tuning.PauseBeam.Duration)
end

return PauseBeam
```

### Grapple Line
- **Client:** finds the best target (tag `GrappleRing`, or any object with `Frozen = true`) within range and a small aim cone, draws the line, and runs the swing locally like a Swing Point for responsiveness. It tells the server with `ToolUse(1, target)`.
- **Server:** validates range and that the target is still a valid ring/frozen object. If the target unfreezes mid-swing, the server tells the client to drop the line.
- **Pull:** server-side. Validate `Pullable` + `Mass`, then move it with a temporary `AlignPosition` to 6 studs in front of Miko over 0.4 s.

### Starfall Castle (top-down combat)
- **Camera:** scriptable, centered between both players, zooms out as they separate.

```lua
-- Part of CameraController (client)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local camera = workspace.CurrentCamera

local HEIGHT, BACK = 55, 30

local function rootOf(p: Player?): BasePart?
	local c = p and p.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function startTopDown(partner: Player?)
	camera.CameraType = Enum.CameraType.Scriptable
	RunService:BindToRenderStep("TopDownCam", Enum.RenderPriority.Camera.Value + 1, function(dt)
		local a, b = rootOf(Players.LocalPlayer), rootOf(partner)
		if not a then return end
		local mid = if b then (a.Position + b.Position) / 2 else a.Position
		local spread = if b then (a.Position - b.Position).Magnitude else 0
		local zoom = math.clamp(1 + spread / 60, 1, 1.6)
		local eye = mid + Vector3.new(0, HEIGHT * zoom, BACK * zoom)
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(eye, mid), math.min(1, dt * 8))
	end)
end

local function stopTopDown()
	RunService:UnbindFromRenderStep("TopDownCam")
	camera.CameraType = Enum.CameraType.Custom
end
```

- **Aiming:** cast a ray from the mouse (or right-stick direction) onto a flat plane at character height; the character faces that point.
- **Projectiles** (fireballs, arrows) are simulated on the server: each `Heartbeat`, raycast from the old to the new position. Clients draw the visuals.
- **Shield reflect:** while Miko blocks, the server enables an invisible `ShieldHitbox` part welded in front of her. A projectile ray that hits it bounces with `newDir = dir - 2 * dir:Dot(n) * n` (`n` = the hitbox's front direction), becomes friendly to both players, and deals 1.5× damage.
- **Melee hits:** `workspace:GetPartBoundsInBox()` in front of the attacker, filtered to `Enemy`-tagged models.
- **Enemies:** simple state machine (Idle → Chase → Attack → Recover, plus Stunned). `PathfindingService` for chasing. Target choice: prefer Miko if she is blocking within 20 studs (her taunt), otherwise nearest player.
- **XP and level-ups:** XP lives on the server per player. At a level threshold, set `InCutscene`-style `Picking = true` on both, enable `MenuContext`, show the picker; resume when both have picked.

### Glitched Core
- **Code Layer collisions:** use collision groups so Code Layer parts are only solid for Miko while she is shifted.

```lua
-- Server, once at startup
local PhysicsService = game:GetService("PhysicsService")
for _, name in { "CodeLayer", "Kai", "Miko", "MikoShifted" } do
	PhysicsService:RegisterCollisionGroup(name)
end
PhysicsService:CollisionGroupSetCollidable("CodeLayer", "Default", false)
PhysicsService:CollisionGroupSetCollidable("CodeLayer", "Kai", false)
PhysicsService:CollisionGroupSetCollidable("CodeLayer", "Miko", false)
PhysicsService:CollisionGroupSetCollidable("CodeLayer", "MikoShifted", true)
```
Put every `CodeLayer`-tagged part in the `CodeLayer` group. Put each character's parts in `Kai` or `Miko` on spawn, and switch Miko's parts between `Miko` and `MikoShifted` when she toggles Layer Shift (set it on her client for instant feel and on the server to match).

- **Code Layer visibility:** `CodeLayerController` on each client sets `LocalTransparencyModifier = 1` on Code Layer parts for Kai always, and for Miko when she isn't shifted; Miko sees them with a green wireframe look when shifted.
- **Pull Out:** server moves the part from the `CodeLayer` group to `Default` (now solid and visible for both), and returns the previous pulled-out part to the Code Layer.
- **Copy/Paste:** server stores which `Copyable` object Kai copied. On paste, clone it, place it at the validated position (range check, and `GetPartBoundsInBox` to refuse overlapping a character), tag it `Pasted`, and destroy the oldest paste if there are more than 2.

---

## 9. Health, Downed, respawn, checkpoints

Don't let Roblox's normal death happen; run our own state so we can do Downed and revive.

- `HealthService` keeps `Hearts` (or `HP` in the castle) as player attributes. Hazards call `HealthService.Damage(player, amount)`; nothing sets `Humanoid.Health` to 0.
- At 0 → set `Downed = true`: character becomes a ghost (transparent, slow, tools blocked through `BlockedBy`). Start the auto-respawn timer (5 s, 8 s in boss fights; attributes `RespawnAt` / `RespawnTotal`); each mash press (`RespawnMash` remote, `MashCount` attribute) shortens it, in every world. No partner revive (It Takes Two). Client: `ReviveController` draws the radial meter (own: mid-screen; partner: BillboardGui over the ghost).
- **Both Downed:** fade out, move both to the last checkpoint, restore health.
- **Kill zones:** touching a `KillZone` (checked on the server) moves that player back to their **last safe ground position** after 1.5 s. The server records a safe position every 0.5 s while `Humanoid.FloorMaterial ~= Enum.Material.Air` and the player isn't on a moving object.
- **Checkpoints:** when either player touches a `Checkpoint` with a higher `Order` than the current one, it becomes the duo's checkpoint and `SaveService` saves.

---

## 10. Saving

```lua
-- Key for a duo's save: the same two players always share one save
local function duoKey(a: number, b: number): string
	return `duo_{math.min(a, b)}_{math.max(a, b)}`
end
```

| DataStore | Key | Value |
| --- | --- | --- |
| `DuoSaves` | `duo_<lowId>_<highId>` | `{ world = "PixelPlains", checkpoint = 4, unlocked = { "Prologue", "PixelPlains" }, version = 1 }` |
| `PlayerProgress` | `<userId>` | `{ worldsUnlocked = {...} }` (for a future world-select menu) |

Use `UpdateAsync` (not `SetAsync`) and wrap every call in `pcall` with a retry. Save on checkpoint, on world complete, and on `game:BindToClose()`.

---

## 11. Cutscenes, Pip, Peek, Ping

- **Cutscenes:** each cutscene is a folder of camera parts named `1`, `2`, `3`… with a `Duration` attribute, plus a dialogue list in a module. `CutsceneService` fires both clients with the id and sets `InCutscene = true` on both players (blocks tools and movement). Clients tween the camera through the parts. Skip only when both players have sent `SkipVote`.
- **Pip hints (Oct 19):** Pip is hidden in play and glitches in only to talk (hint or cutscene). `HintService` counts seconds without progress *while someone moves* (`Tuning.HintAfter` 90 / 150 s; no idle timer in boss fights) and setbacks per section (`Tuning.HintDeaths` = 3 downs/falls → that player gets the direct hint). Lines live in `Config/Hints`: per world, per checkpoint section, optional `at`/`r` spot (nearest to the player wins), text per role (`Kai` / `Miko`, or `Both`; `Kai2`/`Miko2`/`Both2` = the more direct second hint). Each player only hears their own role's line; a section without entries = no hint.
- **Partner Peek:** each client sends its camera CFrame on `CamSync` (unreliable, 10 times a second); the server relays it to the partner. While Peek is held, the client smoothly moves its own camera to the partner's latest camera CFrame, and snaps back on release.
- **Ping:** raycast from the camera through the screen center; send the hit position; the server relays it to the partner; both show a marker for 4 s.

---

## 12. Bosses

A boss is a server module with a list of phases. Each phase has `Enter()`, `Update(dt)`, `IsDone(): boolean` and `Exit()`. Attacks alternate their target between Kai and Miko. The final boss's phase `Enter()` changes both players' `Kit` attribute and the camera mode, reusing the World 1, castle and World 3 tools.

```lua
-- Shape of a boss module (ServerStorage/Bosses/CrusherKing.lua)
local Boss = {}
Boss.Phases = {
	{ Name = "Fists",        Enter = function(self) end, Update = function(self, dt) end, IsDone = function(self) return self.CrystalsBroken >= 3 end, Exit = function(self) end },
	{ Name = "FallingFloor", Enter = function(self) end, Update = function(self, dt) end, IsDone = function(self) return self.ShoulderHits >= 2 end,  Exit = function(self) end },
	{ Name = "Crown",        Enter = function(self) end, Update = function(self, dt) end, IsDone = function(self) return self.CrownPulled end,        Exit = function(self) end },
}
return Boss
```

`BossService` runs the current phase each `Heartbeat`, moves to the next when `IsDone()` is true, and saves a checkpoint at the start of each phase so a wipe doesn't restart the whole fight.

---

## 13. Build order

Build the shared systems first, then one world at a time, castle first (it has the biggest new system: combat). Grey-box everything before art.

| Milestone | Deliverable | Done when |
| --- | --- | --- |
| M0 Setup | Rojo + Git, Lobby and Adventure places, Net, Tuning | Both places publish, scripts sync |
| M1 Moveset | Jump, double jump, dash, ground pound, sprint, crouch, wall jump, swing, grind | Feels good solo in a test course |
| M2 Duo core | **Lobby capsules + teleport**, DuoService, roles, checkpoints, health/Downed/revive, plates, Duo Gate, Ping, Peek | Two friends lock in, arrive together, finish a grey-box test course |
| M3 Starfall Castle | Top-down camera, both kits, 5 enemies, XP/level-ups, Siege Cart | Castle playable start to end without the boss |
| M4 Pixel Plains | MoverService, Pause Beam, Grapple Line, enemies, Glitch Chase | Playable start to end without the boss |
| M5 Glitched Core | Collision groups, Layer Shift, Copy/Paste, Freefall | Playable start to end without the boss |
| M6 Bosses | Crusher King, Hollow Dragon, The Unfinished | All 3 beatable |
| M7 Story | Cutscenes, Pip hints and lines, memories, prologue, epilogue | Full run with story |
| M8 Polish and launch | Art and audio pass, mobile controls, saving, playtests (see design.md §9) | 3 outside duos finish without help |

### Testing two players in Studio
Use **Test → Clients and Servers** with 2 players to run a local server and two client windows. DuoService's Studio fallback makes the first player Kai and the second Miko. Teleports and MemoryStore need a published game.

---

## Sources

- [Input Action System — Roblox Creator Hub](https://create.roblox.com/docs/input/input-action-system)
- [Server authority model — Roblox Creator Hub](https://create.roblox.com/docs/projects/server-authority) and [Roblox announcement (July 2026)](https://about.roblox.com/newsroom/2026/07/creating-responsive-cheat-resistant-games-roblox-server-authority)
- [Hazelight on Split Fiction's tech and the capabilities GDC talk — Unreal Engine](https://www.unrealengine.com/developer-interviews/sci-fi-and-fantasy-worlds-collide-in-ue5-powered-co-op-adventure-split-fiction)
- [Hazelight on co-op challenges (syncing players, two cameras) — 80.lv](https://80.lv/articles/hazelight-studios-working-culture-and-approach-to-creating-collaborative-gameplay)
