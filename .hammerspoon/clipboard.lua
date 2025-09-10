--- Types associated with the current clipboard contents.
--- Manually-generated from hs.pasteboard.typesAvailable() docs.
---@class TypesAvailable
---@field string? true Whether the contents contain a string value.
---@field styledText? true Whether the contents contain styled text.
---@field sound? true Whether the contents contain an sound.
---@field image? true Whether the contents contain an image.
---@field URL? true Whether the contents contain a URL.
---@field color? true Whether the contents contain a color value.

local musicURLFragments = { "https://open.spotify.com/" }

local textOnly = { image = nil, sound = nil, URL = nil, color = nil, string = true }

--- Callbacks are executed in the order specified. If a callback returns
--- `true`, the event is consumed and no further callbacks are processed.
---@type { [TypesAvailable]: fun(value: string): boolean? }
local callbacks = {
  -- Remove links from copied images.
  [{ image = true, URL = true }] = function()
    local image = hs.pasteboard.readImage()
    if image ~= nil then
      hs.pasteboard.clearContents()
      hs.pasteboard.writeObjects(image)
      return true
    end
  end,
  -- Music link handling.
  [{ URL = true }] = function(value)
    -- Apple Music
    -- Song.link results returns https://geo.music.apple.com/, so this
    -- shouldn't cause any loops.
    if value:find("https://music.apple.com/", 1, true) then
      hs.pasteboard.writeObjects("https://song.link/" .. value)
      return true
    end

    -- Other music providers.
    if hs.fnutils.some(musicURLFragments, function(fragment)
        return value:find(fragment, 1, true)
      end) then
      hs.http.asyncGet(
        "https://api.song.link/v1-alpha.1/links?songIfSingle=true&url=" .. value,
        nil,
        function(httpCode, body)
          if httpCode >= 400 then
            return hs.notify.show("", "", "Failed to get Apple Music link.")
          end
          ---@diagnostic disable-next-line: undefined-field
          hs.pasteboard.writeObjects(hs.json.decode(body).linksByPlatform
            .appleMusic.url)
        end
      )
    end

    return true
  end,
  -- Convert Digital Color Meter RGB to hex.
  [textOnly] = function(value)
    local r, g, b = value:match("^(%d+)	(%d+)	(%d+)	")
    if r ~= nil and g ~= nil and b ~= nil then
      local hex = string.format("#%x%x%x", r, g, b)
      local success = hs.pasteboard.setContents(hex)
      if not success then
        hs.notify.show("", "", "Failed to copy hex colour.")
      end
    end
  end,
}

-- Actions on copy.
-- Store resulting object as a global to prevent garbage collection:
-- https://github.com/Hammerspoon/hammerspoon/issues/3774
CLIPBOARD_WATCHER = hs.pasteboard.watcher.new(
---@param value string | nil
---@param pbName string
  function(value, pbName)
    if value == nil then return end

    local types = hs.pasteboard.typesAvailable() --[[@as TypesAvailable]]
    for selectors, callback in pairs(callbacks) do
      -- Ensure all selectors match the clipboard types.
      local allMatched = true
      for k, v in pairs(selectors) do
        allMatched = v == types[k]
        if allMatched == false then
          break
        end
      end

      -- Stop even propagation if specified.
      if allMatched and callback(value) then
        break
      end
    end
  end
)

-- Paste as keystrokes.
-- Store resulting object as a global to prevent garbage collection:
-- https://github.com/Hammerspoon/hammerspoon/issues/3774
CLIPBOARD_HOTKEY = hs.hotkey.bind("cmd-alt", "v", function()
  hs.eventtap.keyStrokes(hs.pasteboard.getContents())
end)
