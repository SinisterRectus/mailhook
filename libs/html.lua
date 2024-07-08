local utf8char = utf8.char

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
	str = str:gsub('__?%w+', '\\%1')

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
