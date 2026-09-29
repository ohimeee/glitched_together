-- Kai's Copy/Paste, client half: Tool1 copies the Copyable under the crosshair; hold Tool2 to show a ghost
-- preview (R rotates), release to paste within 40 studs.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tuning = require(ReplicatedStorage.Shared.Config.Tuning)
local Net = require(ReplicatedStorage.Shared.Net)
local Tags = require(ReplicatedStorage.Shared.Util.Tags)
local Trove = require(ReplicatedStorage.Shared.Util.Trove)
local Input = require(script.Parent.Parent.Input)
local Aim = require(script.Parent.Parent.Aim)

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

	local function pasteCFrame(): CFrame?
		local root = Aim.root()
		local hit = Aim.hit(T.PasteRange + 40)
		if not (root and hit and copiedSize) then
			return nil
		end
		local pos = hit.Position + hit.Normal * (copiedSize.Y / 2)
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
			toolUse:FireServer(1, target)
		end
	end))

	local tool2 = Input.action("W3Tools", "Tool2")
	trove:Add(tool2.Pressed:Connect(function()
		previewing = copiedSize ~= nil
	end))
	trove:Add(tool2.Released:Connect(function()
		if not previewing then
			return
		end
		previewing = false
		ghost.Transparency = 1
		local cf = pasteCFrame()
		if cf then
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
		if kind == "PasteBlocked" then
			ghost.Color = Color3.fromRGB(255, 80, 80)
			task.delay(0.4, function()
				ghost.Color = Color3.new(1, 1, 1)
			end)
		end
	end))

	player:SetAttribute("CopiedName", nil)
end

function CopyPaste:Stop()
	trove:Clean()
end

return CopyPaste
