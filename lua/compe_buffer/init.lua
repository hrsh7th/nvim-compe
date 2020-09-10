local Pattern = require'compe.pattern'

local Source = {
  context = {};
  cache = {};
}

function Source:get_metadata()
  return {
    priority = 10;
    dup = 0;
    menu = '[BUFFER]';
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
  local context_regex = vim.regex(Pattern:get_keyword_pattern(context))
  local default_regex = vim.regex(Pattern:get_default_keyword_pattern())
  local items = {}
  while true do
    local s1, e1 = context_regex:match_str(buffer)
    local s2, e2 = default_regex:match_str(buffer)
    if s1 == nil and s2 == nil then
      break
    end

    s1 = s1 or -1
    e1 = e1 or -1
    s2 = s2 or -1
    e2 = e2 or -1

    local s = s1
    local e = e1
    if s1 < s2 then
      s = s1
      e = e2
    elseif s2 < s1 then
      s = s2
      e = e2
    elseif s1 == s2 then
      if e1 > e2 then
        s = s1
        e = e1
      elseif e2 > e1 then
        s = s2
        e = e2
      end
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

