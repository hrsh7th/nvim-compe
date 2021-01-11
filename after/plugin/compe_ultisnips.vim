if match(&runtimepath, 'UltiSnips') == -1 || exists('g:loaded_compe_ultisnips')
  finish
endif
let g:loaded_compe_ultisnips = v:true

if exists('g:loaded_compe')
  lua require'compe'.register_source('ultisnips', require'compe_ultisnips')
endif

