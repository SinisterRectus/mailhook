local list = require('list')
local database = require('database')
local webhook = require('webhook')
local clock = require('clock')
local utils = require('utils')

local config = require('./config')

local function main()

	utils.log('Starting main task')
	database.open()

	for year, month, count in list.scanIndex() do
		if count ~= database.getCount(year, month) then
			database.begin()
			utils.log('Downloading message IDs for %04i-%02i', year, month)
			for id in list.scanDateIndex(year, month) do
				database.addMessageId(year, month, id)
			end
			database.commit()
		end
	end

	for year, month, id in database.scanMessages(0) do

		utils.log('Parsing message %04i-%02i %s', year, month, id)
		local head, body, url = list.getMessage(year, month, id)

		if head and body and url then

			local title = head
			local description = string.format('%s\n\n%s', url, body)

			utils.log('Posting webhook for %04i-%02i %s', year, month, id)
			if webhook.post(config.WEBHOOK_ID, config.WEBHOOK_TOKEN, title, description) then
				database.setSent(year, month, id)
			end

		end

	end

	database.close()
	utils.log('Main task completed')

end

main = utils.task(main)
coroutine.wrap(main)()
clock.setCallback('hour', main)
clock.start()
