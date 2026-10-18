-- Trailer recording mode (admin /trailer, server Services/Trailer). No UI at all (ScreenGuis, Roblox's own UI,
-- overhead tags, prompts, partner outline) so OBS records clean frames. Keys (PC):
--   End        leave trailer mode            U   UI back on / off (check something without leaving)
--   V          fly camera on / off (the character stays put; WASD, E up, Q down, Shift fast, scroll = speed,
--              hold the right mouse button to look, Z / X = narrower / wider lens)
--   1-9        camera path slot              K   add the camera here as the slot's next point   J   drop the last
--   Delete     clear the slot                [ / ]  path time -1 s / +1 s
--   P          play the slot's path (or stop): a smooth constant-speed flight, eased at both ends. Out of fly mode
--              you keep playing the character live while the camera flies the path.
--   O          print the slot's points to the output (paste them into a shot list)
--   H          hide / show your own character (environment shots)
--   G          ghost take (3 s countdown, G again stops early): /puppet replays it with /ghost play
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Net = require(ReplicatedStorage.Shared.Net)
local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Input = require(script.Parent.Parent.Input)
local CameraController = require(script.Parent.CameraController)

local T = Tuning.Trailer
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local TrailerController = {}

type Key = { cf: CFrame, fov: number }

local active = false
local uiHidden = false
local flying = false
local playing = false
local camCF = CFrame.new()
local fov = 70
local yaw, pitch = 0, 0
local speedScale = 1
local slot = 1
local paths: { [number]: { keys: { Key }, time: number } } = {}
local charHidden = false
local recording = false
local overriding = false
local nextStream = 0
local streamedAt = Vector3.new(1e9, 0, 0)

-- toast: the only UI left in trailer mode (top-left, gone after a moment; never during a path or a take)
local toastGui = Instance.new("ScreenGui")
toastGui.Name = "TrailerToast"
toastGui.ResetOnSpawn = false
toastGui.DisplayOrder = 100
toastGui.IgnoreGuiInset = true
local toastLabel = Instance.new("TextLabel")
toastLabel.BackgroundColor3 = Color3.new(0, 0, 0)
toastLabel.BackgroundTransparency = 0.4
toastLabel.TextColor3 = Color3.new(1, 1, 1)
toastLabel.Font = Enum.Font.GothamBold
toastLabel.TextSize = 16
toastLabel.AutomaticSize = Enum.AutomaticSize.XY
toastLabel.Position = UDim2.fromOffset(12, 12)
toastLabel.Visible = false
toastLabel.Parent = toastGui
local toastPad = Instance.new("UIPadding")
toastPad.PaddingLeft, toastPad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
toastPad.PaddingTop, toastPad.PaddingBottom = UDim.new(0, 4), UDim.new(0, 4)
toastPad.Parent = toastLabel
local toastId = 0
local function toast(text: string, secs: number?)
	toastId += 1
	local id = toastId
	toastLabel.Text = text
	toastLabel.Visible = true
	task.delay(secs or 1.2, function()
		if toastId == id then
			toastLabel.Visible = false
		end
	end)
end

local function path(): { keys: { Key }, time: number }
	local p = paths[slot]
	if not p then
		p = { keys = {}, time = T.PathTime }
		paths[slot] = p
	end
	return p
end

-- UI hiding ------------------------------------------------------------------------------------------------------
local hiddenGuis: { [Instance]: boolean } = {} -- ScreenGui / BillboardGui / Highlight → its Enabled before
local watchConns: { RBXScriptConnection } = {}

local function hideOne(d: Instance)
	if d == toastGui then
		return
	end
	local hide = d:IsA("ScreenGui") or d:IsA("BillboardGui") or (d:IsA("Highlight") and d.Name == "RoleOutline")
	if hide and hiddenGuis[d] == nil then
		hiddenGuis[d] = (d :: any).Enabled;
		(d :: any).Enabled = false
	end
end

local function setUiHidden(on: boolean)
	if on == uiHidden then
		return
	end
	uiHidden = on
	if on then
		local pg = player:FindFirstChildOfClass("PlayerGui")
		for _, root in { pg, workspace } do
			if root then
				for _, d in root:GetDescendants() do
					hideOne(d)
				end
				table.insert(watchConns, root.DescendantAdded:Connect(hideOne))
			end
		end
		pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.All, false)
		ProximityPromptService.MaxPromptsVisible = 0
	else
		for _, c in watchConns do
			c:Disconnect()
		end
		table.clear(watchConns)
		for d, was in hiddenGuis do
			if d.Parent then
				(d :: any).Enabled = was
			end
		end
		table.clear(hiddenGuis)
		pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.All, true)
		ProximityPromptService.MaxPromptsVisible = 16
	end
end

-- some controllers switch their guis back on (range checks): keep them off
local function enforceHidden()
	for d in hiddenGuis do
		if d.Parent and (d :: any).Enabled then
			(d :: any).Enabled = false
		end
	end
end

-- character ------------------------------------------------------------------------------------------------------
local function root(): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function setCharHidden(on: boolean)
	charHidden = on
	local c = player.Character
	if c then
		for _, d in c:GetDescendants() do
			if d:IsA("BasePart") or d:IsA("Decal") then
				(d :: any).LocalTransparencyModifier = if on then 1 else 0
			end
		end
	end
end

-- camera paths ---------------------------------------------------------------------------------------------------
local function catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, u: number): Vector3
	local u2, u3 = u * u, u * u * u
	return 0.5 * ((2 * p1) + (p2 - p0) * u + (2 * p0 - 5 * p1 + 4 * p2 - p3) * u2 + (3 * p1 - p0 - 3 * p2 + p3) * u3)
end

-- position / rotation / lens at distance-progress s ∈ [0, 1] along the keys (constant speed)
local function sampler(keys: { Key }): (number) -> (CFrame, number)
	local n = #keys
	if n == 1 then
		return function()
			return keys[1].cf, keys[1].fov
		end
	end
	local function pos(i: number, u: number): Vector3
		local p0 = keys[math.max(1, i - 1)].cf.Position
		local p1 = keys[i].cf.Position
		local p2 = keys[i + 1].cf.Position
		local p3 = keys[math.min(n, i + 2)].cf.Position
		return catmull(p0, p1, p2, p3, u)
	end
	local STEPS = 24
	local table_: { { d: number, i: number, u: number } } = { { d = 0, i = 1, u = 0 } }
	local total = 0
	local last = keys[1].cf.Position
	for i = 1, n - 1 do
		for k = 1, STEPS do
			local u = k / STEPS
			local p = pos(i, u)
			total += (p - last).Magnitude
			last = p
			table.insert(table_, { d = total, i = i, u = u })
		end
	end
	return function(s: number): (CFrame, number)
		local d = s * total
		local lo = 1
		for j = 2, #table_ do
			if table_[j].d >= d then
				lo = j - 1
				break
			end
			lo = j
		end
		local a = table_[lo]
		local b = table_[math.min(lo + 1, #table_)]
		local f = if b.d > a.d then (d - a.d) / (b.d - a.d) else 0
		local i = if b.i ~= a.i then b.i else a.i
		local u = if b.i ~= a.i then f * b.u else a.u + (b.u - a.u) * f
		local p = pos(i, u)
		local rot = keys[i].cf.Rotation:Lerp(keys[i + 1].cf.Rotation, u)
		local lens = keys[i].fov + (keys[i + 1].fov - keys[i].fov) * u
		return CFrame.new(p) * rot, lens
	end
end

local function ease(t: number): number
	return t * t * (3 - 2 * t)
end

local playToken = 0
local function playPath()
	local p = path()
	if #p.keys == 0 then
		toast(`slot {slot}: no points (K adds one)`)
		return
	end
	playToken += 1
	local token = playToken
	playing = true
	local at = sampler(p.keys)
	camCF, fov = at(0)
	local start = os.clock()
	task.spawn(function()
		while playToken == token do
			local t = math.min(1, (os.clock() - start) / p.time)
			camCF, fov = at(ease(t))
			if t >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
		if playToken == token then
			playing = false
		end
	end)
end

local function stopPath()
	playToken += 1
	playing = false
end

local function syncFlyAngles()
	local x, y = camCF:ToEulerAnglesYXZ()
	pitch, yaw = math.deg(x), math.deg(y)
end

local function setFlying(on: boolean)
	flying = on
	local r = root()
	if r then
		r.Anchored = on
	end
	if on then
		camCF, fov = camera.CFrame, camera.FieldOfView
		syncFlyAngles()
	end
	Input.setEnabled("MenuContext", on) -- sinks gameplay keys while the keyboard drives the camera
end

local function cameraActive(): boolean
	return active and (flying or playing)
end

local function printPath()
	local p = path()
	local lines = { `-- trailer path slot {slot}: {p.time} s` }
	for _, k in p.keys do
		local c = { k.cf:GetComponents() }
		for i, v in c do
			c[i] = string.format("%.3f", v)
		end
		table.insert(lines, `\t\{ cf = CFrame.new({table.concat(c, ", ")}), fov = {string.format("%.1f", k.fov)} \},`)
	end
	print(table.concat(lines, "\n"))
	toast(`slot {slot}: {#p.keys} points printed to the output`)
end

-- ghost take: samples the character + its playing animation tracks, sends them to the server in chunks
local function recordGhost(secs: number)
	if recording then
		recording = false
		return
	end
	local c = player.Character
	local humanoid = c and c:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	local r = root()
	if not (humanoid and animator and r) then
		return
	end
	recording = true
	task.spawn(function()
		for n = T.Countdown, 1, -1 do
			toast(`GHOST TAKE IN {n}`, 0.9)
			task.wait(1)
			if not recording then
				toast("ghost take cancelled")
				return
			end
		end
		toastLabel.Visible = false
		local hip = humanoid.HipHeight + r.Size.Y / 2
		local samples = {}
		local first = true
		local function flush(last: boolean)
			Net.event("TrailerGhost"):FireServer(first, last, hip, samples)
			first = false
			samples = {}
		end
		local stopAt = os.clock() + secs
		local step = 1 / T.GhostRate
		local nextAt = os.clock()
		local count = 0
		while recording and os.clock() < stopAt and r.Parent do
			if os.clock() >= nextAt then
				nextAt += step
				local tracks = {}
				for _, tr in animator:GetPlayingAnimationTracks() do
					if tr.Animation and tr.WeightCurrent > 0.05 then
						table.insert(tracks, { id = tr.Animation.AnimationId, t = tr.TimePosition, speed = tr.Speed })
					end
				end
				table.insert(samples, { cf = r.CFrame, tracks = tracks })
				count += 1
				if #samples >= T.GhostChunk then
					flush(false)
				end
			end
			RunService.Heartbeat:Wait()
		end
		recording = false
		flush(true)
		toast(`ghost take: {string.format("%.1f", count / T.GhostRate)} s (/ghost play)`)
	end)
end

local function setActive(on: boolean)
	if on == active then
		return
	end
	active = on
	if on then
		setUiHidden(true)
		toast("TRAILER MODE · End = leave · V fly · K point · P play")
	else
		stopPath()
		recording = false
		if flying then
			setFlying(false)
		end
		if charHidden then
			setCharHidden(false)
		end
		setUiHidden(false)
		overriding = false
		CameraController.SetOverride(nil)
	end
end

local KEYS: { [Enum.KeyCode]: () -> () } = {
	[Enum.KeyCode.End] = function()
		setActive(false)
	end,
	[Enum.KeyCode.U] = function()
		setUiHidden(not uiHidden)
	end,
	[Enum.KeyCode.V] = function()
		setFlying(not flying)
		toast(if flying then "fly camera" else "camera back on the character")
	end,
	[Enum.KeyCode.K] = function()
		local p = path()
		table.insert(p.keys, { cf = camera.CFrame, fov = camera.FieldOfView })
		toast(`slot {slot}: point {#p.keys}`)
	end,
	[Enum.KeyCode.J] = function()
		local p = path()
		table.remove(p.keys)
		toast(`slot {slot}: {#p.keys} points`)
	end,
	[Enum.KeyCode.Delete] = function()
		paths[slot] = nil
		toast(`slot {slot} cleared`)
	end,
	[Enum.KeyCode.LeftBracket] = function()
		local p = path()
		p.time = math.max(1, p.time - 1)
		toast(`slot {slot}: {p.time} s`)
	end,
	[Enum.KeyCode.RightBracket] = function()
		local p = path()
		p.time += 1
		toast(`slot {slot}: {p.time} s`)
	end,
	[Enum.KeyCode.P] = function()
		if playing then
			stopPath()
			if flying then
				syncFlyAngles()
			end
		else
			playPath()
		end
	end,
	[Enum.KeyCode.O] = printPath,
	[Enum.KeyCode.H] = function()
		setCharHidden(not charHidden)
	end,
	[Enum.KeyCode.G] = function()
		recordGhost(15)
	end,
}
local SLOTS = {
	Enum.KeyCode.One,
	Enum.KeyCode.Two,
	Enum.KeyCode.Three,
	Enum.KeyCode.Four,
	Enum.KeyCode.Five,
	Enum.KeyCode.Six,
	Enum.KeyCode.Seven,
	Enum.KeyCode.Eight,
	Enum.KeyCode.Nine,
}

function TrailerController.Init()
	toastGui.Parent = player:WaitForChild("PlayerGui")

	Net.event("Trailer").OnClientEvent:Connect(function(what: string, arg: any)
		if what == "Toggle" then
			setActive(not active)
		elseif what == "Record" and active then
			recordGhost(tonumber(arg) or 15)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not active or processed then
			return
		end
		local fn = KEYS[input.KeyCode]
		if fn then
			fn()
			return
		end
		local n = table.find(SLOTS, input.KeyCode)
		if n then
			slot = n
			toast(`slot {slot}: {#path().keys} points, {path().time} s`)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not (active and flying) then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			speedScale = math.clamp(speedScale * (if input.Position.Z > 0 then 1.25 else 0.8), 0.05, 20)
			toast(`fly speed ×{string.format("%.2f", speedScale)}`, 0.6)
		elseif
			input.UserInputType == Enum.UserInputType.MouseMovement
			and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
			and not playing
		then
			yaw -= input.Delta.X * T.LookSpeed
			pitch = math.clamp(pitch - input.Delta.Y * T.LookSpeed, -89, 89)
		end
	end)

	player.CharacterAdded:Connect(function()
		if active and charHidden then
			task.wait(0.5)
			setCharHidden(true)
		end
	end)

	-- after CameraController (Camera + 1): our CFrame wins exactly, no follow lag
	RunService:BindToRenderStep("TrailerCamera", Enum.RenderPriority.Camera.Value + 2, function(dt)
		if not active then
			return
		end
		enforceHidden()
		if flying and not playing then
			local move = Vector3.zero
			local k = UserInputService
			if k:IsKeyDown(Enum.KeyCode.W) then
				move += Vector3.new(0, 0, -1)
			end
			if k:IsKeyDown(Enum.KeyCode.S) then
				move += Vector3.new(0, 0, 1)
			end
			if k:IsKeyDown(Enum.KeyCode.A) then
				move += Vector3.new(-1, 0, 0)
			end
			if k:IsKeyDown(Enum.KeyCode.D) then
				move += Vector3.new(1, 0, 0)
			end
			local rise = (if k:IsKeyDown(Enum.KeyCode.E) then 1 else 0) - (if k:IsKeyDown(Enum.KeyCode.Q) then 1 else 0)
			local speed = T.FlySpeed * speedScale * (if k:IsKeyDown(Enum.KeyCode.LeftShift) then T.FlyFast else 1)
			local rot = CFrame.fromEulerAnglesYXZ(math.rad(pitch), math.rad(yaw), 0)
			local pos = camCF.Position + (rot:VectorToWorldSpace(move) + Vector3.new(0, rise, 0)) * speed * dt
			camCF = CFrame.new(pos) * rot
			local zoom = (if k:IsKeyDown(Enum.KeyCode.X) then 1 else 0) - (if k:IsKeyDown(Enum.KeyCode.Z) then 1 else 0)
			fov = math.clamp(fov + zoom * 30 * dt, T.FovMin, T.FovMax)
		end
		if cameraActive() then
			if not overriding then
				overriding = true
				CameraController.SetOverride(function()
					return camCF
				end)
			end
			camera.CameraType = Enum.CameraType.Scriptable
			camera.CFrame = camCF
			camera.FieldOfView = fov
			-- StreamingEnabled: load what the camera sees (throttled; the request yields)
			if os.clock() >= nextStream and (camCF.Position - streamedAt).Magnitude > 48 then
				nextStream = os.clock() + 1
				streamedAt = camCF.Position
				task.spawn(pcall, player.RequestStreamAroundAsync, player, streamedAt)
			end
		elseif overriding then
			overriding = false
			CameraController.SetOverride(nil)
		end
	end)
end

return TrailerController
