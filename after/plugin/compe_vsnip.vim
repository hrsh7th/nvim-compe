if exists('g:loaded_compe_vsnip')
  finish
endif
let g:loaded_compe_vsnip = v:true

if exists('g:loaded_compe')
  call compe#register_source('vsnip', compe_vsnip#source#create())
endif

