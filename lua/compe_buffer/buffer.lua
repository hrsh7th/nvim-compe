local Buffer = {}

function Buffer.new(bufnr, pattern1, pattern2)
  local self = setmetatable({}, { __index = Buffer })
  self.bufnr = bufnr
  self.pattern1 = pattern1
  self.pattern2 = pattern2
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
    self:add_words(self.pattern1, self.pattern2, text)
    if chunk >= #self.lines then
      self.timer:stop()
      self.timer:close()
      self.timer = nil
      self.processing = false
    end
  end))
  return self
end

function Buffer.add_words(self, pattern1, pattern2, text)
  local buffer = text
  local regex1 = vim.regex(pattern1)
  local regex2 = vim.regex(pattern2)
  while true do
    local s1, e1 = regex1:match_str(buffer)
    local s2, e2 = regex2:match_str(buffer)
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
    if #word > 2 then
      self.words[word] = true
    end
    buffer = string.sub(buffer, e + 1)
  end
end

return Buffer

