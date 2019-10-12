local timer = require('timer')

local callbacks = {}

local interval

local function start()
	local prev = os.date('!*t')
	interval = interval or timer.setInterval(1000, function()
		local now = os.date('!*t')
		for k, fn in pairs(callbacks) do
			if prev[k] ~= now[k] then
				coroutine.wrap(fn)(now)
			end
		end
		prev = now
	end)
end

local function stop()
	timer.stopInterval(interval)
	interval = nil
end

local function setCallback(k, fn)
	callbacks[k] = fn
end

return {
	start = start,
	stop = stop,
	setCallback = setCallback,
}
