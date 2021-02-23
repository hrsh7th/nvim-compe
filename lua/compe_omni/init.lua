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
  end

  return {
    keyword_pattern_offset = math.min(start, context.col - 1) + 1,
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
  local prev_pos = vim.api.nvim_win_get_cursor(0)
  local _, result = pcall(function()
    return vim.api.nvim_call_function(func, args)
  end)
  local next_pos = vim.api.nvim_win_get_cursor(0)

  if prev_pos[1] ~= next_pos[1] or prev_pos[2] ~= next_pos[2] then
    vim.api.nvim_win_set_cursor(0, prev_pos)
  end

  return result
end

return Source.new()

