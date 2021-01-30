if exists('g:loaded_compe_snippets')
  finish
endif
let g:loaded_compe_snippets = v:true

if exists('g:loaded_compe')
  lua require'compe'.register_source('snippets', require'compe_snippets')
endif
