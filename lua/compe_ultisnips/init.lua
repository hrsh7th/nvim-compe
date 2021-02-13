local compe = require'compe'

local M = {}

function M:get_metadata()
  return {
    priority = 50,
    dup = 1,
    menu = '[Ultisnips]',
  }
end

function M:determine(context)
  return compe.helper.determine(context)
end

function M:complete(args)
  local received_snippets = vim.F.npcall(vim.call, 'UltiSnips#SnippetsInCurrentScope') or {}
  if vim.tbl_isempty(received_snippets) then
    args.abort()
    return
  end
  local completion_list = {}
  for key, value in pairs(received_snippets) do
    local item = {
      word =  key,
      abbr =  key,
      user_data = value,
      kind = 'Snippet',
      dup = 1
    }
    table.insert(completion_list, item)
  end
  args.callback{
    items = completion_list
  }
end

function M:documentation(args)
  local completed_item = args.completed_item
  local user_data = completed_item.user_data
  if user_data == nil or user_data == '' then
    args.abort()
    return
  end
  args.callback(user_data)
end

function M:confirm(_, _)
  vim.call('UltiSnips#ExpandSnippet')
end

return M
