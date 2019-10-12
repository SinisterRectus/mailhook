local http = require('coro-http')
local json = require('json')
local timer = require('timer')

local utils = require('./utils')

local TITLE_LIMIT = 256
local DESCRIPTION_LIMIT = 1024
local SUCCESS = 204
local DELAY = 2500 -- ms

-- normal ratelimit is 5/2s, but there is a hidden 30/60s limit per channel

local function truncateString(str, n, suffix)
	if #str <= n then
		return str
	else
		if suffix then
			assert(n > #suffix, 'string suffix too long')
			return str:sub(1, n - #suffix) .. suffix
		else
			return str:sub(1, n)
		end
	end
end

local function post(id, token, title, description)

	timer.sleep(DELAY)

	local url = string.format("https://discordapp.com/api/webhooks/%s/%s", id, token)

	local content = json.encode {
		embeds = {
			{
				title = truncateString(title, TITLE_LIMIT, ' ...'),
				description = truncateString(description, DESCRIPTION_LIMIT, ' ...'),
			}
		},
	}

	local res = http.request('POST', url, {
		{'content-type', 'application/json'}
	}, content)

	utils.log('%s - %s | %s', res.code, res.reason, url:gsub(token:gsub('-', '%%-'), '{token}'))

	return res.code == SUCCESS

end

return {
	post = post,
}
