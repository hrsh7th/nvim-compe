local Buffer = {}

function Buffer.new(bufnr, pattern1, pattern2)
  local self = setmetatable({}, { __index = Buffer })
  self.bufnr = bufnr
  self.regex1 = vim.regex(pattern1)
  self.regex2 = vim.regex(pattern2)
  self.words = {}
  self.lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  self.processing = true

  local index = 1
  self.timer = vim.loop.new_timer()
  self.timer:start(0, 200, vim.schedule_wrap(function()
    local text = ''
    local chunk = math.min(index + 2000, #self.lines)
    for i = index, chunk do
      text = text .. '\n' .. self.lines[i]
    end
    self:add_words(text)
    if chunk >= #self.lines then
      if self.timer then
        self.timer:stop()
        self.timer:close()
      end
      self.timer = nil
      self.processing = false
    end
  end))
  return self
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
    if #word > 2 then
      self.words[word] = true
    end
    buffer = string.sub(buffer, e + 1)
  end
end

return Buffer

