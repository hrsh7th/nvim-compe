if exists('g:loaded_compe_snippets_nvim')
  finish
endif
let g:loaded_compe_snippets_nvim = v:true

if exists('g:loaded_compe') && luaeval('pcall(require, "snippets")')
  lua require'compe'.register_source('snippets_nvim', require'compe_snippets_nvim')
endif
