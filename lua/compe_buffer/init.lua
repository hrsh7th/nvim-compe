local Pattern = require'compe.pattern'

local Source = {
  context = {};
  cache = {};
}

function Source:get_metadata()
  return {
    priority = 10;
    dup = 0;
    menu = '[b]';
  }
end

function Source:datermine(context)
  return {
    keyword_pattern_offset = Pattern:get_keyword_pattern_offset(context)
  }
end

function Source:complete(args)
  args.callback({
    items = self:_get_items(args.context);
  })
end

function Source:_get_items(context)
  if self.context.bufnr == context.bufnr and self.context.lnum == context.lnum then
    return self.cache
  end
  self.context = context

  local lines = {}
  for _, line in ipairs(vim.api.nvim_call_function('getbufline', { '%', '^', context.lnum - 1 })) do
    table.insert(lines, 1, line)
  end
  for _, line in ipairs(vim.api.nvim_call_function('getbufline', { '%', context.lnum, '$' })) do
    table.insert(lines, line)
  end

  local buffer = table.concat(lines, ' ')
  local regex = vim.regex(Pattern:get_keyword_pattern(context))
  local items = {}
  while true do
    local s, e = regex:match_str(buffer)
    if s == nil then
      break
    end

    local word = string.sub(buffer, s + 1, e)
    if #word > 2 and vim.tbl_contains(items, word) ~= true then
      table.insert(items, word)
    end
    buffer = string.sub(buffer, e + 1)
  end

  self.cache = items
  return self.cache
end

return Source

