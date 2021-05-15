if exists('g:loaded_compe_path')
  finish
endif
let g:loaded_compe_path = v:true

if exists('g:loaded_compe')
  lua require'compe'.register_source('path', require'compe_path')
endif

