local compe = require'compe'
local Source = require'compe_nvim_lsp.source'

local source_ids = {}

return {
  attach = function()
    vim.api.nvim_exec([[
      augroup compe_nvim_lsp
      autocmd InsertEnter * lua require"compe_nvim_lsp".register()
      augroup END
    ]], false)
  end;
  register = function()
    -- unregister
    for _, source_id in ipairs(source_ids) do
      compe.unregister_source(source_id)
    end
    source_ids = {}

    -- register
    local filetype = vim.bo.filetype
    for _, client in pairs(vim.lsp.buf_get_clients(0)) do
      table.insert(source_ids, compe.register_source('nvim_lsp', Source.new(client, filetype)))
    end
  end;
}

