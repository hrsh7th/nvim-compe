-- TODO: Use vim regex for split word
-- TODO: Define language keyword patterns in core.
local default_pattern = '([%a%$_][%w%-_]*)'

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
    keyword_pattern_offset = string.find(context.before_line, default_pattern .. '$')
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
  local items = {}
  local start = 0
  while true do
    local s, e, t = string.find(buffer, default_pattern, start + 1)
    if s == nil then
      break
    end

    if #t > 2 and vim.tbl_contains(items, t) ~= true then
      table.insert(items, t)
    end
    start = e
  end

  self.cache = items
  return self.cache
end

return Source

