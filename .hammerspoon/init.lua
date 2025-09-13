hs.notify.withdrawAll()
require("bootstrap")

local tablex = require("pl.tablex")
local BC = require("utils.bulk-controller")
local UriHandling = require("utils.uri-handling")

---@class Config: BulkController
m = BC()
m.webURIs =
  UriHandling(UriHandling.schemas.web):setDefaultHandler("com.apple.Safari")
m.mailURIs =
  UriHandling(UriHandling.schemas.mail):setDefaultHandler("com.apple.Mail")
m.clipboard = require("utils.clipboard-handling")()
m.upp = require("utils.universal-play-pause")()
m.internetStatus = hs.network.reachability.internet() --[[@as hs.network.reachability]]
m.tz = require("utils.timezone")()

-- Paste clipboard contents as keystrokes.
m.clipboard:associateHotkey(hs.hotkey.new("cmd-alt", "v", function()
  local value = hs.pasteboard.getContents()
  if value ~= nil then
    hs.eventtap.keyStrokes(value)
  end
end))

require("media")
require("network")

m:startAll()
hs.notify.show("", "", "Configuration reloaded")
