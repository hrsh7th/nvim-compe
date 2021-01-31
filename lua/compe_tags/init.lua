local compe = require("compe")
local Source = {}

function Source.new()
  return setmetatable({}, { __index = Source })
end

function Source.get_metadata(_)
  return {
    priority = 90;
    menu = '[Tag]';
  }
end

function Source.determine(_, context)
  return compe.helper.determine(context)
end

function Source.complete(_, context)
  context.callback({
    items = vim.fn.getcompletion(context.input, "tag"),
    incomplete = true
  })
end

function Source.documentation(_, context)
  local document = {}
  local tags = vim.fn.taglist(context.completed_item.word)

  for i, tag in ipairs(tags) do
    if 10 < i then
      table.insert(document, ('...and %d more'):format(#tags - 10))
      break
    end
    table.insert(document, tag.filename)
  end

  context.callback(document)
end

return Source.new()

