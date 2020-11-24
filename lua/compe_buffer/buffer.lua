local Buffer = {}

--- new
function Buffer.new(bufnr, pattern1, pattern2)
  local self = setmetatable({}, { __index = Buffer })
  self.bufnr = bufnr
  self.regex1 = vim.regex(pattern1)
  self.regex2 = vim.regex(pattern2)
  self.words = {}
  self.processing = false
  return self
end

--- index
function Buffer.index(self)
  self.processing = true
  local index = 1
  local lines = vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, false)
  local timer = vim.loop.new_timer()
  timer:start(0, 200, vim.schedule_wrap(function()
    local chunk = math.min(index + 1000, #lines)
    for i = index, chunk do
      self:index_line(i, lines[i] or '')
    end
    index = chunk + 1

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

--- watch
function Buffer.watch(self)
  vim.api.nvim_buf_attach(self.bufnr, false, {
    on_lines = vim.schedule_wrap(function(_, _, _, firstline, _, new_lastline, _, _, _)
      if not vim.api.nvim_buf_is_valid(self.bufnr) then
        return true
      end

      local lines = vim.api.nvim_buf_get_lines(self.bufnr, firstline, new_lastline, false)
      for i, line in ipairs(lines) do
        self:index_line(firstline + i, line or '')
      end
    end)
  })
end

--- add_words
function Buffer.index_line(self, i, line)
  local words = {}

  local buffer = line
  while true do
    local s, e = self:matchstrpos(buffer)
    if s then
      local word = string.sub(buffer, s + 1, e)
      if #word > 3 and string.sub(word, #word, 1) ~= '-' then
        table.insert(words, word)
      end
    end
    local new_buffer = string.sub(buffer, e and (e + 1) or 2)
    if buffer == new_buffer then
      break
    end
    buffer = new_buffer
  end
  self.words[i] = words
end

--- get_words
function Buffer.get_words(self, lnum)
  local words = {}
  local offset = 0
  while true do
    local below = lnum - offset
    local above = lnum + offset + 1
    if not self.words[below] and not self.words[above] then
      break
    end
    if self.words[below] then
      for _, word in ipairs(self.words[below]) do
        table.insert(words, word)
      end
    end
    if self.words[above] then
      for _, word in ipairs(self.words[above]) do
        table.insert(words, word)
      end
    end
    offset = offset + 1
  end
  return words
 end

--- matchstrpos
function Buffer.matchstrpos(self, text)
  local s1, e1 = self.regex1:match_str(text)
  local s2, e2 = self.regex2:match_str(text)
  if s1 == nil and s2 == nil then
    return nil, nil
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
  return s, e
end

return Buffer

