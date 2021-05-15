if exists('g:loaded_compe_vim_lsc')
  finish
endif
let g:loaded_compe_vim_lsc = v:true

if exists('g:loaded_compe') && exists('g:loaded_lsc')
  call compe_vim_lsc#source#attach()
endif



