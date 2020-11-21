local compe = require'compe'
-- local bridge = require'comp.completion.source.vim_bridge'
local builtin = {}

local register_vim_source = function(id, attach)
  local vimfn = nil

  if attach then -- until create or attach becomes standard.
    vimfn = vim.fn.printf("compe_%s#source#attach", id)
  else
    vimfn = vim.fn.printf("compe_%s#source#create", id)
  end

  local cmd = vim.fn.printf("call compe#source#vim_bridge#register('%s', %s())", id, vimfn)
  return vim.cmd(cmd)

  -- Don't work for some reason
  -- NOTE: might be better be moved to util or compined with compe:register_vim_source, idk...
  -- if not id == "vim_lamp" then
  --   compe:register_vim_source(id)
  -- end
  -- vim.fn[vimfn]()
end

--- activate buffer source
builtin.buffer_source = function()
 return compe:register_lua_source("buffer", require'compe.builtin.buffer')
end

--- activate nvim_lsp source
builtin.nvim_lsp_source = function()
  vim.fn.execute('augroup compe_nvim_lsp') 
  -- it may be better to have the autocmd require this file
  vim.fn.execute('autocmd InsertEnter * lua require"compe.builtin.nvim_lsp".register()')
  vim.fn.execute('augroup END')
end

--- activate vsnip source
-- @return register_vim_source("vsnip")
builtin.vsnip_source = function()
  return register_vim_source("vsnip")
end

--- activate vim-lamp source
-- @return register_vim_source("vim_lamp")
builtin.vim_lamp_source = function()
  return register_vim_source("vim_lamp", 1)
end

--- activate tags source
-- @return register_vim_source("tags")
builtin.tags_source = function()
  return register_vim_source("tags")
end

--- activate path source
-- @return register_vim_source("path")
builtin.path_source = function()
  return register_vim_source("path")
end

-- require'compe'.setup({
--   enable = true,
--   min_length = 1,
--   auto_preselect = true,
--   source_timeout = 200,
--   incomplete_delay = 400,
--   sources = {
--     "buffer",
--     "path",
--     "tags",
--     "vsnip",
--     "vim-lamp",
--     {my_custom_source = require'my_custom_source'}
--     }
--   })

builtin.use = function(sources)
 for _, source in pairs(sources) do
   local s = source:gsub("-", "_") .. "_source"
   if builtin[s] then
      builtin[s]()
    else
      print(source .. " is not a builtin source, please check source name.")
   end
 end
end

return builtin
