local class = require("pl.class")

---@class MessageIndicatorAppInfo
---@field bundleName string
---@field name string
---@field icon hs.image
---@field badge? string
---@field badgeCmd? string

---@class MessageIndicator: pl.Class
---@overload fun(): MessageIndicator
---@field protected mbItem hs.menubar
---@field protected timer hs.timer
---@field protected apps table<string,MessageIndicatorAppInfo>
local obj = class() --[[@as MessageIndicator]]

local menubarName = "hammerspoon:message-indicator"
local allReadIcon = "assets/bell.fill@2x.png"
local unreadIcon = "assets/bell.badge.fill@2x.png"

function obj:_init()
  self.apps = {}

  self.timer = hs.timer.new(2, function()
    self:update()
  end)

  self.mbItem = hs.menubar.new(true, menubarName) --[[@as hs.menubar]]
  self.mbItem:setIcon(allReadIcon, false)
  self.mbItem:setMenu(function()
    local res = {}
    for appId, appInfo in pairs(self.apps) do
      if
        appInfo.badge ~= nil
        and appInfo.badge ~= ""
        and appInfo.badge ~= "0"
      then
        local item = {
          title = appInfo.name,
          image = appInfo.icon,
          fn = function()
            hs.application.launchOrFocusByBundleID(appId)
          end,
        }
        table.insert(res, item)
      end
    end

    if #res == 0 then
      return { { title = "No Notifications", disabled = true } }
    end
    return res
  end)
end

function obj:start()
  self.timer:start()
  self.timer:fire()

  return self
end

function obj:stop()
  self.mbItem:removeFromMenuBar()

  return self
end

---Add an app bundle ID to the list of allowed apps.
---@param appId string
function obj:addApp(appId, badgeCountCmd)
  local res = self:getAppInfo(appId)
  res.badgeCmd = badgeCountCmd
  self.apps[appId] = res

  return self
end

---@protected
---@param appId string
---@return MessageIndicatorAppInfo
function obj:getAppInfo(appId)
  local info = hs.application.infoForBundleID(appId)
  if info == nil then
    error("could not find app info for " .. hs.inspect(appId))
  end

  local icon = hs.image.imageFromAppBundle(appId) --[[@as hs.image]]
  if icon == nil then
    error("could not find icon for " .. hs.inspect(appId))
  end

  return {
    name = info.CFBundleDisplayName,
    bundleName = info.CFBundleName,
    icon = icon:setSize({ w = 16, h = 16 }),
  }
end

---@protected
function obj:update()
  local hasNotifications = false
  for _, info in pairs(self.apps) do
    local newBadge = hs
      .execute(
        info.badgeCmd
          or (
            "lsappinfo -all info -only StatusLabel "
            .. info.bundleName
            .. [=[ | sed -nr 's/\"StatusLabel\"=\{ \"label\"=\"(.+)\" \}$/\1/p']=]
          )
      ) --[[@as string]]
      :gsub("\n", "")

    if newBadge ~= nil and newBadge ~= "" and newBadge ~= "0" then
      hasNotifications = true
    end
    if newBadge ~= info.badge then
      info.badge = newBadge
    end
  end

  if hasNotifications then
    self.mbItem:setIcon(unreadIcon, false)
  else
    self.mbItem:setIcon(allReadIcon, false)
  end
end

return obj
