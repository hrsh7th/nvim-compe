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
  local tags = {}
  local word = context.completed_item.word or ''

  if word == '' then return context.abort() end

  local slice = function(tbl, first, last, step)
    local sliced = {}

    for i = first or 1, last or #tbl, step or 1 do
      sliced[#sliced+1] = tbl[i]
    end

    return sliced
  end

  tags = vim.tbl_map(function(item)
    if not vim.tbl_contains(tags, item) then
      return item.filename
    end
  end, vim.fn.taglist(word))

  if #tags > 10 then
    tags = table.insert(
      slice(tags, 1, 9), string.format("...and %d more", #slice(tags, 10))
    )
  end

  context.callback(tags)
end

return Source.new()

