if exists('g:loaded_compe_emoji')
  finish
endif
let g:loaded_compe_emoji = v:true

lua require'compe'.register_source('emoji', require'compe_emoji')
