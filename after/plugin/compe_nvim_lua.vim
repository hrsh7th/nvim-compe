if exists('g:loaded_compe_nvim_lua')
  finish
endif
let g:loaded_compe_nvim_lua = v:true

if exists('g:loaded_compe')
  lua require'compe'.register_source('nvim_lua', require'compe_nvim_lua')
endif

