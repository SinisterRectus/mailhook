local sql = require('sqlite3')

local db, stmts

local function open()

	if db then return end
	db = sql.open('msglist.db')

	db:exec [[
	CREATE TABLE IF NOT EXISTS messages (
		year INTEGER NOT NULL,
		month INTEGER NOT NULL,
		id TEXT NOT NULL,
		sent INTENGER NOT NULL,
		PRIMARY KEY (year, month, id)
	)
	]]

	stmts = setmetatable({}, {__index = function(self, cmd)
		self[cmd] = db:prepare(cmd)
		return self[cmd]
	end})

end

local function close()
	if not db then return end
	db:close()
	db = nil
end

local function getStatement(cmd, ...)
	if select('#', ...) > 0 then
		return stmts[cmd]:reset():bind(...)
	else
		return stmts[cmd]:reset()
	end
end

local function exec(cmd, ...)
	return getStatement(cmd, ...):step()
end

local function cleanRow(row)
	for k, v in pairs(row) do
		row[k] = type(v) == 'cdata' and tonumber(v) or v
	end
end

local function iter(cmd, ...)
	local row = {}
	local stmt = getStatement(cmd, ...)
	return function()
		row = stmt:step(row)
		if row then
			cleanRow(row)
			return unpack(row)
		end
	end
end

local function begin()
	return exec('BEGIN')
end

local function commit()
	return exec('COMMIT')
end

local function getCount(year, month)
	local res = exec('SELECT count(*) FROM messages WHERE year == ? AND month == ?', year, month)
	return tonumber(res[1]) or 0
end

local function addMessageId(year, month, id)
	return exec('INSERT OR IGNORE INTO messages (year, month, id, sent) VALUES (?, ?, ?, ?)', year, month, id, 0)
end

local function scanMessages(sent)
	return iter('SELECT year, month, id FROM messages WHERE sent == ? ORDER BY 1, 2, 3 ASC', sent)
end

local function setSent(year, month, id)
	return exec('UPDATE messages SET sent = 1 WHERE year == ? AND month == ? AND id == ?', year, month, id)
end

local function forceFirstUnsent(year, month, id)
	begin()
	exec('UPDATE messages SET sent = 0')
	if year then
		exec('UPDATE messages SET sent = 1 WHERE year < ?', year)
		if month then
			exec('UPDATE messages SET sent = 1 WHERE year == ? AND month < ?', year, month)
			if id then
				exec('UPDATE messages SET sent = 1 WHERE year == ? AND month == ? AND id < ?', year, month , id)
			end
		end
	end
	commit()
end

return {
	open = open,
	close = close,
	begin = begin,
	commit = commit,
	getCount = getCount,
	addMessageId = addMessageId,
	scanMessages = scanMessages,
	setSent = setSent,
	forceFirstUnsent = forceFirstUnsent,
}
