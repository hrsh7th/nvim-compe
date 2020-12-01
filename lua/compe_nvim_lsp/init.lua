local compe = require'compe'
local Source = require'compe_nvim_lsp.source'

local source_ids = {}

return {
  attach = function()
    vim.fn.execute('augroup compe_nvim_lsp')
    vim.fn.execute('autocmd InsertEnter * lua require"compe_nvim_lsp".register()')
    vim.fn.execute('augroup END')
  end;
  register = function()
    -- unregister
    for _, source_id in ipairs(source_ids) do
      compe.unregister_source(source_id)
    end

    -- register
    local filetype = vim.fn.getbufvar('%', '&filetype')
    for id, client in pairs(vim.lsp.buf_get_clients(0)) do
      table.insert(source_ids, compe.register_source('nvim_lsp', Source.new(client, filetype)))
    end
  end;
}

