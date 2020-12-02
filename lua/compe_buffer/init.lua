local compe = require'compe'
local Buffer = require'compe_buffer.buffer'

local Source = {
  buffers = {};
}

--- get_metadata
function Source.get_metadata(_)
  return {
    priority = 10;
    dup = 0;
    menu = '[BUFFER]';
  }
end

--- datermine
function Source.datermine(_, context)
  return compe.helper.datermine(context)
end

--- complete
function Source.complete(self, args)
  --- gather buffers.
  local bufs = self:_get_bufs()
  for _, buf in ipairs(bufs) do
    if not self.buffers[buf] then
      local buffer = Buffer.new(
        buf,
        compe.helper.get_keyword_pattern(vim.fn.getbufvar(buf, '&filetype')),
        compe.helper.get_default_pattern()
      )
      buffer:index()
      buffer:watch()
      self.buffers[buf] = buffer
    end
  end

  --- check processing
  local processing = false
  for _, buf in ipairs(bufs) do
    processing = processing or self.buffers[buf]
  end

  if processing then
    local timer = vim.loop.new_timer()
    timer:start(100, 0, vim.schedule_wrap(function()
      timer:stop()
      timer:close()
      timer = nil
      self:do_complete(args)
    end))
  else
    self.do_complete(args)
  end
end

--- do_complete
function Source.do_complete(self, args)
  local processing = false
  local words = {}
  local words_uniq = {}
  for _, buf in ipairs(self:_get_bufs()) do
    processing = processing or self.buffers[buf].processing
    for _, word in ipairs(self.buffers[buf]:get_words(args.context.lnum)) do
      if not words_uniq[word] then
        words_uniq[word] = true
        table.insert(words, word)
      end
    end
  end

  args.callback({
    items = words;
    incomplete = processing;
  })
end

--- _get_bufs
function Source._get_bufs(_)
  local bufs = {}

  local tab = vim.fn.tabpagenr()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_tabpage(win) == tab then
      table.insert(bufs, vim.api.nvim_win_get_buf(win))
    end
  end

  local alternate = vim.fn.bufnr('#')
  if alternate ~= -1 and not vim.tbl_contains(bufs, alternate) then
    table.insert(bufs, alternate)
  end

  return bufs
end

return Source

