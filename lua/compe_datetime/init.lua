local compe = require("compe")
local cmd = vim.cmd
local Source = {}

function Source.new()
	return setmetatable({}, {__index = Source})
end

function Source.get_metadata(_)
	return {
		priority = 88;
		dup = 1;
		menu = '[DateTime]';
	}
end

function Source.determine(_,context)
	return compe.helper.determine(context)
end

function Source.complete(_,context)
	context.callback({
		items = { "date", "time", "datetime" }
	})
end

function Source.confirm(_,context)
	local item = context.completed_item.word
	if item == "date" then
		cmd [[s/date/\=strftime('%Y-%m-%d %a')/]]
	elseif item == "time" then
		cmd [[s/time/\=strftime('%H:%M')/]]
	elseif item == "datetime" then
		cmd [[s/datetime/\=strftime('%Y-%m-%d %a %H:%M')/]]
	end
end

return Source.new()
