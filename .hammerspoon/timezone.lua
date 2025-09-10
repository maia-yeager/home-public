local menubarName = 'hammerspoon:timezone'
local isoFormatter = "%Y-%m-%dT%H:%M:%S"
local utcIsoFormatter = isoFormatter .. "Z"

---@class osdatepartial
---@field day? string|integer
---@field hours? string|integer
---@field isdst? boolean
---@field min? string|integer
---@field month? string|integer
---@field sec? string|integer
---@field wday? string|integer
---@field yday? string|integer
---@field year? string|integer

--- Merge multiple `osdate` objects into a new object.
---@param date1 string | osdate Must be an `osdate` object.
---@param date2 osdatepartial Keys will override those in `date1`.
---@return osdate
local function mergeDates(date1, date2)
  if type(date1) == "string" then
    error("date1 must be an osdate, received: '" .. hs.inspect(date1) .. "'")
  end

  local newDate = {}
  for key, value in pairs(date1) do
    if date2[key] == nil then
      newDate[key] = value
    else
      newDate[key] = date2[key]
    end
  end

  return newDate
end

---@param formatter string Output formatter.
---@param nowFormatter? string Output formatter for the "Now" option. If `nil`, defaults to `formatter`.
---@return table
local function timestampSubmenu(formatter, nowFormatter)
  ---@param datePartial osdatepartial
  ---@return function
  local function copyTimestamp(datePartial)
    return function()
      hs.pasteboard.writeObjects(os.date(formatter,
        os.time(mergeDates(os.date("*t"), datePartial))))
    end
  end
  ---@param dayOffset? number
  ---@return function
  local function midnightTimestamp(dayOffset)
    return copyTimestamp({ day = dayOffset, hour = 0, min = 0, sec = 0 })
  end
  ---@param dayOffset? number
  ---@return function
  local function endOfDayTimestamp(dayOffset)
    return copyTimestamp({ day = dayOffset, hour = 23, min = 59, sec = 59 })
  end

  return {
    {
      title = "Now",
      fn = function()
        hs.pasteboard.writeObjects(os.date(nowFormatter or formatter))
      end,
    },
    { title = "-" },
    { title = "Past",             disabled = true },
    { title = "Midnight",         fn = midnightTimestamp() },
    { title = "1 Day Ago",        fn = midnightTimestamp(-1) },
    { title = "3 Days Ago",       fn = midnightTimestamp(-3) },
    { title = "7 Days Ago",       fn = midnightTimestamp(-7) },
    { title = "30 Days Ago",      fn = midnightTimestamp(-30) },
    { title = "-" },
    { title = "Future",           disabled = true },
    { title = "End of Day",       fn = endOfDayTimestamp() },
    { title = "1 Day from Now",   fn = endOfDayTimestamp(1) },
    { title = "3 Days from Now",  fn = endOfDayTimestamp(3) },
    { title = "7 Days from Now",  fn = endOfDayTimestamp(7) },
    { title = "30 Days from Now", fn = endOfDayTimestamp(30) },
  }
end

--- Get the next DST event timestamp.
---
--- Assumes that DST starts the second Sunday in March and ends the first Sunday of November.
---@param dtObj osdate
---@return integer
local function getNextDSTEvent(dtObj)
  local normalizedDt = mergeDates(dtObj, { hour = 2, min = 0, sec = 0 })

  -- Get the second Sunday of March.
  local dstStart = mergeDates(normalizedDt, { month = 3 })
  local dstStartFound = false
  for day = 7, 14 do
    local dstObj = os.date("*t", os.time(mergeDates(dstStart, { day = day }))) --[[@as osdate]]
    if dstObj.wday == 1 then
      dstStart = dstObj
      dstStartFound = true
      break
    end
  end
  if dstStartFound == false then
    error("unable to determine DST start")
  end

  -- Get the first Sunday of November.
  local dstEnd = mergeDates(normalizedDt, { month = 11 })
  local dstEndFound = false
  for day = 1, 7 do
    local dstObj = os.date("*t", os.time(mergeDates(dstEnd, { day = day }))) --[[@as osdate]]
    if dstObj.wday == 1 then
      dstEnd = dstObj
      dstEndFound = true
      break
    end
  end
  if dstEndFound == false then
    error("unable to determine DST end")
  end

  -- Compare timestamps and return the appropriate one for the next event.
  local nowStamp = os.time(dtObj)
  local dstStartStamp = os.time(dstStart)
  local dstEndStamp = os.time(dstEnd)
  if nowStamp < dstStartStamp then
    return dstStartStamp
  elseif nowStamp < dstEndStamp then
    return dstEndStamp
  end
  -- Recurse into next year if already past DST end.
  return getNextDSTEvent(mergeDates(normalizedDt,
    { year = dtObj.year + 1, month = 1, day = 1 }))
end

---@class TZMenuBar
---@field protected mbItem hs.menubar
---@field protected timer hs.timer
local tz = {}
function tz:start()
  self:stop()

  if self.mbItem == nil then
    self.mbItem = hs.menubar.new() --[[@as hs.menubar]]
    self.mbItem:autosaveName(menubarName)
    self.mbItem:setTooltip("UTC offset")
    self.mbItem:setIcon(nil)
    self.mbItem:setMenu(function()
      local dtObj = os.date("*t") --[[@as osdate]]

      -- Offset.
      local direction, hours, minutes = os
        .date("%z") --[[@as string]]
        :match("^([%-|+])(%d%d)(%d%d)$")
      local formattedOffset = direction .. hours .. ":" .. minutes

      -- Next DST event.
      local dstEvent = os
        .date("%B %d", getNextDSTEvent(dtObj)) --[[@as string]]
        :gsub("0(%d)", "%1")
        :gsub("11$", "11th")
        :gsub("12$", "12th")
        :gsub("13$", "13th")
        :gsub("1$", "1st")
        :gsub("2$", "2nd")
        :gsub("3$", "3rd")
        :gsub("(%d)$", "%1th")
      local dstEventType = dtObj.isdst and "ends" or "starts"

      return {
        {
          title = "DST " .. dstEventType .. " " .. dstEvent .. ".",
          disabled = true,
        },
        {
          title = "Copy Offset (" .. formattedOffset .. ")",
          fn = function()
            hs.pasteboard.writeObjects(formattedOffset)
          end,
        },
        { title = "-" },
        { title = "ISO 8601 / RFC 3339", disabled = true },
        { title = "Copy Naïve",          menu = timestampSubmenu(isoFormatter) },
        {
          title = "Copy UTC",
          menu = timestampSubmenu(utcIsoFormatter, "!" .. utcIsoFormatter),
        },
        {
          title = "Copy " .. os.date("%Z") .. "",
          menu = timestampSubmenu(isoFormatter .. "%z"),
        },
      }
    end)
  end
  if self.timer == nil then
    self.timer = hs.timer.doEvery(5, function()
      self:update()
    end)
    self.timer:fire()
  end
end

function tz:update()
  local offset = os.date("%Z")
  if self.mbItem:title() ~= offset then
    self.mbItem:setTitle(offset)
  end
end

function tz:stop()
  if self.mbItem ~= nil then
    self.mbItem:delete()
    self.mbItem = nil
  end
  if self.timer ~= nil then
    self.timer:stop()
    self.timer = nil
  end
end

tz:start()
