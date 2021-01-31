if exists('g:loaded_compe_vsnip')
  finish
endif
let g:loaded_compe_vsnip = v:true

if exists('g:loaded_compe')
  lua require'compe'.register_source('vsnip', require'compe_vsnip')
endif

