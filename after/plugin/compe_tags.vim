if exists('g:loaded_compe_tags')
  finish
endif
let g:loaded_compe_tags = v:true

if exists('g:loaded_compe')
  call compe#register_source('tags', compe_tags#source#create())
endif

