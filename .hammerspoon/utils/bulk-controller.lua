local class = require("pl.class")

---@class BulkController: pl.Class
---@overload fun(): BulkController
local obj = class() --[[@as BulkController]]

function obj:startAll()
  for _, value in pairs(self) do
    if type(value) == "table" then
      if type(value.start) == "function" then
        value:start()
      end
      if type(value.startAll) == "function" then
        value:startAll()
      end
    end
  end
end
function obj:stopAll()
  for _, value in pairs(self) do
    if type(value) == "table" then
      if type(value.stop) == "function" then
        value:stop()
      end
      if type(value.stopAll) == "function" then
        value:stopAll()
      end
    end
  end
end

return obj
