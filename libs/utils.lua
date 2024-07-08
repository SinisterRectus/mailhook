local f = string.format
local len, offset = utf8.len, utf8.offset

local function log(fmt, ...)
	print(f('%s | %s', os.date('%F %T'), f(fmt, ...)))
end

local function task(fn)
	local active = false
	return function(...)
		if active then return end
		active = true
		fn(...)
		active = false
	end
end

local function truncateString(str, n, suffix)
	if len(str) <= n then
		return str
	else
		if suffix then
			assert(n > len(suffix), 'string suffix too long')
			return str:sub(1, offset(str, n - #suffix)) .. suffix
		else
			return str:sub(1, offset(str, n))
		end
	end
end

return {
	log = log,
	task = task,
	truncateString = truncateString,
}
