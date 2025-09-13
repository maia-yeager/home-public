local tablex = require("pl.tablex")

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
local musicURLFragments = {
  "https://open.spotify.com/",
  "https://music.youtube.com/watch",
}
---@param value string
---@return boolean
local function hasFragment(value)
  return hs.fnutils.some(musicURLFragments, function(fragment)
    return value:find(fragment, 1, true)
  end)
end
---@param value string
---@return string
local function createSongLinkURL(value)
  return "https://song.link/" .. value
end

m.webURIs:addHandler(function(_, _, _, fullURL)
  if hasFragment(fullURL) then
    return createSongLinkURL(fullURL)
  end
end)
-- Apple Music
-- Song.link results returns https://geo.music.apple.com/, so this
-- shouldn't cause any loops.
m.clipboard:addCallback({ URL = true }, function(value)
  if value:find("https://music.apple.com/", 1, true) then
    hs.pasteboard.writeObjects(createSongLinkURL(value))
    return true
  end
end)
-- Other music providers.
m.clipboard:addCallback({ URL = true }, function(value)
  if hasFragment(value) then
    hs.http.asyncGet(
      "https://api.song.link/v1-alpha.1/links?songIfSingle=true&url=" .. value,
      nil,
      function(httpCode, body)
        if httpCode >= 400 then
          return hs.notify.show("", "", "Failed to get Apple Music link.")
        end
        hs.pasteboard.writeObjects(
          ---@diagnostic disable-next-line: undefined-field
          hs.json.decode(body).linksByPlatform.appleMusic.url
        )
        hs.notify.show("Song.link", "", "Copied URL to clipboard.")
      end
    )
  end

  return true
end)
