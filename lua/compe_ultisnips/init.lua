local compe = require'compe'

local M = {}

function M:get_metadata()
  return {
    priority = 50,
    dup = 0,
    menu = '[Ultisnips]',
  }
end

function M:datermine(context)
  return compe.helper.datermine(context)
end

function M:complete(args)
  if vim.fn.exists("*UltiSnips#SnippetsInCurrentScope") == 0 then
    args.abort()
    return
  end
  local receivedSnippets = vim.call('UltiSnips#SnippetsInCurrentScope')
  if vim.tbl_isempty(receivedSnippets) then
    args.abort()
    return
  end
  local completionList = {}
  for key, value in pairs(receivedSnippets) do
    local item = {
      word =  key,
      abbr =  key,
      userdata = value,
      kind = 'Snippet',
      dup = 1
    }
    table.insert(completionList, item)
  end
  args.callback{
    items = completionList
  }
end

function M:documentation(args)
  local completedItem = args.completed_item
  local userdata = completedItem.userdata
  if userdata == nil or userdata == '' then
    args.abort()
    return
  end
  args.callback(userdata)
end

return M
