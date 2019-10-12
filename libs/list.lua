local fs = require('coro-fs')
local http = require('coro-http')
local pathjoin = require('pathjoin')
local timer = require('timer')

local html = require('./html')
local utils = require('./utils')

local DELAY = 500 -- ms
local LOCAL_ARCHIVE_DIR = './archive'
local SUCCESS = 200

local f = string.format

local function buildURL(str, ...)
	return "http://lua-users.org/lists/lua-l" .. f(str, ...)
end

local function get(url)
	timer.sleep(DELAY)
	local res, body = http.request('GET', url)
	utils.log('%s - %s | %s', res.code, res.reason, url)
	return res.code == SUCCESS and body
end

local function scanIndex()

	local url = buildURL('/')
	local index = get(url)
	if not index then return function() end end
	index = html.removeComments(index)

	local iter = index:gmatch('<a.-href="/lists/lua%-l/(%d-)%-(%d-)/">(%d-)</a>')

	return function()
		local year, month, count = iter()
		if year and month and count then
			return tonumber(year), tonumber(month), tonumber(count)
		end
	end

end

local function scanDateIndex(year, month)

	local url = buildURL('/%04i-%02i/', year, month)
	local index = get(url)
	if not index then return function() end end

	return index:gmatch('<a.-href="msg(%d-)%.html">')

end

local function getMessage(year, month, id)

	local url = buildURL('/%04i-%02i/msg%s.html', year, month, id)
	local path = pathjoin.pathJoin(LOCAL_ARCHIVE_DIR, f('%04i', year), f('%02i', month), f('msg%s.html', id))
	local page = fs.readFile(path)

	if not page then
		page = get(url)
		fs.writeFile(path, page, true)
	end

	local head = page:match('<!%-%-X%-Head%-of%-Message%-%->(.-)<!%-%-X%-Head%-of%-Message%-End%-%->')
	local body = page:match('<!%-%-X%-Body%-of%-Message%-%->(.-)<!%-%-X%-Body%-of%-Message%-End%-%->')

	if head and body then
		head = html.cleanHead(head)
		body = html.cleanBody(body)
		return head, body, url
	end

end

return {
	scanIndex = scanIndex,
	scanDateIndex = scanDateIndex,
	getMessage = getMessage,
}
