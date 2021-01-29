if exists('g:loaded_compe_spell')
  finish
endif
let g:loaded_compe_spell = v:true

if exists('g:loaded_compe')
  call compe#register_source('spell', compe_spell#source#create())
endif

