local tablex = require("pl.tablex")
local List = require("pl.List")
local class = require("pl.class")

--- Types associated with the current clipboard contents.
--- Manually-generated from hs.pasteboard.typesAvailable() docs.
---@class ClipboardItemTypes
---@field string? true Whether the contents contain a string value.
---@field styledText? true Whether the contents contain styled text.
---@field sound? true Whether the contents contain an sound.
---@field image? true Whether the contents contain an image.
---@field URL? true Whether the contents contain a URL.
---@field color? true Whether the contents contain a color value.

---@alias CallbackFn fun(value: string): boolean?

---@class Callback
---@field selectors ClipboardItemTypes
---@field fn CallbackFn

---@class ClipboardHandling: pl.Class
---@overload fun(): ClipboardHandling
---@field protected callbacks pl.List<Callback>
---@field protected hotkeys pl.List<hs.hotkey>
---@field protected watcher hs.pasteboard.watcher
local obj = class() --[[@as ClipboardHandling]]

-- Constants

--- Selector for callbacks targeting text-only clipboard content.
--- @type ClipboardItemTypes
obj.textOnlySelector = tablex.readonly({
  image = nil,
  sound = nil,
  URL = nil,
  color = nil,
  string = true,
})

-- Methods

---@package
function obj:_init()
  self.callbacks = List()
  self.hotkeys = List()

  self.watcher = hs.pasteboard.watcher.new(
    ---@param value string | nil
    ---@param pbName string
    function(value, pbName)
      if value == nil then
        return
      end

      local types = hs.pasteboard.typesAvailable() --[[@as ClipboardItemTypes]]
      for _, callback in ipairs(self.callbacks) do
        -- Ensure all selectors match the clipboard types.
        local allMatched = true
        for k, v in pairs(callback.selectors) do
          allMatched = v == types[k]
          if allMatched == false then
            break
          end
        end

        -- Stop even propagation if specified.
        if allMatched and callback.fn(value) then
          break
        end
      end
    end
  ) --[[@as hs.pasteboard.watcher]]
end

function obj:start()
  for _, hotkey in ipairs(self.hotkeys) do
    hotkey:enable()
  end
  self.watcher:start()

  return self
end

function obj:stop()
  self.watcher:stop()
  for _, hotkey in ipairs(self.hotkeys) do
    hotkey:disable()
  end

  return self
end

---Add a handler for a clipboard item type. Higher priority is given to
---callbacks with more selectors.
---@param selectors ClipboardItemTypes
---@param fn CallbackFn
function obj:addCallback(selectors, fn)
  self.callbacks:append({ selectors = selectors, fn = fn })
  self.callbacks:sort(
    ---@param a Callback
    ---@param b Callback
    function(a, b)
      return #a.selectors > #b.selectors
    end
  )

  return self
end

---Manage a hotkey binding with the clipboard module lifecycle.
---@param hotkey hs.hotkey
function obj:associateHotkey(hotkey)
  self.hotkeys:append(hotkey)
end

--- Callbacks are executed in the order specified. If a callback returns
--- `true`, the event is consumed and no further callbacks are processed.
---@type { [ClipboardItemTypes]: CallbackFn }
local callbacks = {}

return obj
