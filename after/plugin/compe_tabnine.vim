if exists('g:loaded_compe_tabnine')
  finish
endif
let g:loaded_compe_tabnine = v:true

if exists('g:loaded_compe')
  lua require'compe'.register_source('tabnine', require'compe_tabnine')
endif

