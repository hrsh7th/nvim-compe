if exists('g:loaded_compe_nvim_lsp')
  finish
endif
let g:loaded_compe_nvim_lsp = v:true

if exists('g:loaded_compe')
  lua require'compe_nvim_lsp'.attach()
endif

