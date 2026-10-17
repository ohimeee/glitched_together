-- Kai's Copy/Paste, client half: Tool1 copies the Copyable under the crosshair; hold Tool2 to show a ghost
-- preview (R rotates), release to paste within 40 studs: on what the crosshair hits, or floating in mid-air ahead
-- of Kai when it hits nothing in range (bridges over the void): level with his feet, far enough out that it clears
-- him (FloatDistance, or half its length for long planks).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Net = require(ReplicatedStorage.Shared.Net)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local Input = require(script.Parent.Parent.Input)
local Aim = require(script.Parent.Parent.Aim)
local MoveAnim = require(script.Parent.Parent.Controllers.MoveAnimController)

local player = Players.LocalPlayer
local toolUse = Net.event("ToolUse")
local toolResult = Net.event("ToolResult")
local T = Tuning.CopyPaste

local CopyPaste = {}
local trove = Trove.new()

local function sizeOf(inst: Instance): Vector3
	if inst:IsA("BasePart") then
		return inst.Size
	end
	local _, size = (inst :: Model):GetBoundingBox()
	return size
end

function CopyPaste:Start()
	local copiedSize: Vector3? = nil
	local rotation = 0
	local previewing = false

	local ghost = trove:Add(Instance.new("Part"))
	ghost.Name = "PasteGhost"
	ghost.Anchored = true
	ghost.CanCollide = false
	ghost.CanQuery = false
	ghost.CanTouch = false
	ghost.Material = Enum.Material.ForceField
	ghost.Color = Color3.new(1, 1, 1)
	ghost.Transparency = 1
	ghost.Parent = workspace

	-- a refused paste (NoPaste room, or into a player) flashes the ghost red where it would have gone, with a label;
	-- the ghost is already hidden on release, so a flash on the ghost alone showed nothing (playtest Oct 1)
	local refused = Instance.new("BillboardGui")
	refused.Size = UDim2.fromOffset(220, 40)
	refused.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	refused.AlwaysOnTop = true
	refused.Enabled = false
	refused.Parent = ghost
	local refusedText = Instance.new("TextLabel")
	refusedText.Size = UDim2.fromScale(1, 1)
	refusedText.BackgroundTransparency = 1
	refusedText.Font = Enum.Font.GothamBlack
	refusedText.TextScaled = true
	refusedText.TextColor3 = Color3.fromRGB(255, 80, 80)
	refusedText.TextStrokeTransparency = 0
	refusedText.Text = "CAN'T PASTE HERE"
	refusedText.Parent = refused
	local lastCf: CFrame? = nil
	local flashId = 0

	local function pasteCFrame(): CFrame?
		local root = Aim.root()
		if not (root and copiedSize) then
			return nil
		end
		local hit = Aim.hit(T.PasteRange + 40)
		local pos: Vector3
		if hit and (hit.Position - root.Position).Magnitude <= T.PasteRange then
			pos = hit.Position + hit.Normal * (copiedSize.Y / 2)
		else
			local ray = Aim.centerRay()
			local flatDir = ray.Direction * Vector3.new(1, 0, 1)
			if flatDir.Magnitude < 0.01 then
				return nil
			end
			local size = copiedSize :: Vector3
			local reach = math.max(T.FloatDistance, math.max(size.X, size.Z) / 2 + 3)
			local feet = root.Position.Y - 3
			pos = Vector3.new(root.Position.X, feet - size.Y / 2, root.Position.Z) + flatDir.Unit * reach
		end
		-- touch: dragging the PASTE button slides the spot across the floor, camera-relative (screen up = away)
		local drag = Aim.drag()
		if drag and drag.Magnitude > Tuning.Touch.UltDeadZone then
			local cam = workspace.CurrentCamera.CFrame
			local look = Vector3.new(cam.LookVector.X, 0, cam.LookVector.Z).Unit
			local right = Vector3.new(cam.RightVector.X, 0, cam.RightVector.Z).Unit
			local amount = math.min(1, drag.Magnitude / Tuning.Touch.UltDragPx) * Tuning.Touch.PasteDrag
			pos += (right * drag.X - look * drag.Y).Unit * amount
			-- land on what's under the new spot (a slope, a step); over the void it stays level
			local params = RaycastParams.new()
			params.FilterDescendantsInstances = { player.Character :: Instance, ghost }
			params.FilterType = Enum.RaycastFilterType.Exclude
			local size = copiedSize :: Vector3
			local down = workspace:Raycast(pos + Vector3.new(0, 12, 0), Vector3.new(0, -24, 0), params)
			if down then
				pos = Vector3.new(pos.X, down.Position.Y + size.Y / 2, pos.Z)
			end
		end
		if (pos - root.Position).Magnitude > T.PasteRange then
			return nil
		end
		return CFrame.new(pos) * CFrame.Angles(0, math.rad(rotation), 0)
	end

	trove:Add(Input.action("W3Tools", "Tool1").Pressed:Connect(function()
		local target = Aim.best({ "Copyable", "CodeLayer" }, T.CopyRange, 6, function(inst)
			return Tags.has(inst, "Copyable") or inst:GetAttribute("PulledOut") == true
		end)
		if target then
			copiedSize = sizeOf(target)
			MoveAnim.Aim()
			toolUse:FireServer(1, target)
		end
	end))

	local tool2 = Input.action("W3Tools", "Tool2")
	trove:Add(tool2.Pressed:Connect(function()
		previewing = copiedSize ~= nil
	end))
	trove:Add(function()
		Aim.SetDrag(nil)
	end)
	trove:Add(tool2.Released:Connect(function()
		if not previewing then
			return
		end
		previewing = false
		ghost.Transparency = 1
		local cf = pasteCFrame()
		Aim.SetDrag(nil)
		if cf then
			lastCf = cf
			MoveAnim.Aim()
			toolUse:FireServer(2, nil, cf)
		end
	end))
	trove:Add(Input.action("W3Tools", "Rotate").Pressed:Connect(function()
		rotation = (rotation + 45) % 360
	end))

	trove:Add(RunService.RenderStepped:Connect(function()
		if not (previewing and copiedSize) then
			return
		end
		local cf = pasteCFrame()
		ghost.Size = copiedSize :: Vector3
		if cf then
			ghost.CFrame = cf
			ghost.Transparency = 0.3
		else
			ghost.Transparency = 1
		end
	end))

	trove:Add(toolResult.OnClientEvent:Connect(function(kind: string)
		if kind == "ClipboardCleared" then
			copiedSize = nil
			previewing = false
			ghost.Transparency = 1
		elseif kind == "PasteBlocked" then
			flashId += 1
			local id = flashId
			if lastCf and copiedSize then
				ghost.Size = copiedSize
				ghost.CFrame = lastCf
			end
			ghost.Color = Color3.fromRGB(255, 80, 80)
			ghost.Transparency = 0.3
			refused.Enabled = true
			task.delay(0.9, function()
				if flashId ~= id then
					return
				end
				ghost.Color = Color3.new(1, 1, 1)
				refused.Enabled = false
				if not previewing then
					ghost.Transparency = 1
				end
			end)
		end
	end))

	player:SetAttribute("CopiedName", nil)
end

function CopyPaste:Stop()
	trove:Clean()
end

return CopyPaste
