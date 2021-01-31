local compe = require("compe")
local Source = {}

function Source.new()
  return setmetatable({}, { __index = Source })
end

function Source.get_metadata(_)
  return {
    priority = 50;
    menu = '[Vsnip]';
  }
end

function Source.determine(_, context)
  return compe.helper.determine(context)
end

function Source.complete(_, context)
  local items = vim.fn['vsnip#get_complete_items'](vim.fn.bufnr('%'))

  local add_user_data = function(item)
    item.user_data = { compe = item.user_data }
    return item
  end

  vim.tbl_map(function(item) return add_user_data(item) end, items)

  context.callback({
    items = items
  })
end

function Source.documentation(_, context)
  context.callback(
    vim.fn.json_decode(context.completed_item.user_data.compe).vsnip.snippet
  )
end

function Source.confirm(_, context)
  local item = context.completed_item

  vim.fn['vsnip#anonymous'](
    table.concat(vim.fn.json_decode(item.user_data.compe).vsnip.snippet, '\n'),
    { prefix = item.word }
  )
end

return Source.new()

