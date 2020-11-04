local Buffer = {}

function Buffer.new(bufnr, pattern1, pattern2)
  local self = setmetatable({}, { __index = Buffer })
  self.bufnr = bufnr
  self.regex1 = vim.regex(pattern1)
  self.regex2 = vim.regex(pattern2)
  self.words = {}
  self.processing = false
  return self
end

function Buffer.index(self)
  self.processing = true
  local index = 1
  local lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)
  local timer = vim.loop.new_timer()
  timer:start(0, 200, vim.schedule_wrap(function()
    local text = ''

    local chunk = math.min(index + 1000, #lines)
    for i = index, chunk do
      text = text .. '\n' .. lines[i]
    end
    index = chunk + 1

    self:add_words(text)
    if chunk >= #lines then
      if timer then
        timer:stop()
        timer:close()
        timer = nil
      end
      self.processing = false
    end
  end))
end

function Buffer.watch(self)
  local lnum = vim.fn.line('.')
  vim.api.nvim_buf_attach(self.bufnr, false, {
    on_lines = vim.schedule_wrap(function(_, _, _, firstline, _, new_lastline, _, _, _)
      local new_lnum = vim.fn.line('.')
      if lnum == new_lnum then
        return false
      end
      lnum = new_lnum
      self:add_words(table.concat(vim.api.nvim_buf_get_lines(self.bufnr, firstline, new_lastline, true), '\n'))
      return false
    end)
  })
end

function Buffer.add_words(self, text)
  local buffer = text
  while true do
    local s1, e1 = self.regex1:match_str(buffer)
    local s2, e2 = self.regex2:match_str(buffer)
    if s1 == nil and s2 == nil then
      break
    end

    if not s1 then
      s1 = s2
      e1 = e2
    end

    if not s2 then
      s2 = s1
      e2 = e1
    end

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
    if #word > 2 and string.sub(word, #word, 1) ~= '-' then
      self.words[word] = true
    end
    buffer = string.sub(buffer, e + 1)
  end
end

return Buffer

