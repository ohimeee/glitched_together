-- Plays cutscenes sent by CutsceneService: letterbox, camera path (ReplicatedStorage.Cutscenes.<id>/1,2,3…),
-- dialogue lines, and a skip vote (both players must press Skip).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage.Shared.Net)
local Roles = require(ReplicatedStorage.Shared.Config.Roles)
local Input = require(script.Parent.Parent.Input)
local CameraController = require(script.Parent.CameraController)

local player = Players.LocalPlayer

local CutsceneController = {}

local LINE_TIME = 3.2
local playingId: string? = nil
local token = 0

local SPEAKER_COLORS = {
	Pip = Color3.fromRGB(255, 220, 90),
	["???"] = Color3.fromRGB(255, 80, 170),
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

	local function playCamera(id: string, myToken: number)
		local folder = ReplicatedStorage:FindFirstChild("Cutscenes")
		local path = folder and folder:FindFirstChild(id)
		if not path then
			return
		end
		local points = path:GetChildren()
		table.sort(points, function(a, b)
			return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
		end)
		local camera = workspace.CurrentCamera
		local cam = camera.CFrame
		CameraController.SetOverride(function()
			return cam
		end)
		for _, p in points do
			if token ~= myToken then
				return
			end
			if p:IsA("BasePart") then
				local duration = (p:GetAttribute("Duration") or 2) :: number
				local start = cam
				local t0 = os.clock()
				while os.clock() - t0 < duration and token == myToken do
					local alpha = (os.clock() - t0) / duration
					cam = start:Lerp(
						p.CFrame,
						TweenService:GetValue(alpha, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
					)
					task.wait()
				end
			end
		end
	end

	Net.event("Cutscene").OnClientEvent:Connect(function(id: string?, lines: { { Speaker: string, Text: string } }?)
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
		task.spawn(playCamera, id, myToken)
		for _, l in lines or {} do
			if token ~= myToken then
				return
			end
			speaker.Text = l.Speaker
			speaker.TextColor3 = speakerColor(l.Speaker)
			line.Text = l.Text
			task.wait(LINE_TIME)
		end
		if token == myToken then
			Net.event("CutsceneDone"):FireServer()
		end
	end)
end

return CutsceneController
