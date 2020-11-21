local pattern = require'compe.pattern'
local Buffer = {}
local source = {
  buffers = {};
}

--- create new buffer source
-- @param bufnr number: buffer number
-- @pattern1 string: search primary pattern
-- @pattern2 string: secondary primary pattern
-- @return new Buffer obj
Buffer.new = function(bufnr, pattern1, pattern2)
  return setmetatable({
    bufnr = bufnr,
    regex1 = vim.regex(pattern1),
    regex2 = vim.regex(pattern2),
    words = {},
    processing = false,
  }, { __index = Buffer })
end

--- indexes buffer lines
-- store lines into a ... ???
-- @see Buffer.index_line
Buffer.index = function(self)
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

--- watch buffer for line changes
-- updates indexed lines with new content??
-- @see Buffer.index_line
Buffer.watch = function(self)
  vim.api.nvim_buf_attach(self.bufnr, false, {
    on_lines = vim.schedule_wrap(function(_, _, _, firstline, _, new_lastline, _, _, _)
      local lines = vim.api.nvim_buf_get_lines(self.bufnr, firstline, new_lastline, false)
      for i, line in ipairs(lines) do
        self:index_line(firstline + i, line or '')
      end
    end)
  })
end

-- updates Buffer.words with new words.
-- @param i number: index number
-- @param line string: ???
-- @see Buffer.matchstrpos
Buffer.index_line = function(self, i, line)
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

--- get words from self.word
-- what else???
-- @param lnm number: buffer line number
-- @return table of words??
Buffer.get_words = function(self, lnum)
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

--- matches start and end position??
-- @param text string: word ??
-- @return table of words??
Buffer.matchstrpos = function(self, text)
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


--- Source definition
source.get_metadata = function(_)
  return {
    priority = 10;
    dup = 0;
    menu = '[BUFFER]';
  }
end

source.datermine = function(_, context)
  return {
    keyword_pattern_offset = pattern:get_keyword_pattern_offset(context)
  }
end

source.complete = function(self, args)
  local bufs = self:get_bufs()
  for _, buf in ipairs(bufs) do
    if not self.buffers[buf] then
      local buffer = Buffer.new(
        buf,
        pattern:get_keyword_pattern_by_filetype(vim.fn.getbufvar(buf, '&filetype')),
        pattern:get_default_keyword_pattern())
      buffer:index()
      buffer:watch()
      self.buffers[buf] = buffer
    end
  end

  local processing = false

  -- gatcher words by reverse order
  local words = {}
  for _, buf in ipairs(bufs) do
    processing = processing or self.buffers[buf].processing
    for _, word in ipairs(self.buffers[buf]:get_words(args.context.lnum)) do
      table.insert(words, word)
    end
  end

  args.callback({
    items = words;
    incomplete = processing;
  })
end

source.get_bufs = function(_)
  local bufs = {}

  local tab = vim.fn.tabpagenr()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_tabpage(win) == tab then
      table.insert(bufs, vim.api.nvim_win_get_buf(win))
    end
  end

  return bufs
end

return source
