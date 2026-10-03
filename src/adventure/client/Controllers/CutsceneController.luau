-- Plays cutscenes sent by CutsceneService: letterbox, camera path (ReplicatedStorage.Cutscenes.<id>/1,2,3…),
-- dialogue lines, and a skip vote (both players must press Skip).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage.Shared.Net)
local UiSkin = require(ReplicatedStorage.Shared.Util.UiSkin)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)
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
		skipHint.Text = `SPACE skip {votes}/2`
	end
	workspace:GetAttributeChangedSignal("SkipVotes"):Connect(refreshSkip)

	Input.action("MenuContext", "Skip").Pressed:Connect(function()
		if playingId then
			Net.event("SkipVote"):FireServer()
		end
	end)

	-- Shots come from the server (built from the loaded world) or, for story scenes, ReplicatedStorage.Cutscenes.<id>.
	-- The camera glides from where it is through each shot, then back to where it started, and only then is the
	-- cutscene done on this client.
	type Shot = { CFrame: CFrame, Duration: number }
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
		for _, shot in list do
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
