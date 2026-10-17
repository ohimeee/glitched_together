-- Plays cutscenes sent by CutsceneService: letterbox, camera path (ReplicatedStorage.Cutscenes.<id>/1,2,3…),
-- dialogue lines, and a skip vote (both players must press Skip).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage.Shared.Net)
local UiSkin = require(ReplicatedStorage.Shared.Util.UiSkin)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)
local Glyphs = require(ReplicatedStorage.Shared.Util.Glyphs)
local Roles = require(ReplicatedStorage.Shared.Config.Roles)
local Input = require(script.Parent.Parent.Input)
local CameraController = require(script.Parent.CameraController)

local player = Players.LocalPlayer

local CutsceneController = {}

local LINE_TIME = 3.2
local LINE_CPS = 40 -- typewriter speed, characters per second
local playingId: string? = nil
local token = 0

local SPEAKER_COLORS = {
	Pip = Color3.fromRGB(255, 220, 90),
	["???"] = Palette.Glitch,
}

local function speakerColor(name: string): Color3
	local role = (Roles :: any)[name]
	return if role then role.Color else SPEAKER_COLORS[name] or Color3.new(1, 1, 1)
end

function CutsceneController.Init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "Cutscene"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	-- full-bleed: IgnoreGuiInset only drops the top bar; phones also inset round the notch (black edges showed)
	gui.ScreenInsets = Enum.ScreenInsets.None
	gui.DisplayOrder = 10
	gui.Enabled = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local function bar(y: number): Frame
		local f = Instance.new("Frame")
		f.BackgroundColor3 = Color3.new(0, 0, 0)
		f.BorderSizePixel = 0
		f.Size = UDim2.new(1, 0, 0.12, 0)
		f.Position = UDim2.fromScale(0, y)
		f.Parent = gui
		return f
	end
	bar(0)
	local bottom = bar(0.88)

	local speaker = Instance.new("TextLabel")
	speaker.BackgroundTransparency = 1
	speaker.Font = Enum.Font.FredokaOne
	speaker.TextScaled = true
	speaker.Size = UDim2.new(0.6, 0, 0.3, 0)
	speaker.Position = UDim2.fromScale(0.2, 0.02)
	speaker.TextXAlignment = Enum.TextXAlignment.Left
	speaker.Parent = bottom
	local line = speaker:Clone()
	line.Size = UDim2.new(0.6, 0, 0.55, 0)
	line.Position = UDim2.fromScale(0.2, 0.35)
	line.TextColor3 = Color3.new(1, 1, 1)
	line.Parent = bottom
	local skipHint = speaker:Clone()
	skipHint.Size = UDim2.new(0.18, 0, 0.3, 0)
	skipHint.Position = UDim2.fromScale(0.8, 0.6)
	skipHint.TextXAlignment = Enum.TextXAlignment.Right
	skipHint.TextColor3 = Color3.fromRGB(180, 180, 200)
	skipHint.Parent = bottom

	-- world-themed: the speaker is a sticker chip in their color, lines use the world's font (UiTheme)
	speaker.Size = UDim2.new(0.16, 0, 0.26, 0)
	speaker.Position = UDim2.fromScale(0.2, 0.04)
	speaker.TextXAlignment = Enum.TextXAlignment.Center
	local chipPad = Instance.new("UIPadding")
	chipPad.PaddingTop = UDim.new(0, 4)
	chipPad.PaddingBottom = UDim.new(0, 4)
	chipPad.Parent = speaker
	UiSkin.Panel(speaker, { NoShadow = true })
	UiSkin.Text(speaker, "Title")
	UiSkin.Text(line, "Float", Color3.new(1, 1, 1))
	UiSkin.Text(skipHint, "Float", Color3.fromRGB(180, 180, 200))
	line.Position = UDim2.fromScale(0.2, 0.38)
	line.Size = UDim2.new(0.6, 0, 0.5, 0)
	line.TextWrapped = true

	local function refreshSkip()
		local votes = workspace:GetAttribute("SkipVotes") or 0
		skipHint.Text = if Glyphs.device() == "Touch"
			then `TAP to skip {votes}/2`
			else `{Glyphs.key("Skip")} skip {votes}/2` -- SPACE / A
	end
	workspace:GetAttributeChangedSignal("SkipVotes"):Connect(refreshSkip)
	Glyphs.Changed:Connect(refreshSkip)

	-- phones: a tap anywhere votes to skip (behind the bars and text, so it never blocks the SKIP button)
	local tapCatcher = Instance.new("TextButton")
	tapCatcher.Name = "TapToSkip"
	tapCatcher.Size = UDim2.fromScale(1, 1)
	tapCatcher.BackgroundTransparency = 1
	tapCatcher.Text = ""
	tapCatcher.ZIndex = 0
	tapCatcher.Parent = gui
	tapCatcher.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch and playingId then
			Net.event("SkipVote"):FireServer()
		end
	end)

	Input.action("MenuContext", "Skip").Pressed:Connect(function()
		if playingId then
			Net.event("SkipVote"):FireServer()
		end
	end)

	-- Shots come from the server (built from the loaded world) or, for story scenes, ReplicatedStorage.Cutscenes.<id>.
	-- The camera glides from where it is through each shot, then back to where it started, and only then is the
	-- cutscene done on this client.
	-- A run of `Glide` shots is one drone flight (user, Oct 12: "each boss should have intro camera or that drone view
	-- so they will appreciate the arts"): the camera flows through them on a Catmull-Rom curve without stopping, eased
	-- only at the start and end of the whole run. Other shots glide in and settle (Sine in/out per shot).
	type Shot = { CFrame: CFrame, Duration: number, Glide: boolean? }
	local function catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
		local t2, t3 = t * t, t * t * t
		return 0.5
			* ((2 * p1) + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (3 * p1 - p0 - 3 * p2 + p3) * t3)
	end
	local function playCamera(id: string, myToken: number, shots: { Shot }?)
		local list: { Shot } = shots or {}
		if #list == 0 then
			local folder = ReplicatedStorage:FindFirstChild("Cutscenes")
			local path = folder and folder:FindFirstChild(id)
			if not path then
				return
			end
			local points = path:GetChildren()
			table.sort(points, function(a, b)
				return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
			end)
			for _, p in points do
				if p:IsA("BasePart") then
					table.insert(list, { CFrame = p.CFrame, Duration = (p:GetAttribute("Duration") or 2) :: number })
				end
			end
		end
		if #list == 0 then
			return
		end
		local camera = workspace.CurrentCamera
		local home = camera.CFrame
		local cam = home
		CameraController.SetOverride(function()
			return cam
		end)
		table.insert(list, { CFrame = home, Duration = 1.2 })
		local i = 1
		while i <= #list do
			if list[i].Glide then
				local pts: { CFrame } = { cam }
				local total = 0
				while i <= #list and list[i].Glide do
					table.insert(pts, list[i].CFrame)
					total += list[i].Duration
					i += 1
				end
				-- constant drone speed: pace by distance along the curve (an arc-length table), not time per shot
				-- (measured Oct 12: per-shot timing slowed it ~45% at every waypoint)
				local function at(k: number, s: number): Vector3
					local a, b = pts[k], pts[k + 1]
					return catmull((pts[k - 1] or a).Position, a.Position, b.Position, (pts[k + 2] or b).Position, s)
				end
				local lut: { { number } } = { { 0, 1, 0 } } -- { distance, segment, s }
				local length = 0
				for k = 1, #pts - 1 do
					local prev = at(k, 0)
					for step = 1, 24 do
						local s = step / 24
						local p = at(k, s)
						length += (p - prev).Magnitude
						prev = p
						table.insert(lut, { length, k, s })
					end
				end
				local t0 = os.clock()
				local j = 1
				while os.clock() - t0 < total and token == myToken do
					local d = TweenService:GetValue(
						(os.clock() - t0) / total,
						Enum.EasingStyle.Sine,
						Enum.EasingDirection.InOut
					) * length
					while j < #lut - 1 and lut[j + 1][1] < d do
						j += 1
					end
					local lo, hi = lut[j], lut[j + 1] or lut[j]
					local f = if hi[1] > lo[1] then math.clamp((d - lo[1]) / (hi[1] - lo[1]), 0, 1) else 0
					local k = hi[2]
					local s = if hi[2] == lo[2] then lo[3] + (hi[3] - lo[3]) * f else hi[3] * f
					cam = CFrame.new(at(k, s)) * pts[k].Rotation:Lerp(pts[k + 1].Rotation, s)
					task.wait()
				end
				if token ~= myToken then
					return
				end
				cam = pts[#pts]
				continue
			end
			local shot = list[i]
			i += 1
			local start = cam
			local t0 = os.clock()
			while os.clock() - t0 < shot.Duration and token == myToken do
				local alpha = (os.clock() - t0) / shot.Duration
				cam = start:Lerp(
					shot.CFrame,
					TweenService:GetValue(alpha, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				)
				task.wait()
			end
			if token ~= myToken then
				return
			end
		end
	end

	Net.event("Cutscene").OnClientEvent
		:Connect(function(id: string?, lines: { { Speaker: string, Text: string } }?, shots: { Shot }?)
			token += 1
			local myToken = token
			if not id then
				playingId = nil
				gui.Enabled = false
				Input.setEnabled("MenuContext", false)
				CameraController.SetOverride(nil)
				return
			end
			playingId = id
			gui.Enabled = true
			Input.setEnabled("MenuContext", true)
			refreshSkip()
			local cameraDone = false
			task.spawn(function()
				playCamera(id, myToken, shots)
				cameraDone = true
			end)
			for _, l in lines or {} do
				if token ~= myToken then
					return
				end
				speaker.Text = l.Speaker
				UiSkin.Panel(speaker, { NoShadow = true, Fill = speakerColor(l.Speaker) })
				UiSkin.SetTextColor(speaker, Color3.fromRGB(25, 22, 40))
				line.Text = l.Text
				line.MaxVisibleGraphemes = 0
				if l.Speaker == "???" then
					Audio.play("GlitchCrackle") -- the Glitch speaking: always a crackle (art-direction.md §7)
				end
				local total = utf8.len(l.Text) or #l.Text
				local t0 = os.clock()
				local bleeped = 0
				while token == myToken and os.clock() - t0 < LINE_TIME do
					local shown = math.floor((os.clock() - t0) * LINE_CPS)
					line.MaxVisibleGraphemes = if shown >= total then -1 else shown
					-- Pip talks in bleeps (design.md §8), one every few letters while the text types out
					if l.Speaker == "Pip" and shown < total and shown - bleeped >= 3 then
						bleeped = shown
						Audio.play("PipBleep")
					end
					task.wait()
				end
				line.MaxVisibleGraphemes = -1
			end
			while token == myToken and not cameraDone do
				task.wait() -- a fly-over can outlast its lines
			end
			if token == myToken then
				Net.event("CutsceneDone"):FireServer()
			end
		end)
end

return CutsceneController
