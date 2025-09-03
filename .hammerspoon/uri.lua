hs.urlevent.setDefaultHandler("http")
hs.urlevent.setDefaultHandler("mailto")

--- Handle HTTP/HTTPS schemes.
---@param scheme string
---@param host string
---@param params table<string, string>
---@param fullURL string
---@param senderPID number
hs.urlevent.httpCallback = function(scheme, host, params, fullURL, senderPID)
	hs.urlevent.openURLWithBundle(fullURL, "com.apple.Safari")
end

--- Handle mailto schemes.
---@param scheme string
---@param host string
---@param params table<string, string>
---@param fullURL string
---@param senderPID number
hs.urlevent.mailtoCallback = function(scheme, host, params, fullURL, senderPID)
	hs.urlevent.openURLWithBundle(fullURL, "com.apple.Mail")
end
