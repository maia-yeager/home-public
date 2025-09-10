---@class NSSystemDefinedAuxControlButtonEvent
---@field key string Actions string containing one of the following labels indicating the key involved.
---@field keyCode number The numeric keyCode corresponding to the key specified in `key`.
---@field down boolean A boolean value indicating if the key is pressed down (true) or just released (false)
---@field repeat boolean A boolean indicating if this event is because the keydown is repeating. This will always be false for a key release.

---@class KeyHandlers
---@field isPlaying fun(): boolean
---@field FAST? fun(): nil
---@field PLAY? fun(shouldPause: boolean): nil
---@field REWIND? fun(): nil

local wasPlayingKey = "media:wasPlaying"

--- Wrap AppleScript targeting a website. Will only apply to the first matched website.
---
--- The following AppleScript variables are available:
--- - `w`: The Safari window containing the target website tab.
--- - `t`: The Safari tab containing the target website.
---@param site string
---@param as string
local function safariASWrapper(site, as)
  if hs.application.get("Safari") == nil then
    return
  end

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

  local _, result = hs.osascript.applescript(script)
  return result
end

--- Wrap JavaScript targeting a website. Will only apply to the first matched website.
---@param site string
---@param js string
local function safariJSWrapper(site, js)
  return safariASWrapper(site, [[
				tell t
					return do JavaScript "]] .. js:gsub('"', '\\"') .. [["
				end tell
]])
end

---@type table<string, KeyHandlers>
local appHandlers = {
  Music = {
    isPlaying = hs.itunes.isPlaying,
    FAST = hs.itunes.next,
    REWIND = hs.itunes.rw,
    PLAY = hs.itunes.playpause,
  },

  SafariYouTube = {
    isPlaying = function()
      return safariJSWrapper(
        "youtube.com",
        "document.querySelector('button[data-tooltip-title=\"Pause (k)\"]') ? true : false;"
      ) --[[@as boolean]]
    end,
    PLAY = function(shouldPause)
      if shouldPause then
        return safariJSWrapper(
          "youtube.com",
          "document.querySelector('button[data-tooltip-title=\"Pause (k)\"]')?.click();"
        )
      end
      safariJSWrapper(
        "youtube.com",
        "document.querySelector('button[data-tooltip-title=\"Play (k)\"]')?.click();"
      )
    end,
  },

  SafariPlex = {
    isPlaying = function()
      return safariJSWrapper(
        "stream.yeagers.co",
        "document.querySelector('button[data-testid=\"pauseButton\"]') ? true : false;"
      ) --[[@as boolean]]
    end,
    PLAY = function()
      -- Can't use JS, since it seems that Plex web filters for trusted JS events.
      safariASWrapper(
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
      )
    end,
  },
}

-- Intercept media keys.
-- Store resulting object as a global to prevent garbage collection:
-- https://github.com/Hammerspoon/hammerspoon/issues/3774
MEDIA_EVENTTAP = hs.eventtap
  .new(
    { hs.eventtap.event.types.systemDefined },
    ---@param event hs.eventtap.event
    function(event)
      local data = event:systemKey() --[[@as NSSystemDefinedAuxControlButtonEvent]]
      -- Ignore everything except media keys.
      if data["key"] ~= "PLAY" and data["key"] ~= "FAST" and data["key"] ~= "REWIND" then
        return false -- Do not consume event.
      end
      -- Only fire on key-up or repeat.
      if data["down"] == false or data["repeat"] == true then
        return true -- Consume event.
      end

      -- Determine what's currently playing.
      ---@type string[]
      local isPlaying = {}
      for app, handlers in pairs(appHandlers) do
        if handlers.isPlaying() then
          table.insert(isPlaying, app)
        end
      end

      -- Update previously playing apps.
      if #isPlaying > 0 then
        hs.settings.set(wasPlayingKey, isPlaying)
      end
      local wasPlaying = hs.settings.get(wasPlayingKey) or {}

      -- If nothing is or was playing, return early.
      if #isPlaying == 0 and #wasPlaying == 0 then
        return true -- Consume event.
      end

      -- Propagate actions to apps that were playing.
      local shouldPause = #isPlaying > 0 and true or false
      for _, app in ipairs(wasPlaying) do
        local handler = appHandlers[app][data["key"]]
        if handler ~= nil then
          handler(shouldPause)
        end
      end

      return true -- Consume event.
    end
  )
  :start()

-- Bind a URL event controls.
hs.urlevent.bind(
  "media-resetWasPlaying",
  ---comment
  ---@param eventName string
  ---@param params table<string, string>
  ---@param senderPID number
  function(eventName, params, senderPID)
    hs.settings.set(wasPlayingKey, {})
  end
)
hs.urlevent.bind(
  "media-printWasPlaying",
  ---comment
  ---@param eventName string
  ---@param params table<string, string>
  ---@param senderPID number
  function(eventName, params, senderPID)
    print(hs.inspect(hs.settings.get(wasPlayingKey)))
  end
)
