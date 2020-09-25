# nvim-compe

Auto completion plugin

# Concept

- Lua implementation
- Lua source & Vim source

# Usage

```viml
let g:compe_enabled = v:true
let g:compe_min_length = 1

if s:default
  inoremap <expr><CR>  compe#confirm('<CR>')
  inoremap <expr><C-e> compe#close('<C-e>')
  inoremap <silent><C-Space> <C-r>=compe#complete()<CR>
endif

if s:lexima
  inoremap <expr><CR>  compe#confirm(lexima#expand('<LT>CR>', 'i'))
  inoremap <expr><C-e> compe#close('<C-e>')
endif

lua require'compe_nvim_lsp'.attach()
lua require'compe':register_lua_source('buffer', require'compe_buffer')
call compe#source#vim_bridge#register('path', compe_path#source#create())
```

# Source

#### nvim-lsp
You can enable nvim_lsp completion via `lua require'compe_nvim_lsp'.attach()`.

#### vim-lamp
You can enable vim-lamp completion via `call compe_lamp#source#attach()`.

#### buffer
You can enable buffer completion via `lua require'compe':register_lua_source('buffer', require'compe_buffer')`.

#### path
You can enable path completion via `call compe#source#vim_bridge#register('path', compe_path#source#create())`.

#### vsnip
You can enable vsnip completion via `call compe#source#vim_bridge#register('vsnip', compe_vsnip#source#create())`.



# Development

### special attributes

- preselect
  - Specify the item should be preselect
- filter_text
  - Specify text that will be used only filter
- sort_text
  - Specify text that will be used only sort

