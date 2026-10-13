-------------------------------------------------------------------------------
-- Pre-flight
-------------------------------------------------------------------------------

hs.notify.withdrawAll()

require("hs.ipc") -- For VS Code extension.

-- Get luarocks location and add it to the search path.
local luarocksBin = hs
  .execute("command -v luarocks 2>/dev/null", true) --[[@as string]]
  :gsub("\n", "")
if #luarocksBin > 0 then
  local function getLuaRocksPaths(strArgs)
    local path, status = hs.execute(luarocksBin .. " path " .. strArgs) --[[@as string]]
    if not status then
      hs.notify.show("", "", "luarocks " .. strArgs .. " command failed")
      return ""
    end
    return path:gsub("\n", "")
  end
  package.path = package.path .. ";" .. getLuaRocksPaths("--lr-path")
  package.cpath = package.cpath .. ";" .. getLuaRocksPaths("--lr-cpath")
else
  hs.notify.show("", "", "luarocks not found")
end

-- SpoonInstall.
hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall.use_syncinstall = true

-- Only update repos if connected to the internet.
local internetReachability = hs.network.reachability.internet() --[[@as hs.network.reachability]]
if
  (internetReachability:status() & hs.network.reachability.flags.reachable) > 0
then
  spoon.SpoonInstall:updateAllRepos()
else
  print("No internet connection, skipping updating Spoons.")
end

-- Module loading.
spoon.SpoonInstall:andUse("EmmyLua")
spoon.SpoonInstall:andUse("ReloadConfiguration", { start = true })

-------------------------------------------------------------------------------
-- Initialization
-------------------------------------------------------------------------------

local BulkController = require("utils.bulk-controller")
local UriHandling = require("utils.uri-handling")

---@class Controller: BulkController
m = BulkController()
m.webUris =
  UriHandling(UriHandling.schemas.web):setDefaultHandler("com.apple.Safari")
m.mailUris =
  UriHandling(UriHandling.schemas.mail):setDefaultHandler("com.apple.Mail")
m.clipboard = require("utils.clipboard-handling")()
m.upp = require("utils.universal-play-pause")()
m.tz = require("utils.timezone")()
m.messageIndicator = require("utils.message-indicator")()

-------------------------------------------------------------------------------
-- Configuration
-------------------------------------------------------------------------------

-- Paste clipboard contents as keystrokes.
m.clipboard:associateHotkey(hs.hotkey.new("⌃⌥⌘", "v", function()
  local value = hs.pasteboard.getContents()
  if value ~= nil then
    hs.eventtap.keyStrokes(value)
  end
end))

-- Visually alert if there are unread messages.
m.messageIndicator:addApp(
  "/System/Applications/Messages.app",
  [=[sqlite3 ~/Library/Messages/chat.db "SELECT COUNT(guid) FROM message WHERE NOT(is_read) AND NOT(is_from_me) AND NOT(is_spam) AND text !=''"]=]
)
m.messageIndicator:addApp("/Applications/Signal.app")

-- Convert Digital Color Meter RGB to hex.
m.clipboard:addCallback(m.clipboard.textOnlySelector, function(value)
  local r, g, b = value:match("^(%d+)	(%d+)	(%d+)	")
  if r == nil or g == nil or b == nil then
    return false
  end

  local hex = string.format("#%x%x%x", r, g, b)
  local success = hs.pasteboard.setContents(hex)
  if not success then
    hs.notify.show("", "", "Failed to copy hex colour.")
  end
end)

-- Remove links from copied images.
m.clipboard:addCallback({ image = true, URL = true }, function()
  -- Skip file URLs.
  local url = hs.pasteboard.readURL()
  if url == nil then
    return false
  end
  if url.url and url.url:match("^file:///") then
    return false
  end

  local image = hs.pasteboard.readImage()
  if image == nil then
    return false
  end

  hs.pasteboard.clearContents()
  hs.pasteboard.writeObjects(image)
  return true
end)

-- Universal play / pause.
m.upp:addHandler("Music", {
  isPlaying = hs.itunes.isPlaying,
  FAST = hs.itunes.next,
  REWIND = hs.itunes.rw,
  PLAY = hs.itunes.playpause,
})
m.upp:addHandler("Safari:YouTube", {
  isPlaying = m.upp.wrapSafariJS(
    "youtube.com",
    "document.querySelector('button[data-tooltip-title=\"Pause (k)\"]') ? true : false;"
  ),
  PLAY = m.upp.wrapSafariJS(
    "youtube.com",
    "document.querySelector('button.ytp-play-button')?.click();"
  ),
})
m.upp:addHandler("Safari:Plex", {
  isPlaying = m.upp.wrapSafariJS(
    "stream.yeagers.co",
    "document.querySelector('button[data-testid=\"pauseButton\"]') ? true : false;"
  ),
  PLAY = m.upp.wrapSafariAS(
    "stream.yeagers.co",
    [[
delay 0.25
activate application "Safari"
tell w
  set current tab to t
end tell
delay 0.25
tell application "System Events"
  keystroke space
end tell
return
]]
  ),
})

-- Music link handling.
local musicUrlPatterns = {
  "^https://music.apple.com/",
  "^https://open.spotify.com/",
  "^https://music.youtube.com/watch",
  "^https://[^.]+.bandcamp.com/(album|track)/",
}
---@param value string
---@return boolean
local function isMusicUrl(value)
  return hs.fnutils.some(musicUrlPatterns, function(fragment)
    return value:match(fragment) ~= nil
  end)
end
---@param value string
---@return string
local function createSongLinkUrl(value)
  return "https://song.link/" .. value
end
m.clipboard:addCallback({ URL = true }, function(value)
  if isMusicUrl(value) then
    hs.pasteboard.writeObjects(createSongLinkUrl(value))
    return true
  end
end)
m.webUris:addHandler(function(_, _, _, fullURL)
  if isMusicUrl(fullURL) then
    return createSongLinkUrl(fullURL)
  end
end)

-------------------------------------------------------------------------------
-- Start
-------------------------------------------------------------------------------

m:startAll()
hs.notify.show("", "", "Configuration reloaded")
