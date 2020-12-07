if exists('g:loaded_compe_lamp')
  finish
endif
let g:loaded_compe_lamp = v:true

if exists('g:loaded_compe') && exists('g:loaded_lamp')
  call compe_lamp#source#attach()
endif

