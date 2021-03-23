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

  local snippets_list = {}
  local filetypes = vim.split(vim.bo.filetype, ".", true)
  table.insert(filetypes, '_global')
  for _ , ft in ipairs(filetypes) do
    snippets_list = vim.tbl_extend ('force',
    snippets_nvim.snippets[ft] or {},
    snippets_list
    )
  end

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
  local filetypes = vim.split(vim.bo.filetype, ".", true)
  local snippet = nil
  local _global_snippet = snippets_nvim.lookup_snippet(
                            '', context.completed_item.word
                          )
  for _ , ft in ipairs(filetypes) do
    s = snippets_nvim.lookup_snippet(ft, context.completed_item.word)
    if s ~= _global_snippet then
      -- snippet from first filetype will be used
      snippet = snippet or s
    end
  end
  -- if there is only a _global snippet
  snippet = snippet or _global_snippet
  local doc = self._parse_result(snippet)

  context.callback(doc)
end

function Source.confirm(_, context)
  snippets_nvim.expand_at_cursor(
    context.completed_item.user_data.snippets_nvim.snippet[1],
    context.completed_item.word
  )
end

return Source.new()

