if exists('g:loaded_compe_spell')
  finish
endif
let g:loaded_compe_spell = v:true

if exists('g:loaded_compe')
  lua require'compe'.register_source('spell', require'compe_spell')
endif

