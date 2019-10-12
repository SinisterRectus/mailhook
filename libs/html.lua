local function bin(str)
	return tonumber(str, 2)
end

local codec = {
	{0x00000000, 0x0000007F, bin('00000000'), bin('01111111')},
	{0x00000080, 0x000007FF, bin('11000000'), bin('00011111')},
	{0x00000800, 0x0000FFFF, bin('11100000'), bin('00001111')},
	{0x00010000, 0x0010FFFF, bin('11110000'), bin('00000111')},
}

local mask = {bin('10000000'), bin('00111111')}

local function range(n)
	for i, v in ipairs(codec) do
		if v[1] <= n and n <= v[2] then
			return i
		end
	end
end

local char = string.char
local rshift, bor, band = bit.rshift, bit.bor, bit.band

local function utf8char(n)
	local i = range(n)
	if i == 1 then
		return char(n)
	elseif i then
		local buf = {}
		for b = i, 2, -1 do
			local byte = band(n, mask[2])
			byte = bor(mask[1], byte)
			buf[b] = char(byte)
			n = rshift(n, 6)
		end
		n = bor(codec[i][3], n)
		buf[1] = char(n)
		return table.concat(buf)
	end
end

local function utf8dec(d)
	return utf8char(tonumber(d, 10))
end

local function utf8hex(x)
	return utf8char(tonumber(x, 16))
end

local chars = {
	['lt'] = '<',
	['gt'] = '>',
	['amp'] = '&',
	['quot'] = '"',
	['apos'] = "'",
	['nbsp'] = ' ',
}

local tags = {
	['<u>'] = '__',
	['</u>'] = '__',

	['<i>'] = '*',
	['</i>'] = '*',

	['<em>'] = '*',
	['</em>'] = '*',

	['<b>'] = '**',
	['</b>'] = '**',

	['<strong>'] = '**',
	['</strong>'] = '**',

	['<li>'] = ' - ',

	['<br>'] = '\n',
	['<hr>'] = '----\n',

	['<h1>'] = '# ',
	['<h2>'] = '## ',
	['<h3>'] = '### ',
	['<h4>'] = '### ',
	['<h5>'] = '#### ',
	['<h6>'] = '##### ',
}

local function cleanHead(str)

	str = str:gsub('%b<>', '')
	str = str:gsub('&(%a-);', chars)
	str = str:gsub('&#(%d-);', utf8dec)
	str = str:gsub('&#x(%x-);', utf8hex)

	return str

end

local function cleanBody(str)

	str = str:gsub('%b<>', function(tag)
		return tags[tag:lower()] or ''
	end)

	str = str:gsub('&(%a-);', chars)
	str = str:gsub('&#(%d-);', utf8dec)
	str = str:gsub('&#x(%x-);', utf8hex)

	str = str:gsub('\n+', function(s)
		if #s > 2 then
			return '\n\n'
		end
	end)

	str = str:gsub('^%s*(.-)%s*$', '%1')

	return str

end

local function removeComments(str)
	return str:gsub('<!%-%-.-%-%->', '')
end

return {
	cleanHead = cleanHead,
	cleanBody = cleanBody,
	removeComments = removeComments,
}
