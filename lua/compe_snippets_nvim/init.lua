local compe = require("compe")
local Source = {}
local snippets_nvim_exists, snippets_nvim = pcall(require, "snippets")

function Source.new()
  return setmetatable({}, { __index = Source })
end

function Source.get_metadata(_)
  return {
    priority = 10;
    dup = 0;
    menu = '[Snippets]';
  }
end

function Source.determine(_, context)
  if not snippets_nvim_exists then
    error("You need to install snippets.nvim!")
    return {}
  end
  return compe.helper.determine(context)
end

function Source.complete(_, context)
  local items = {}

  local snippets_list = vim.tbl_extend ('force',
    snippets_nvim.snippets._global or {},
    snippets_nvim.snippets[vim.bo.filetype] or {}
  )

  for name, expansion in pairs(snippets_list) do
    table.insert(items, {
      word = name,
      user_data = {
        snippets_nvim = {
          snippet = {expansion},
        }
      },
      kind = "Snippet",
      abbr = name,
      dup = 1
    })
  end

  context.callback({
    items = items
  })
end

function Source.confirm(_, context)
  snippets_nvim.expand_at_cursor(
    context.completed_item.user_data.snippets_nvim.snippet[1],
    context.completed_item.word
  )
end

return Source.new()

