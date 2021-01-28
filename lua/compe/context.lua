local Context = {}

function Context.new(option)
  local self = setmetatable({}, { __index = Context })
  self.time = vim.loop.now()
  self.changedtick = vim.fn.getbufvar('%', 'changedtick', 0)
  self.manual = option.manual or false
  self.lnum = vim.fn.line('.')
  self.col = vim.fn.col('.')
  self.bufnr = vim.fn.bufnr('%')
  self.filetype = vim.fn.getbufvar('%', '&filetype', '')
  self.line = vim.fn.getline('.')
  self.before_line = string.sub(self.line, 1, self.col - 1)
  self.before_char = self:get_before_char(self.lnum, self.before_line)
  self.after_line = string.sub(self.line, self.col, -1)
  return self
end

--- should_complete
function Context.should_complete(self, new_context)
  if new_context.manual then
    return true
  end
  return self.changedtick ~= new_context.changedtick and (self.lnum ~= new_context.lnum or self.col ~= new_context.col)
end

--- maybe_backspace
function Context.maybe_backspace(self, new_context)
  return self.lnum == new_context.lnum and self.col == new_context.col + 1 and string.find(self.before_line, new_context.before_line, 1, true) == 1
end

--- get_input
function Context.get_input(self, start)
  return string.sub(self.line, start, self.col - 1)
end

--- get_before_char
function Context.get_before_char(_, lnum, before_line)
  local current_lnum = lnum
  while current_lnum > 0 do
    local line = current_lnum == lnum and before_line or vim.fn.getline(current_lnum)
    local _, _, c = string.find(line, '([^%s])%s*$')
    if c ~= nil then
      break
    end
    current_lnum = current_lnum - 1
  end
  return string.sub(before_line, #before_line, #before_line)
end

return Context

