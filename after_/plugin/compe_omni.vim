if exists('g:loaded_compe_omni')
  finish
endif
let g:loaded_compe_omni = v:true

if exists('g:loaded_compe')
  lua require'compe'.register_source('omni', require'compe_omni')
endif

