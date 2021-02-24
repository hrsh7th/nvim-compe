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
    menu = '[Buffer]';
  }
end

--- determine
function Source.determine(_, context)
  return compe.helper.determine(context)
end

--- complete
function Source.complete(self, args)
  --- check processing
  local processing = false
  for _, buffer in ipairs(self:_get_buffers()) do
    processing = processing or buffer.processing
  end

  if processing then
    local timer = vim.loop.new_timer()
    timer:start(100, 0, vim.schedule_wrap(function()
      timer:stop()
      timer:close()
      timer = nil
      self:_do_complete(args)
    end))
  else
    self:_do_complete(args)
  end
end

--- _do_complete
function Source._do_complete(self, args)
  local processing = false
  local words = {}
  local words_uniq = {}
  for _, buffer in ipairs(self:_get_buffers()) do
    processing = processing or buffer.processing
    for _, word in ipairs(buffer:get_words(args.context.lnum)) do
      if not words_uniq[word] and args.input ~= word then
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
function Source._get_buffers(self)
  local bufs = {}
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    bufs[vim.api.nvim_win_get_buf(win)] = true
  end

  local buffers = {}
  for _, buf in ipairs(vim.tbl_keys(bufs)) do
    if not self.buffers[buf] then
      local buffer = Buffer.new(
        buf,
        compe.helper.get_keyword_pattern(vim.bo.filetype),
        compe.helper.get_default_pattern()
      )
      buffer:index()
      buffer:watch()
      self.buffers[buf] = buffer
    end
    table.insert(buffers, self.buffers[buf])
  end

  return buffers
end

return Source
