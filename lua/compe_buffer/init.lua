local Pattern = require'compe.pattern'
local Buffer = require'compe_buffer.buffer'

local Source = {
  buffers = {};
}

function Source:get_metadata()
  return {
    priority = 10;
    dup = 0;
    menu = '[BUFFER]';
  }
end

function Source:datermine(context)
  return {
    keyword_pattern_offset = Pattern:get_keyword_pattern_offset(context)
  }
end

function Source:complete(args)
  if not self.buffers[args.context.bufnr] then
    local buffer = Buffer.new(args.context.bufnr, Pattern:get_keyword_pattern(args.context), Pattern:get_default_keyword_pattern())
    buffer:index()
    buffer:watch()
    self.buffers[args.context.bufnr] = buffer
    vim.defer_fn(function()
      args.callback({
        items = vim.tbl_keys(self.buffers[args.context.bufnr].words);
        incomplete = self.buffers[args.context.bufnr].processing;
      })
    end, 100)
    return
  end
  args.callback({
    items = vim.tbl_keys(self.buffers[args.context.bufnr].words);
    incomplete = self.buffers[args.context.bufnr].processing;
  })
end

return Source

