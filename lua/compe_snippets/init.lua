local compe = require("compe")
local Source = {}

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
  return compe.helper.determine(context)
end

function Source.complete(_, context)
  local items = {}

  local snippetsList = vim.tbl_extend ('force',
    require"snippets".snippets._global or {},
    require"snippets".snippets[vim.bo.filetype] or {}
  )

  for name, expansion in pairs(snippetsList) do
    table.insert(items, {
      word = name,
      userdata = {
        snippets = {
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
  require"snippets".expand_at_cursor(
    context.completed_item.userdata.snippets.snippet[1],
    context.completed_item.word
  )
end

return Source.new()

