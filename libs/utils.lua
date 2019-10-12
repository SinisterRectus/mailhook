local f = string.format

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

return {
	log = log,
	task = task,
}
