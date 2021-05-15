if exists('g:loaded_compe_calc')
  finish
endif
let g:loaded_compe_calc = v:true

lua require'compe'.register_source('calc', require'compe_calc')

