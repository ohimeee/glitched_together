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
		if kind == "ClipboardCleared" then
			copiedSize = nil
			previewing = false
			ghost.Transparency = 1
		elseif kind == "PasteBlocked" then
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
