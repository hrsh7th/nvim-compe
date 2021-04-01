if exists('g:loaded_compe_luasnip')
  finish
endif
let g:loaded_compe_luasnip = v:true

if exists('g:loaded_compe') && luaeval('pcall(require, "luasnip")')
  lua require'compe'.register_source('luasnip', require'compe_luasnip')
endif
