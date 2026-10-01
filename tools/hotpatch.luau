-- Hot-patch script sources into the open Studio place without a rebuild or restart (memory: studio-restart-wait).
-- 1. Serve the repo: `python -m http.server 8767 --bind 127.0.0.1` (repo root, background).
-- 2. Run this through Studio MCP `execute_luau` (Edit datamodel) with FILES set to repo-relative paths
--    (e.g. from `git diff --name-only`). Missing scripts are created; init.luau patches its folder module.
-- Mirrors adventure.project.json: src/shared → ReplicatedStorage.Shared, src/adventure/server →
-- ServerScriptService.Server, src/adventure/client → StarterPlayer.StarterPlayerScripts.Client.
local FILES = {
	-- "src/shared/Config/Tuning.luau",
}
local BASE = "http://127.0.0.1:8767/"

local HttpService = game:GetService("HttpService")
local ROOTS = {
	{ "src/shared/", game:GetService("ReplicatedStorage"), "Shared" },
	{ "src/adventure/server/", game:GetService("ServerScriptService"), "Server" },
	{ "src/adventure/client/", game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts"), "Client" },
}

local was = HttpService.HttpEnabled
HttpService.HttpEnabled = true
local log = {}
for _, path in FILES do
	local parent: Instance?, rest
	for _, r in ROOTS do
		if path:sub(1, #r[1]) == r[1] then
			parent = r[2]:FindFirstChild(r[3])
			rest = path:sub(#r[1] + 1)
		end
	end
	if not parent then
		table.insert(log, "skip " .. path)
		continue
	end
	local parts = string.split(rest, "/")
	local file = table.remove(parts) :: string
	for _, folder in parts do
		parent = (parent :: Instance):FindFirstChild(folder)
			or (function()
				local f = Instance.new("Folder")
				f.Name = folder
				f.Parent = parent
				return f
			end)()
	end
	local name, class = file:gsub("%.luau$", ""), "ModuleScript"
	if name:match("%.server$") then
		name, class = name:gsub("%.server$", ""), "Script"
	elseif name:match("%.client$") then
		name, class = name:gsub("%.client$", ""), "LocalScript"
	end
	local target: Instance? = if name == "init" then parent else (parent :: Instance):FindFirstChild(name)
	if not target then
		target = Instance.new(class)
		target.Name = name
		target.Parent = parent
	end
	local ok, src = pcall(HttpService.GetAsync, HttpService, BASE .. path, true)
	if ok then
		(target :: any).Source = src
		table.insert(log, "ok " .. target:GetFullName())
	else
		table.insert(log, "FAIL " .. path .. ": " .. tostring(src))
	end
end
HttpService.HttpEnabled = was
return table.concat(log, "\n")
