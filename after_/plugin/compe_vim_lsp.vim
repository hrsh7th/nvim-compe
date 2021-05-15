if exists('g:loaded_compe_vim_lsp')
  finish
endif
let g:loaded_compe_vim_lsp = v:true

if exists('g:loaded_compe') && exists('g:lsp_loaded')
  call compe_vim_lsp#source#attach()
endif


