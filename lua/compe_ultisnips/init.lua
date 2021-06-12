local compe = require'compe'

-- matches any text within backticks, skipping over escaped ones
local EXPRESSION_REGEX = vim.regex([[`\(\\`\|[^`]\)\+`]])

local M = {}

local function get_snippet_preview(data, args)
  local filepath = string.gsub(data.location, '.snippets:%d*', '.snippets')
  local _, _, linenr = string.find(data.location, ':(%d+)')
  local content = vim.fn.readfile(filepath)

  local snippet = {}
  local count = 0

  table.insert(snippet, '```' .. args.context.filetype)
  for i, line in pairs(content) do
    if i > linenr - 1 then
      local is_snippet_header = line:find('^snippet%s[^%s]') ~= nil
      count = count + 1
      if line:find('^endsnippet') ~= nil or is_snippet_header and count ~= 1 then
        break
      end
      if not is_snippet_header then
        local s, e = EXPRESSION_REGEX:match_str(line)
        while s do
          local expr = string.sub(line, s+2, e-1)
          local prefix = string.sub(expr, 1, 2)
          local evaluated
          if prefix == '!v' then
            evaluated = vim.api.nvim_eval(string.sub(expr, 3))
          elseif prefix == '!p' then
            -- TODO: implement python interpolation (value of snip.rv)
            evaluated = expr
          else
            evaluated = vim.fn.system(expr)
          end
          line = string.sub(line, 1, s+1) .. evaluated .. string.sub(line, e+1)
          s, e = EXPRESSION_REGEX:match_str(line)
        end
        table.insert(snippet, line)
      end
    end
  end
  table.insert(snippet, '```')

  return snippet
end

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
  local received_snippets = vim.F.npcall(vim.call, 'UltiSnips#SnippetsInCurrentScope', 1) or {}

  if vim.tbl_isempty(received_snippets) then
    args.abort()
    return
  end

  local snippets_list = vim.g.current_ulti_dict_info

  local completion_list = {}
  for key, value in pairs(snippets_list) do
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
  args.callback(get_snippet_preview(user_data, args))
end

function M:confirm(_, _)
  vim.call('UltiSnips#ExpandSnippet')
end

return M
