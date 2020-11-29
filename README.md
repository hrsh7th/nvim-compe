# nvim-compe

Auto completion plugin for nvim.


# Concept

- Lua source & Vim source
- Better matching algorithm
- Support LSP completion features (trigger character, isIncomplete)


# Usage

```viml
let g:compe_enabled = v:true
let g:compe_debug = v:false
let g:compe_min_length = 1
let g:compe_auto_preselect = v:false
let g:compe_throttle_time = 120
let g:compe_source_timeout = 200
let g:compe_incomplete_delay = 400

inoremap <silent> <C-Space> <C-r>=compe#complete()<CR>
inoremap <silent><expr> <C-e> compe#close('<C-e>')

if s:default
  inoremap <silent><expr> <CR>  compe#confirm('<CR>')
endif

if s:lexima
  inoremap <silent><expr> <CR>  compe#confirm(lexima#expand('<LT>CR>', 'i'))
endif

lua require'compe_nvim_lsp'.attach()
lua require'compe':register_lua_source('buffer', require'compe_buffer')
call compe#source#vim_bridge#register('path', compe_path#source#create())
call compe#source#vim_bridge#register('tags', compe_tags#source#create())
```


# Source

#### nvim-lsp
You can enable nvim_lsp completion via `lua require'compe_nvim_lsp'.attach()`.

#### nvim-lua
You can enable nvim_lua completion via `lua require'compe_nvim_lua'.attach()`.

#### vim-lamp
You can enable vim-lamp completion via `call compe_lamp#source#attach()`.

#### buffer
You can enable buffer completion via `lua require'compe':register_lua_source('buffer', require'compe_buffer', opts)`.

[opts](https://github.com/hrsh7th/nvim-compe/wiki#get_metadata)

#### path
You can enable path completion via `call compe#source#vim_bridge#register('path', compe_path#source#create(), opts)`.

[opts](https://github.com/hrsh7th/nvim-compe/wiki#get_metadata)

#### tags
You can enable tags completion via `call compe#source#vim_bridge#register('tags', compe_tags#source#create(), opts)`.

[opts](https://github.com/hrsh7th/nvim-compe/wiki#get_metadata)

#### vsnip
You can enable vsnip completion via `call compe#source#vim_bridge#register('vsnip', compe_vsnip#source#create(), opts)`.

[opts](https://github.com/hrsh7th/nvim-compe/wiki#get_metadata)


# Development

### special attributes

- preselect
  - Specify the item should be preselect

- filter_text
  - Specify text that will be used only filter

- sort_text
  - Specify text that will be used only sort

