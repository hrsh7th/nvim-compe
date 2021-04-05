local compe = require("compe")
local Source = {}

function Source.new()
  return setmetatable({}, { __index = Source })
end

function Source.get_metadata(_)
  return {
    priority = 50;
    dup = 1,
    menu = '[Vsnip]';
  }
end

function Source.determine(_, context)
  return compe.helper.determine(context)
end

function Source.complete(_, context)
  local items = vim.fn['vsnip#get_complete_items'](vim.api.nvim_get_current_buf())

  for _, item in ipairs(items) do
    item.user_data = { compe = item.user_data }
    item.kind = nil
    item.menu = nil
  end

  context.callback({
    items = items
  })
end

function Source.resolve(_, args)
  args.completed_item.info = table.concat({
    '```' .. vim.bo.filetype,
    vim.fn['vsnip#to_string'](vim.fn.json_decode(args.completed_item.user_data.compe).vsnip.snippet),
    '```'
  }, "\n")
  args.callback(args.completed_item)
end

function Source.confirm(_, context)
  local item = context.completed_item

  vim.fn['vsnip#anonymous'](
    table.concat(vim.fn.json_decode(item.user_data.compe).vsnip.snippet, '\n'),
    { prefix = item.word }
  )
end

return Source.new()

