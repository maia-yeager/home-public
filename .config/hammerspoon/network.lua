-- Alert when network status changes.
local internetAlertTitle = "Internet connectivity"
m.internetStatus:setCallback(
  ---@param self hs.network.reachability
  ---@param flags number
  ---@return nil
  function(self, flags)
    -- Clear any existing internet-related notifications.
    for _, value in
      pairs(hs.notify.deliveredNotifications() --[=[@as hs.notify[]]=])
    do
      if value:title() == internetAlertTitle then
        value:withdraw()
      end
    end

    -- Display a notification with the current status.
    if (flags & hs.network.reachability.flags.reachable) > 0 then
      return hs.notify.show(internetAlertTitle, "", "we are so back")
    end
    hs
      .notify
      .new({ withdrawAfter = 0 }) --[[@as hs.notify]]
      :title(internetAlertTitle) --[[@as hs.notify]]
      :informativeText("aw shit here we go again") --[[@as hs.notify]]
      :send()
  end
)
