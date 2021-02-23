local Source = {}

Source.new = function()
  return setmetatable({}, { __index = Source })
end

Source.get_metadata = function(_)
  return {
    priority = 100;
    dup = 1;
    menu = '[Omni]';
  }
end

Source.determine = function(self, context)
  if vim.bo.omnifunc == '' then
    return nil
  end

  local start = self:_call(vim.bo.omnifunc, { 1, '' })
  if start == -2 or start == -3 then
    return nil
  elseif context.col < start then
    start = context.col - 1
  end

  return {
    keyword_pattern_offset = start + 1,
  }
end

Source.complete = function(self, args)
  local items = self:_call(vim.bo.omnifunc, { 0, args.input })
  if type(items) ~= 'table' then
    return args.abort()
  end
  args.callback({ items = items })
end

Source._call = function(_, func, args)
  local curpos = vim.api.nvim_win_get_cursor(0)
  local _, result = pcall(function()
    return vim.api.nvim_call_function(func, args)
  end)
  vim.api.nvim_win_set_cursor(0, curpos)
  return result
end

return Source.new()

