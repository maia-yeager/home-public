-- Get luarocks location and add it to the search path.
local lVer = _VERSION:match("Lua (.+)$")
local luarocks = hs
	.execute("which luarocks", true)--[[@as string]]
	:gsub("\n", "")
if #luarocks > 0 then
	package.path = package.path
		.. ";"
		.. hs
			.execute(luarocks .. " --lua-version " .. lVer .. " path --lr-path")--[[@as string]]
			:gsub("\n", "")
	package.cpath = package.cpath
		.. ";"
		.. hs
			.execute(luarocks .. " --lua-version " .. lVer .. " path --lr-cpath")--[[@as string]]
			:gsub("\n", "")
end

-- Remote control of Hammerspoon.
hs.allowAppleScript(true) -- For Raycast.
require("hs.ipc") -- For VS Code extension.

-- SpoonInstall.
hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall.use_syncinstall = true

-- Only update repos if connected to the internet.
local internetReachability = hs.network.reachability.internet() --[[@as hs.network.reachability]]
if (internetReachability:status() & hs.network.reachability.flags.reachable) > 0 then
	spoon.SpoonInstall:updateAllRepos()
end

-- Spoon loading.
spoon.SpoonInstall:andUse("EmmyLua")
spoon.SpoonInstall:andUse("ReloadConfiguration", { start = true })
