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

--- should_auto_complete
function Context.should_auto_complete(self, context)
  return self.changedtick ~= context.changedtick and self.col ~= context.col
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

