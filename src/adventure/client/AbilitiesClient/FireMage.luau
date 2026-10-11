-- Kai's Fire Mage, client half (server: AbilitiesServer/FireMage). Top-down aim at the mouse / right stick.
--   Tool1 (hold)   Fireball auto-fire          Tool2   Flame Wall at the aim point
--   Tool1 + Tool2  Meteor when Ultimate is full Ignite (E) nearest Brazier / Burnable to the aim point
--   Dash           Blink 10 studs (passes through IronBars and BlinkThrough hazards), then tells the server (Ember Trail)
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local Net = require(ReplicatedStorage.Shared.Net)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local Input = require(script.Parent.Parent.Input)
local TopDownAim = require(script.Parent.Parent.TopDownAim)
local MoveAnim = require(script.Parent.Parent.Controllers.MoveAnimController)
local KeyPrompt = require(script.Parent.Parent.Controllers.KeyPromptController)

local player = Players.LocalPlayer
local toolUse = Net.event("ToolUse")
local T = Tuning.FireMage

local FireMage = {}
local trove = Trove.new()

local function rootOf(): BasePart?
	local c = player.Character
	return c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function busy(): boolean
	return player:GetAttribute("Downed") == true or player:GetAttribute("Picking") == true
end

local function ultimateReady(): boolean
	return ((player:GetAttribute("Ultimate") or 0) :: number) >= 1
end

local function blink(lastBlink: { t: number })
	local root = rootOf()
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not (root and hum) or busy() or os.clock() - lastBlink.t < T.Blink.Cooldown then
		return
	end
	lastBlink.t = os.clock()
	local dir = if hum.MoveDirection.Magnitude > 0.1
		then Vector3.new(hum.MoveDirection.X, 0, hum.MoveDirection.Z).Unit
		else TopDownAim.direction()
	local exclude: { Instance } = { character :: Model }
	for _, tag in { "IronBars", "BlinkThrough" } do
		for _, inst in CollectionService:GetTagged(tag) do
			table.insert(exclude, inst)
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = exclude
	params.RespectCanCollide = true
	local dist = T.Blink.Distance
	local hit = workspace:Raycast(root.Position, dir * dist, params)
	if hit then
		dist = math.max(0, hit.Distance - 1.5)
	end
	local from = root.Position
	root.CFrame = root.CFrame + dir * dist
	root.AssemblyLinearVelocity = Vector3.zero
	for _, pos in { from, root.Position } do
		local puff = Instance.new("Part")
		puff.Shape = Enum.PartType.Ball
		puff.Size = Vector3.one * 3
		puff.Material = Enum.Material.Neon
		puff.Color = Palette.Glow.Kai
		puff.Transparency = 0.4
		puff.Anchored = true
		puff.CanCollide = false
		puff.CanQuery = false
		puff.CFrame = CFrame.new(pos)
		puff.Parent = workspace
		task.delay(0.2, puff.Destroy, puff)
	end
	toolUse:FireServer(5, nil, from)
end

local function nearestIgnitable(): Instance?
	local root = rootOf()
	if not root then
		return nil
	end
	local aim = TopDownAim.point()
	local best: Instance?, bestD = nil, math.huge
	for _, tag in { "Brazier", "Burnable", "GolemPillar", "FuseStart", "FuseBreak" } do
		for _, inst in CollectionService:GetTagged(tag) do
			if inst:IsDescendantOf(workspace) and not inst:GetAttribute("Lit") then
				local pos = Tags.position(inst)
				if (pos - root.Position).Magnitude <= T.Ignite.Range then
					local d = (pos - aim).Magnitude
					if d < bestD then
						best, bestD = inst, d
					end
				end
			end
		end
	end
	return best
end

function FireMage:Start()
	TopDownAim.Start(Palette.Kai)
	local fire = Input.action("CastleTools", "Tool1")
	local wall = Input.action("CastleTools", "Tool2")
	local lastBlink = { t = -math.huge }

	local hand = 1 -- auto-fire throws with alternating hands
	local lastWall, lastIgnite = -math.huge, -math.huge -- the cast animation only plays when the server will cast
	local function meteor(): boolean
		if fire:IsDown() and wall:IsDown() and ultimateReady() then
			MoveAnim.Play("CastMeteor")
			toolUse:FireServer(4, nil, TopDownAim.point())
			return true
		end
		return false
	end

	trove:Add(fire.Pressed:Connect(function()
		if busy() or meteor() then
			return
		end
		task.spawn(function()
			while fire:IsDown() and not busy() do
				if wall:IsDown() then
					break
				end
				MoveAnim.Play(if hand > 0 then "CastFireR" else "CastFireL")
				hand = -hand
				toolUse:FireServer(1, nil, TopDownAim.point())
				local cooldown = if player:GetAttribute("Up_FasterCast")
					then Tuning.Combat.FasterCast
					else T.Fireball.Cooldown
				task.wait(cooldown)
			end
		end)
	end))
	trove:Add(wall.Pressed:Connect(function()
		if busy() or meteor() then
			return
		end
		if os.clock() - lastWall >= T.FlameWall.Cooldown then
			lastWall = os.clock()
			MoveAnim.Play("CastWall")
		end
		toolUse:FireServer(2, nil, TopDownAim.point())
	end))
	-- "[E] IGNITE" over what Ignite would light (2P playtest Oct 11: Kai shot at the Torch Run braziers instead), only
	-- when he can see it: through a wall it gave the Torch Run away (user: "it just makes the game easier")
	local sight = RaycastParams.new()
	sight.FilterType = Enum.RaycastFilterType.Exclude
	sight.RespectCanCollide = true
	trove:Add(RunService.RenderStepped:Connect(function()
		local ready = not busy() and os.clock() - lastIgnite >= T.Ignite.Cooldown
		local target = if ready then nearestIgnitable() else nil
		local root = rootOf()
		if target and root then
			sight.FilterDescendantsInstances = { player.Character :: Model, target }
			local to = Tags.position(target)
			if workspace:Raycast(root.Position, to - root.Position, sight) then
				target = nil
			end
		end
		KeyPrompt.Focus(target, "Ignite", "IGNITE")
	end))
	trove:Add(function()
		KeyPrompt.Focus(nil)
	end)
	trove:Add(Input.action("CastleTools", "Ignite").Pressed:Connect(function()
		if not busy() then
			local target = nearestIgnitable()
			if target and os.clock() - lastIgnite >= T.Ignite.Cooldown then
				lastIgnite = os.clock()
				MoveAnim.Play("CastIgnite")
			end
			toolUse:FireServer(3, target, TopDownAim.point())
		end
	end))
	trove:Add(Input.action("BaseContext", "Dash").Pressed:Connect(function()
		blink(lastBlink)
	end))
end

function FireMage:Stop()
	trove:Clean()
	TopDownAim.Stop()
end

return FireMage
