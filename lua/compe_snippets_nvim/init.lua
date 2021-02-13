local compe = require("compe")
local Source = {}
local snippets_nvim_exists, snippets_nvim = pcall(require, "snippets")

function Source.new()
  return setmetatable({}, { __index = Source })
end

function Source.get_metadata(_)
  return {
    priority = 10;
    dup = 1;
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

function Source._parse_result(snippet_doc)
  local result = {}
  for _, v in ipairs(snippet_doc) do
    if type(v) == "table" then
      table.insert(result, "$" .. v.order)
    else
      table.insert(result, v)
    end
  end

  return table.concat(result)
end

function Source.documentation(self, context)
  local doc = self._parse_result(snippets_nvim.lookup_snippet(
    vim.bo.filetype, context.completed_item.word
  ))

  context.callback(doc)
end

function Source.confirm(_, context)
  snippets_nvim.expand_at_cursor(
    context.completed_item.user_data.snippets_nvim.snippet[1],
    context.completed_item.word
  )
end

return Source.new()

