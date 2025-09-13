hs.notify.withdrawAll()
require("bootstrap")

local tablex = require("pl.tablex")
local UriHandling = require("utils.uri-handling")

---@class Config
m = {}
function m:startAll()
  for _, value in pairs(self) do
    if type(value) == "table" and type(value.start) == "function" then
      value:start()
    end
  end
end
function m:stopAll()
  for _, value in pairs(self) do
    if type(value) == "table" and type(value.stop) == "function" then
      value:stop()
    end
  end
end

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
  hs.eventtap.keyStrokes(hs.pasteboard.getContents())
end))

require("media")
require("network")

m:startAll()
hs.notify.show("", "", "Configuration reloaded")
