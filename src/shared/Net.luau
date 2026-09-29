-- Creates (server) or looks up (client) every RemoteEvent, so names never drift.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local IS_SERVER = RunService:IsServer()
local folder: Folder

if IS_SERVER then
	local existing = ReplicatedStorage:FindFirstChild("Net")
	if existing and existing:IsA("Folder") then
		folder = existing
	else
		local created = Instance.new("Folder")
		created.Name = "Net"
		created.Parent = ReplicatedStorage
		folder = created
	end
else
	folder = ReplicatedStorage:WaitForChild("Net") :: Folder
end

local Net = {}

function Net.event(name: string, unreliable: boolean?): RemoteEvent
	if IS_SERVER then
		local existing = folder:FindFirstChild(name)
		if existing then
			return existing :: any
		end
		local e = Instance.new(if unreliable then "UnreliableRemoteEvent" else "RemoteEvent")
		e.Name = name
		e.Parent = folder
		return e :: any
	end
	return folder:WaitForChild(name) :: any
end

return Net
