if exists('g:loaded_compe_path')
  finish
endif
let g:loaded_compe_path = v:true

if exists('g:loaded_compe')
  call compe#register_source('path', compe_path#source#create())
endif

