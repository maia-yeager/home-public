local class = require("pl.class")
local List = require("pl.List")
local tablex = require("pl.tablex")

---@class NSURL
---@field absoluteString string
---@field absoluteURL unknown
---@field fileSystemRepresentation string
---@field fragment? string
---@field host string
---@field isFileURL boolean
---@field lastPathComponent string
---@field parameterString? string
---@field password? string
---@field path string
---@field pathComponents string[]
---@field pathExtension string
---@field port? string
---@field query string
---@field queryItems table<string,string>
---@field resourceSpecifier string
---@field scheme string
---@field standardizedURL unknown
---@field user? string

---Callback for a URI scheme.
---@alias URIHandler fun(scheme: string, host: string, params: table<string,string>, fullURL: string, senderPID: integer): boolean|string|nil
---@alias URIDefaultHandler fun(scheme: string, host: string, params: table<string,string>, fullURL: string, senderPID: integer): nil

---@class URIHandling: pl.Class
---@overload fun(schema: SupportedSchemas): URIHandling
---@field protected handlers URIHandler[]
---@field protected defaultHandler URIDefaultHandler|string|nil
local obj = class() --[[@as URIHandling]]

-- Statics

---@enum SupportedSchemas
obj.schemas = { web = "http", mail = "mailto" }

-- Methods

---@package
function obj:_init(schema)
  if tablex.search(self.schemas, schema) == nil then
    error("uri-handling:init() - unsupported schema: " .. tostring(schema))
  end
  local key = schema .. "Callback"
  if hs.urlevent[key] ~= nil then
    error("uri-handling:init() - callback already defined for " .. schema)
  end

  self.defaultHandler = nil
  self.handlers = {}
  self.schema = schema

  hs.urlevent.setDefaultHandler(schema)
  hs.urlevent[key] = function(...)
    local eventArgs = table.pack(...)
    for _, handler in ipairs(self.handlers) do
      local res = handler(table.unpack(eventArgs))
      if res then
        -- If event is consumed, stop.
        if type(res) == "boolean" then
          return
        end
        local parts = hs.http.urlParts(res) --[[@as NSURL]]
        eventArgs = {
          parts.scheme,
          parts.host,
          parts.queryItems,
          res,
          eventArgs[5],
        }
      end
    end
    -- Otherwise, use default handler.
    if type(self.defaultHandler) == "string" then
      return hs.urlevent.openURLWithBundle(
        select(4, table.unpack(eventArgs)),
        self.defaultHandler
      )
    end
    if type(self.defaultHandler) == "function" then
      ---@diagnostic disable-next-line: param-type-mismatch
      return self.defaultHandler(table.unpack(eventArgs))
    end
    return hs.notify.show(
      "",
      "",
      "No default handler for " .. schema .. " URI schema."
    )
  end
end

---Add default URI handler.
---@param handler URIDefaultHandler|string
---@return URIHandling
function obj:setDefaultHandler(handler)
  self.defaultHandler = handler
  return self
end

---Add URI handler.
---@param fn URIHandler
---@return URIHandling
function obj:addHandler(fn)
  table.insert(self.handlers, fn)
  return self
end

return obj
