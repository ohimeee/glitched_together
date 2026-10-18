-- Double jump + dash in the lobby (user, Oct 18), with the adventure's numbers, sounds and clips (MovementController:
-- Tuning.DoubleJumpVelocity, DashDistance / DashTime, one air dash, GroundDashCooldown). Keys: jump again in the air
-- (SPACE / A / the touch jump button), dash = SHIFT / B / a DASH touch button. Off while frozen in a capsule.
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local MoveAnims = require(ReplicatedStorage.Shared.Config.MoveAnims)
local Audio = require(ReplicatedStorage.Shared.Util.Audio)

local MIN_AIR = 0.12 -- seconds after take-off before a jump press counts as the double jump

local player = Players.LocalPlayer

local function hook(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	local animator = humanoid:WaitForChild("Animator") :: Animator
	local attachment = Instance.new("Attachment")
	attachment.Name = "LobbyMoves"
	attachment.Parent = root

	local tracks: { [string]: AnimationTrack } = {}
	local function play(name: string)
		local id = MoveAnims.Ids[name]
		if not id then
			return
		end
		local track = tracks[name]
		if not track then
			local anim = Instance.new("Animation")
			anim.AnimationId = id
			track = animator:LoadAnimation(anim)
			track.Priority = Enum.AnimationPriority.Action
			tracks[name] = track
		end
		track:Play(0.05)
	end

	local airJumps, airDashes, lastGroundDash, tookOff = 0, 0, -math.huge, 0
	local function inAir(): boolean
		return humanoid.FloorMaterial == Enum.Material.Air
	end
	local function frozen(): boolean
		return humanoid.WalkSpeed <= 0 or humanoid.Health <= 0
	end

	humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			airJumps, airDashes = 0, 0
		elseif new == Enum.HumanoidStateType.Jumping or new == Enum.HumanoidStateType.Freefall then
			if tookOff == 0 or not inAir() then
				tookOff = os.clock()
			end
		end
	end)
	humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
		if inAir() then
			tookOff = os.clock()
		end
	end)

	local function doubleJump()
		if frozen() or not inAir() or airJumps >= 1 or os.clock() - tookOff < MIN_AIR then
			return
		end
		if humanoid:GetState() == Enum.HumanoidStateType.Climbing then
			return
		end
		airJumps += 1
		Audio.play("DoubleJump", root)
		play("DoubleJump")
		local v = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(v.X, Tuning.DoubleJumpVelocity, v.Z)
	end

	local function dash()
		if frozen() or humanoid:GetState() == Enum.HumanoidStateType.Climbing then
			return
		end
		local airborne = inAir()
		if airborne and airDashes >= 1 then
			return
		end
		if not airborne and os.clock() - lastGroundDash < Tuning.GroundDashCooldown then
			return
		end
		if airborne then
			airDashes += 1
		else
			lastGroundDash = os.clock()
		end
		Audio.play("Dash", root)
		play("Dash")
		local move = humanoid.MoveDirection * Vector3.new(1, 0, 1)
		local dir = if move.Magnitude > 0.05 then move.Unit else root.CFrame.LookVector * Vector3.new(1, 0, 1)
		if dir.Magnitude < 0.05 then
			return
		end
		local lv = Instance.new("LinearVelocity")
		lv.Attachment0 = attachment
		lv.MaxForce = math.huge
		lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		lv.RelativeTo = Enum.ActuatorRelativeTo.World
		lv.VectorVelocity = dir.Unit * (Tuning.DashDistance / Tuning.DashTime)
		lv.Parent = root
		task.delay(Tuning.DashTime, function()
			lv:Destroy()
		end)
	end

	local conns = {
		UserInputService.InputBegan:Connect(function(input, processed)
			if processed then
				return
			end
			local k = input.KeyCode
			if k == Enum.KeyCode.Space or k == Enum.KeyCode.ButtonA then
				doubleJump()
			elseif k == Enum.KeyCode.LeftShift or k == Enum.KeyCode.RightShift or k == Enum.KeyCode.ButtonB then
				dash()
			end
		end),
		-- the touch jump button only reaches scripts as JumpRequest
		UserInputService.JumpRequest:Connect(function()
			if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
				doubleJump()
			end
		end),
	}
	humanoid.Died:Once(function()
		for _, c in conns do
			c:Disconnect()
		end
	end)
	character.Destroying:Once(function()
		for _, c in conns do
			c:Disconnect()
		end
	end)
	return dash
end

-- DASH touch button, north-west of Roblox's jump button (user), the adventure's dash icon
-- (falls back to the word if the image fails to load: new uploads reach phones late)
local DASH_ICON = "rbxassetid://129855379396466"
local dashNow: (() -> ())? = nil
local function touchButton()
	if not UserInputService.TouchEnabled then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "LobbyMoves"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local b = Instance.new("TextButton")
	b.Name = "Dash"
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Position = UDim2.new(1, -170, 1, -60)
	b.Size = UDim2.fromOffset(64, 64)
	b.BackgroundColor3 = Color3.new(0, 0, 0)
	b.BackgroundTransparency = 0.6
	b.Text = ""
	b.AutoButtonColor = true
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = b
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Transparency = 0.45
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = b
	local icon = Instance.new("ImageLabel")
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromScale(0.58, 0.58)
	icon.BackgroundTransparency = 1
	icon.Image = DASH_ICON
	icon.ImageTransparency = 0.1
	icon.Parent = b
	local word = Instance.new("TextLabel")
	word.AnchorPoint = Vector2.new(0.5, 0.5)
	word.Position = UDim2.fromScale(0.5, 0.5)
	word.Size = UDim2.fromScale(0.8, 0.28)
	word.BackgroundTransparency = 1
	word.Font = Enum.Font.GothamBlack
	word.TextScaled = true
	word.TextColor3 = Color3.fromRGB(240, 240, 232)
	word.Text = "DASH"
	word.Visible = false
	word.Parent = b
	b.Parent = gui
	task.spawn(function()
		local ok = true
		ContentProvider:PreloadAsync({ icon }, function(_, status)
			ok = status == Enum.AssetFetchStatus.Success
		end)
		icon.Visible = ok
		word.Visible = not ok
	end)
	b.Activated:Connect(function()
		if dashNow then
			dashNow()
		end
	end)
	-- follow the jump button (its spot and size change with the screen)
	task.spawn(function()
		local touchGui = player.PlayerGui:WaitForChild("TouchGui", 30)
		local frame = touchGui and touchGui:WaitForChild("TouchControlFrame", 10)
		local jump = frame and frame:WaitForChild("JumpButton", 10) :: GuiObject?
		if not jump then
			return
		end
		local function follow()
			local size = jump.AbsoluteSize.X * 0.8
			local centre = jump.AbsolutePosition + jump.AbsoluteSize / 2
			local inset = gui.AbsolutePosition -- ScreenGui offset under the top bar
			b.Size = UDim2.fromOffset(size, size)
			-- north-west of the jump button (user, Oct 18)
			local d = jump.AbsoluteSize.X * 0.78
			b.Position = UDim2.fromOffset(centre.X - d - inset.X, centre.Y - d - inset.Y)
			b.Visible = jump.Visible
		end
		follow()
		jump:GetPropertyChangedSignal("AbsolutePosition"):Connect(follow)
		jump:GetPropertyChangedSignal("AbsoluteSize"):Connect(follow)
		jump:GetPropertyChangedSignal("Visible"):Connect(follow)
	end)
end

if player.Character then
	task.spawn(function()
		dashNow = hook(player.Character :: Model)
	end)
end
player.CharacterAdded:Connect(function(c)
	dashNow = hook(c)
end)
touchButton()
