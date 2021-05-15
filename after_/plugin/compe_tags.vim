if exists('g:loaded_compe_tags')
  finish
endif
let g:loaded_compe_tags = v:true

if exists('g:loaded_compe')
  lua require'compe'.register_source('tags', require'compe_tags')
endif

