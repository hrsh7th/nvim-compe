local compe = require("compe")
local Source = {}

function Source.new()
  return setmetatable({}, { __index = Source })
end

function Source.get_metadata(_)
  return {
    priority = 100;
    dup = 1;
    menu = '[Omni]';
  }
end

function Source.determine(_, context)
  local fn = vim.bo.omnifunc
  if fn == '' then
    return nil
  end
  local completion_start_column = vim.api.nvim_call_function(fn, { 1, '' })
  if completion_start_column == -2 or completion_start_column == -3 then
    return nil
  elseif completion_start_column < 0 then
    completion_start_column = vim.api.nvim_win_get_cursor(0)[2]
  end
  return {
    keyword_pattern_offset = completion_start_column + 1,
  }
end

function Source.complete(_, context)
  context.callback({ items = vim.api.nvim_call_function(vim.bo.omnifunc, { 0, context.input }) })
end

return Source.new()

