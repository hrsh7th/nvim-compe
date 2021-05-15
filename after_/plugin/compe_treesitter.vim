if exists('g:loaded_compe_treesitter')
  finish
endif
let g:loaded_compe_treesitter = v:true

if exists('g:loaded_compe') && luaeval('pcall(require, "nvim-treesitter")')
  lua require'compe'.register_source('treesitter', require'compe_treesitter')
endif

