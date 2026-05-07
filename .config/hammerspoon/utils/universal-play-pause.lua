local class = require("pl.class")

---@class NSSystemDefinedAuxControlButtonEvent
---@field key string Actions string containing one of the following labels indicating the key involved.
---@field keyCode integer The numeric keyCode corresponding to the key specified in `key`.
---@field down boolean A boolean value indicating if the key is pressed down (true) or just released (false)
---@field repeat boolean A boolean indicating if this event is because the keydown is repeating. This will always be false for a key release.

---@class UPPHandler
---@field isPlaying fun(): boolean
---@field FAST? fun(): nil
---@field PLAY? fun(shouldPause: boolean): nil
---@field REWIND? fun(): nil

---@class UniversalPlayPause: pl.Class
---@overload fun(): UniversalPlayPause
---@field protected handlers table<string,UPPHandler>
---@field protected tap hs.eventtap
---@field protected wasPlaying string[]
local obj = class() --[[@as UniversalPlayPause]]

-- Static methods

--- Wrap AppleScript targeting a website. Will only apply to the first matched website.
---
--- The following AppleScript variables are available:
--- - `w`: The Safari window containing the target website tab.
--- - `t`: The Safari tab containing the target website.
---@param site string
---@param as string
function obj.wrapSafariAS(site, as)
  local script = [[
tell application "Safari"
	repeat with w in windows
		repeat with t in tabs of w
			if URL of t contains "]] .. site:gsub('"', '\\"') .. [[" then
				]] .. as .. [[
			end if
		end repeat
	end repeat
end tell
]]
  -- print(script)

  return function()
    if hs.application.get("Safari") == nil then
      return
    end
    local _, result = hs.osascript.applescript(script)
    return result
  end
end

--- Wrap JavaScript targeting a website. Will only apply to the first matched website.
---@param site string
---@param js string
function obj.wrapSafariJS(site, js)
  return obj.wrapSafariAS(site, [[
				tell t
					return do JavaScript "]] .. js:gsub('"', '\\"') .. [["
				end tell
]])
end

-- Methods

---@package
function obj:_init()
  self.handlers = {}
  self.wasPlaying = {}

  self.tap = hs.eventtap.new(
    { hs.eventtap.event.types.systemDefined },
    ---@param event hs.eventtap.event
    function(event)
      local data = event:systemKey() --[[@as NSSystemDefinedAuxControlButtonEvent]]
      -- Ignore everything except media keys.
      if
        data["key"] ~= "PLAY"
        and data["key"] ~= "FAST"
        and data["key"] ~= "REWIND"
      then
        return false -- Do not consume event.
      end
      -- Only fire on key-up or repeat.
      if data["down"] == false or data["repeat"] == true then
        return true -- Consume event.
      end

      -- Determine what's currently playing.
      local isPlaying = self:getPlaying()
      if #isPlaying > 0 then
        self.wasPlaying = isPlaying
      end

      -- If nothing is or was playing, return early.
      if #isPlaying == 0 and #self.wasPlaying == 0 then
        return true -- Consume event.
      end

      -- Propagate actions to apps that were playing.
      local shouldPause = #isPlaying > 0 and true or false
      for _, app in ipairs(self.wasPlaying) do
        local handler = self.handlers[app][data["key"]]
        if handler ~= nil then
          handler(shouldPause)
        end
      end

      return true -- Consume event.
    end
  )
end

---@return UniversalPlayPause
function obj:start()
  self.tap:start()
  return self
end

---@return UniversalPlayPause
function obj:stop()
  self.tap:stop()
  return self
end

---Get currently-playing app IDs.
---@return string[]
function obj:getPlaying()
  local res = {}
  for app, handlers in pairs(self.handlers) do
    if handlers.isPlaying() then
      table.insert(res, app)
    end
  end
  return res
end

---@param id string
---@param handler UPPHandler
---@return UniversalPlayPause
function obj:addHandler(id, handler)
  self.handlers[id] = handler

  return self
end

---@return UniversalPlayPause
function obj:printPlaying()
  print(hs.inspect(self:getPlaying()))

  return self
end

---@return UniversalPlayPause
function obj:printWasPlaying()
  print(hs.inspect(self.wasPlaying))

  return self
end

return obj
