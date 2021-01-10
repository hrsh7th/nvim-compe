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
  end
  local receivedSnippets = vim.call('UltiSnips#SnippetsInCurrentScope')
  if vim.tbl_isempty(receivedSnippets) then
    args.abort()
    return
  end
  local completionList = {}
  for key, value in pairs(receivedSnippets) do
    -- local userdata = {snippet_source = 'UltiSnips', hover = value}
    local item = {
      word =  key,
      abbr =  key,
      menu = value,
      kind = 'Snippet',
      dup = 1
    }
    table.insert(completionList, item)
  end
  args.callback{
    items = completionList
  }
end

return M
