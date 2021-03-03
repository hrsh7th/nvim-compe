local Config = require'compe.config'
local Character = require'compe.utils.character'

local Context = {}

--- Create empty/invalid context for avoiding unexpected detects completion triggers.
Context.new_empty = function ()
  local context = Context.new({}, {})
  context.lnum = -1
  context.col = -1
  context.changedtick = -1
  return context
end

--- Create normal context for detecting completion triggers.
Context.new = function(option, prev_context)
  local self = setmetatable({}, { __index = Context })
  self.option = option or {}
  self.time = vim.loop.now()
  self.changedtick = vim.b.changedtick or 0
  self.manual = self.option.manual or false
  self.lnum = vim.api.nvim_win_get_cursor(0)[1]
  self.col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- zero-based index
  self.bufnr = vim.api.nvim_get_current_buf()
  self.filetype = vim.bo.filetype or ''
  self.line = vim.api.nvim_get_current_line()
  self.before_line = string.sub(self.line, 1, self.col - 1)
  self.before_char = self:get_before_char(self.lnum, self.before_line)
  self.after_line = string.sub(self.line, self.col, -1)
  self.is_trigger_character_only = self.option.trigger_character_only and Character.is_symbol(string.byte(self.before_char))
  self.prev_context = prev_context
  return self
end

--- should_complete
Context.should_auto_complete = function(self)
  if self.manual then
    return true
  end
  if self.is_trigger_character_only then
    return true
  end
  if not Config.get().autocomplete then
    return false
  end
  if self:maybe_backspace() then
    return false
  end
  if self.bufnr == self.prev_context.bufnr and self.changedtick == self.prev_context.changedtick then
    return false
  end
  return self.lnum ~= self.prev_context.lnum or self.col ~= self.prev_context.col
end


--- maybe_backspace
Context.maybe_backspace = function(self)
  return self.lnum == self.prev_context.lnum and self.col < self.prev_context.col and string.find(self.prev_context.before_line, self.before_line, 1, true) == 1
end

--- get_input
Context.get_input = function(self, start)
  return string.sub(self.line, start, self.col - 1)
end

--- get_before_char
Context.get_before_char = function(_, lnum, before_line)
  local current_lnum = lnum
  while current_lnum > 0 do
    local line = current_lnum == lnum and before_line or vim.api.nvim_get_current_line()
    local _, _, c = string.find(line, '([^%s])%s*$')
    if c ~= nil then
      return (not Character.is_white(string.byte(c))) and c or ''
    end
    current_lnum = current_lnum - 1
  end
  return ''
end

return Context

