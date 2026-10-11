-- Miko's Shield Knight, client half (server: AbilitiesServer/ShieldKnight). Top-down aim at the mouse / right stick.
--   Tool1 (hold)   Sword combo            Tool2 (hold)  Shield Block (slows Miko; taunts; reflects shots)
--   Tool1 + Tool2  Rally when Ultimate is full
--   Dash           Shield Charge: rush along the aim, then the server resolves hits along the path
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Palette = require(ReplicatedStorage.Shared.Config.Palette)
local Net = require(ReplicatedStorage.Shared.Net)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local Input = require(script.Parent.Parent.Input)
local TopDownAim = require(script.Parent.Parent.TopDownAim)
local MoveAnim = require(script.Parent.Parent.Controllers.MoveAnimController)

local player = Players.LocalPlayer
local toolUse = Net.event("ToolUse")
local T = Tuning.ShieldKnight
local C = Tuning.Combat

local CHARGE_TIME = 0.3

local ShieldKnight = {}
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

local function charge(last: { t: number })
	local root = rootOf()
	if not root or busy() or os.clock() - last.t < T.Charge.Cooldown then
		return
	end
	last.t = os.clock()
	MoveAnim.Play("ShieldCharge")
	local length = if player:GetAttribute("Up_LongerCharge") then C.LongerCharge else T.Charge.Distance
	local dir = TopDownAim.direction()
	local from = root.Position
	local attachment = root:FindFirstChild("RootAttachment") :: Attachment?
	if attachment then
		local lv = Instance.new("LinearVelocity")
		lv.Attachment0 = attachment
		lv.MaxForce = math.huge
		lv.VectorVelocity = dir * (length / CHARGE_TIME)
		lv.Parent = root
		task.delay(CHARGE_TIME, lv.Destroy, lv)
	end
	task.delay(CHARGE_TIME + 0.02, function()
		toolUse:FireServer(3, nil, from)
	end)
end

function ShieldKnight:Start()
	TopDownAim.Start(Palette.Miko)
	local sword = Input.action("CastleTools", "Tool1")
	local block = Input.action("CastleTools", "Tool2")
	local lastCharge = { t = -math.huge }
	local step, lastSwing = 0, -math.huge -- the sword combo's animation follows the server's 3-hit chain

	local function rally(): boolean
		if sword:IsDown() and block:IsDown() and ultimateReady() then
			MoveAnim.Set("Block", false)
			MoveAnim.Play("Rally")
			toolUse:FireServer(4, nil, TopDownAim.point())
			return true
		end
		return false
	end

	trove:Add(sword.Pressed:Connect(function()
		if busy() or rally() then
			return
		end
		task.spawn(function()
			while sword:IsDown() and not busy() and not block:IsDown() do
				step = if os.clock() - lastSwing > C.SwordCombo.Window then 1 else step % 3 + 1
				lastSwing = os.clock()
				MoveAnim.Play("Slash" .. step)
				toolUse:FireServer(1, nil, TopDownAim.point())
				task.wait(C.SwordCombo.Swing)
			end
		end)
	end))
	trove:Add(block.Pressed:Connect(function()
		if rally() then
			return
		end
		MoveAnim.Set("Block", true)
		toolUse:FireServer(2, nil, true)
	end))
	trove:Add(block.Released:Connect(function()
		MoveAnim.Set("Block", false)
		toolUse:FireServer(2, nil, false)
	end))
	trove:Add(Input.action("BaseContext", "Dash").Pressed:Connect(function()
		charge(lastCharge)
	end))
end

function ShieldKnight:Stop()
	MoveAnim.Set("Block", false)
	toolUse:FireServer(2, nil, false)
	trove:Clean()
	TopDownAim.Stop()
end

return ShieldKnight
