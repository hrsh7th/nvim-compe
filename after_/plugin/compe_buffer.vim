if exists('g:loaded_compe_buffer')
  finish
endif
let g:loaded_compe_buffer = v:true

if exists('g:loaded_compe')
  lua require'compe'.register_source('buffer', require'compe_buffer')
endif

