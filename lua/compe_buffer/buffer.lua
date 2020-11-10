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

--- watch
function Buffer.watch(self)
  vim.api.nvim_buf_attach(self.bufnr, false, {
    on_lines = vim.schedule_wrap(function(_, _, _, firstline, _, new_lastline, _, _, _)
      local text = table.concat(vim.api.nvim_buf_get_lines(self.bufnr, firstline, new_lastline, false), '\n')
      if string.sub(vim.fn.mode(), 1, 1) == 'i' then
        text = string.sub(text, 1, vim.fn.col('.') - 1)
        text = self:trim_ending_word(text)
      end
      self:add_words(text)
    end)
  })
end

--- trim_ending_word
function Buffer.trim_ending_word(self, text)
  local buffer = text
  local target_s = nil
  local target_e = nil
  while true do
    local s, e = self:matchstrpos(buffer)
    if s then
      target_s = s + #text - #buffer
      target_e = e + #text - #buffer
    end

    local new_buffer = string.sub(buffer, e and (e + 1) or 2)
    if buffer == new_buffer then
      break
    end
    buffer = new_buffer
  end

  -- does not match any words
  if not target_s then
    return ''
  end

  -- the end of buffer is not a word
  if #text ~= target_e then
    return text
  end

  -- remove ending word
  return string.sub(text, 1, target_s)
end

--- add_words
function Buffer.add_words(self, text)
  local buffer = text
  while true do
    local s, e = self:matchstrpos(buffer)
    if s then
      local word = string.sub(buffer, s + 1, e)
      if #word > 3 and string.sub(word, #word, 1) ~= '-' then
        self:add_word(word)
      end
    end
    local new_buffer = string.sub(buffer, e and (e + 1) or 2)
    if buffer == new_buffer then
      break
    end
    buffer = new_buffer
  end
end

--- add_word
function Buffer.add_word(self, word)
  for i, word_ in ipairs(self.words) do
    if word_ == word then
      table.remove(self.words, i)
      break
    end
  end
  table.insert(self.words, word)
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

