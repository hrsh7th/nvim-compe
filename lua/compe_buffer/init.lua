local Pattern = require'compe.pattern'
local Buffer = require'compe_buffer.buffer'

local Source = {
  buffers = {};
}

function Source.get_metadata(_)
  return {
    priority = 10;
    dup = 0;
    menu = '[BUFFER]';
    sort = false;
  }
end

function Source.datermine(_, context)
  return {
    keyword_pattern_offset = Pattern:get_keyword_pattern_offset(context)
  }
end

function Source.complete(self, args)
  local bufs = self:get_bufs()
  for _, buf in ipairs(bufs) do
    if not self.buffers[buf] then
      local buffer = Buffer.new(
        buf,
        Pattern:get_keyword_pattern_by_filetype(vim.fn.getbufvar(buf, '&filetype')),
        Pattern:get_default_keyword_pattern()
      )
      buffer:index()
      buffer:watch()
      self.buffers[buf] = buffer
    end
  end

  local processing = false

  -- gatcher words by reverse order
  local words = {}
  for i = #bufs, 1, -1 do
    processing = self.buffers[bufs[i]].processing or processing
    for j = #self.buffers[bufs[i]].words, 1, -1 do
      table.insert(words, self.buffers[bufs[i]].words[j])
    end
  end

  args.callback({
    items = words;
    incomplete = processing;
  })
end

function Source.get_bufs(_)
  local bufs = {}

  local tab = vim.fn.tabpagenr()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_tabpage(win) == tab then
      table.insert(bufs, vim.api.nvim_win_get_buf(win))
    end
  end

  return bufs
end

return Source

