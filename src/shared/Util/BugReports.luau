-- Beta bug reports (user, Oct 19), both places. A tester writes a short note (bug button by the gear while
-- Config/Beta is on, or "/bug <text>" in chat); the game adds where and how: place, world, checkpoint, position,
-- device, players in the server, place version, the last client errors. Saved to the DataStore "BugReports" (only the
-- team reads them: `python tools/beta/bugs.py`), never shown to other players. Notes still pass Roblox's text filter.
--   server: BugReports.InitServer(context?)   context(player) -> extra fields (adventure: checkpoint)
--   client: BugReports.InitClient()           the button + the note box
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Beta = require(ReplicatedStorage.Shared.Config.Beta)
local Net = require(ReplicatedStorage.Shared.Net)

local BugReports = {}

local MAX_TEXT = 400
local GAP = 20 -- seconds between two reports from one player
local PER_SERVER = 25 -- reports one player can send per server

-- Server ----------------------------------------------------------------------------------------------------------

function BugReports.InitServer(context: ((Player) -> { [string]: any })?)
	local DataStoreService = game:GetService("DataStoreService")
	local HttpService = game:GetService("HttpService")
	local TextService = game:GetService("TextService")
	local store = DataStoreService:GetDataStore("BugReports")
	local remote = Net.event("BugReport")
	local openBox = Net.event("BugOpen")
	local last: { [Player]: number } = {}
	local count: { [Player]: number } = {}

	local function save(p: Player, text: string, client: { [string]: any }?)
		text = string.sub(text, 1, MAX_TEXT)
		if #text:gsub("%s", "") < 3 then
			return false, "Write a few words about the bug."
		end
		if os.clock() - (last[p] or -GAP) < GAP or (count[p] or 0) >= PER_SERVER then
			return false, "Thanks! Wait a moment before the next report."
		end
		last[p] = os.clock()
		count[p] = (count[p] or 0) + 1
		local ok, filtered = pcall(function()
			return TextService:FilterStringAsync(text, p.UserId):GetNonChatStringForBroadcastAsync()
		end)
		local root = p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local others = {}
		for _, o in Players:GetPlayers() do
			if o ~= p then
				table.insert(others, o.Name)
			end
		end
		local c = client or {}
		local report = {
			text = if ok then filtered else "(filter failed)",
			user = p.Name,
			userId = p.UserId,
			time = os.time(),
			place = if workspace:GetAttribute("World") then "Adventure" else "Lobby",
			placeVersion = game.PlaceVersion,
			jobId = game.JobId,
			world = workspace:GetAttribute("World"),
			pos = root and string.format("%.0f, %.0f, %.0f", root.Position.X, root.Position.Y, root.Position.Z),
			others = others,
			device = typeof(c.device) == "string" and string.sub(c.device, 1, 20) or nil,
			errors = typeof(c.errors) == "table" and c.errors or nil,
		}
		if context then
			local okC, extra = pcall(context, p)
			if okC and typeof(extra) == "table" then
				for k, v in extra do
					report[k] = v
				end
			end
		end
		-- client errors: at most 5 strings of 200 characters
		if report.errors then
			local clean = {}
			for i, e in report.errors do
				if i > 5 then
					break
				end
				if typeof(e) == "string" then
					table.insert(clean, string.sub(e, 1, 200))
				end
			end
			report.errors = clean
		end
		local key = `{os.time()}_{p.UserId}_{HttpService:GenerateGUID(false):sub(1, 6)}`
		local okS, err = pcall(function()
			store:SetAsync(key, report)
		end)
		if not okS then
			warn("[BugReports] save failed:", err)
			return false, "Couldn't send it, try again in a minute."
		end
		return true, "Thanks! Bug report sent."
	end

	remote.OnServerEvent:Connect(function(p: Player, text: any, client: any)
		if typeof(text) ~= "string" then
			return
		end
		local ok, msg = save(p, text, if typeof(client) == "table" then client else nil)
		remote:FireClient(p, ok, msg)
	end)

	-- "/bug" opens the box; "/bug <text>" sends at once (Player.Chatted fires with both chat systems)
	local function hook(p: Player)
		p.Chatted:Connect(function(message)
			local rest = message:match("^/bug%s*(.*)$")
			if rest == nil then
				return
			end
			if rest == "" then
				openBox:FireClient(p)
			else
				openBox:FireClient(p, rest)
			end
		end)
	end
	Players.PlayerAdded:Connect(hook)
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		last[p] = nil
		count[p] = nil
	end)
end

-- Client ----------------------------------------------------------------------------------------------------------

function BugReports.InitClient()
	if not RunService:IsClient() then
		return
	end
	local LogService = game:GetService("LogService")
	local Glyphs = require(ReplicatedStorage.Shared.Util.Glyphs)
	local UiFit = require(ReplicatedStorage.Shared.Util.UiFit)
	local player = Players.LocalPlayer
	local remote = Net.event("BugReport")
	local openBox = Net.event("BugOpen")

	-- the last client errors ride along with each report
	local errors: { string } = {}
	LogService.MessageOut:Connect(function(msg, kind)
		if kind == Enum.MessageType.MessageError then
			table.insert(errors, msg)
			if #errors > 5 then
				table.remove(errors, 1)
			end
		end
	end)

	local gui = Instance.new("ScreenGui")
	gui.Name = "BugReport"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 31
	gui.Parent = player:WaitForChild("PlayerGui")
	UiFit.attach(gui)

	local function corner(inst: Instance, r: number)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, r)
		c.Parent = inst
	end

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.45)
	panel.Size = UDim2.fromOffset(460, 270)
	panel.BackgroundColor3 = Color3.fromRGB(22, 24, 44)
	panel.BackgroundTransparency = 0.05
	panel.Visible = false
	panel.Parent = gui
	corner(panel, 14)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 200, 61)
	stroke.Thickness = 2
	stroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(18, 10)
	title.Size = UDim2.new(1, -36, 0, 34)
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 26
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(255, 200, 61)
	title.Text = "REPORT A BUG"
	title.Parent = panel

	local hint = Instance.new("TextLabel")
	hint.BackgroundTransparency = 1
	hint.Position = UDim2.fromOffset(18, 42)
	hint.Size = UDim2.new(1, -36, 0, 22)
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 15
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.TextColor3 = Color3.fromRGB(200, 205, 230)
	hint.Text = "What happened? We save where you are automatically."
	hint.Parent = panel

	local box = Instance.new("TextBox")
	box.Position = UDim2.fromOffset(18, 70)
	box.Size = UDim2.new(1, -36, 0, 120)
	box.BackgroundColor3 = Color3.fromRGB(38, 42, 70)
	box.TextColor3 = Color3.new(1, 1, 1)
	box.PlaceholderColor3 = Color3.fromRGB(140, 145, 175)
	box.PlaceholderText = "e.g. I fell through the floor after the big crusher"
	box.Font = Enum.Font.Gotham
	box.TextSize = 17
	box.TextWrapped = true
	box.MultiLine = true
	box.ClearTextOnFocus = false
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.TextYAlignment = Enum.TextYAlignment.Top
	box.Text = ""
	box.Parent = panel
	corner(box, 8)
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.PaddingTop = UDim.new(0, 8)
	pad.Parent = box
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if #box.Text > MAX_TEXT then
			box.Text = string.sub(box.Text, 1, MAX_TEXT)
		end
	end)

	local status = Instance.new("TextLabel")
	status.BackgroundTransparency = 1
	status.Position = UDim2.fromOffset(18, 222)
	status.Size = UDim2.new(0.5, -18, 0, 34)
	status.Font = Enum.Font.Gotham
	status.TextSize = 15
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextColor3 = Color3.fromRGB(200, 205, 230)
	status.TextWrapped = true
	status.Text = ""
	status.Parent = panel

	local function button(text: string, x: number, color: Color3): TextButton
		local b = Instance.new("TextButton")
		b.AnchorPoint = Vector2.new(1, 0)
		b.Position = UDim2.new(1, x, 0, 206)
		b.Size = UDim2.fromOffset(110, 44)
		b.BackgroundColor3 = color
		b.Font = Enum.Font.FredokaOne
		b.TextSize = 20
		b.TextColor3 = Color3.fromRGB(22, 24, 44)
		b.Text = text
		b.Parent = panel
		corner(b, 10)
		return b
	end
	local send = button("SEND", -18, Color3.fromRGB(255, 200, 61))
	local cancel = button("CLOSE", -136, Color3.fromRGB(200, 205, 230))

	local busy = false
	local function open(text: string?)
		panel.Visible = true
		player:SetAttribute("FreeCursor", true) -- adventure CameraController unlocks the mouse
		status.Text = ""
		if text then
			box.Text = text
		end
		box:CaptureFocus()
	end
	local function close()
		panel.Visible = false
		player:SetAttribute("FreeCursor", nil)
		box:ReleaseFocus()
	end
	local function submit()
		if busy then
			return
		end
		busy = true
		status.Text = "Sending..."
		remote:FireServer(box.Text, { device = Glyphs.device(), errors = errors })
	end
	send.Activated:Connect(submit)
	cancel.Activated:Connect(close)
	remote.OnClientEvent:Connect(function(ok: boolean, msg: string)
		busy = false
		status.Text = msg
		if ok then
			box.Text = ""
			task.delay(1.6, function()
				if box.Text == "" then
					close()
				end
			end)
		end
	end)
	openBox.OnClientEvent:Connect(function(text: string?)
		if text then
			-- "/bug <text>": send straight away
			box.Text = text
			open()
			submit()
		else
			open()
		end
	end)

	-- the bug button: left of the settings gear, only during the closed beta
	if Beta.Enabled then
		local bug = Instance.new("TextButton")
		bug.Name = "BugButton"
		bug.AnchorPoint = Vector2.new(1, 0)
		bug.Position = UDim2.new(1, -72, 0, 10)
		bug.Size = UDim2.fromOffset(78, 38)
		bug.BackgroundColor3 = Color3.fromRGB(22, 24, 44)
		bug.BackgroundTransparency = 0.25
		bug.Font = Enum.Font.FredokaOne
		bug.TextSize = 17
		bug.TextColor3 = Color3.fromRGB(255, 200, 61)
		bug.Text = "BUG?"
		bug.Parent = gui
		corner(bug, 10)
		bug.Activated:Connect(function()
			if panel.Visible then
				close()
			else
				open()
			end
		end)
		-- PC in the adventure: the mouse is locked for the camera; say how to free it (CameraController)
		local UserInputService = game:GetService("UserInputService")
		if UserInputService.MouseEnabled and not UserInputService.TouchEnabled then
			local tip = Instance.new("TextLabel")
			tip.AnchorPoint = Vector2.new(1, 0)
			tip.Position = UDim2.new(1, -72, 0, 50)
			tip.Size = UDim2.fromOffset(150, 18)
			tip.BackgroundTransparency = 1
			tip.Font = Enum.Font.GothamMedium
			tip.TextSize = 13
			tip.TextXAlignment = Enum.TextXAlignment.Right
			tip.TextColor3 = Color3.fromRGB(230, 232, 245)
			tip.TextStrokeTransparency = 0.5
			tip.Text = "middle-click: free mouse"
			tip.Parent = gui
			-- adventure only (workspace World arrives after the client starts; the lobby's mouse is free anyway)
			local function show()
				tip.Visible = workspace:GetAttribute("World") ~= nil
			end
			workspace:GetAttributeChangedSignal("World"):Connect(show)
			show()
		end
	end
end

return BugReports
