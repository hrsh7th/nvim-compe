# nvim-compe

Auto completion plugin for nvim.


# Concept

- Lua source & Vim source
- Better matching algorithm
- Support LSP completion features (trigger character, isIncomplete)


# Usage

```viml
if s:viml
  let g:compe = {}
  let g:compe.enabled = v:true
  let g:compe.debug = v:false
  let g:compe.min_length = 1
  let g:compe.auto_preselect = v:true
  let g:compe.throttle_time = 120
  let g:compe.source_timeout = 200
  let g:compe.incomplete_delay = 400

  let g:compe.source = {}
  let g:compe.source.path = v:true
  let g:compe.source.buffer = v:true
  let g:compe.source.vsnip = v:true
  let g:compe.source.nvim_lsp = v:true
  let g:compe.source.nvim_lua = { 'filetype': ['lua', 'lua.pad'] }
endif

if s:lua
lua <<EOF
require'compe'.setup {
  enabled = true;
  debug = false;
  min_length = 1;
  auto_preselect = false;
  throttle_time = 120;
  source_timeout = 200;
  incomplete_delay = 400;

  source = {
    path = true;
    buffer = true;
    vsnip = true;
    nvim_lsp = true;
    nvim_lua = { ... overwrite source configuration ... };
  };
}
EOF
endif

if s:default
  inoremap <silent><expr> <C-Space> compe#complete()
  inoremap <silent><expr> <CR>      compe#confirm('<CR>')
  inoremap <silent><expr> <C-e>     compe#close('<C-e>')
endif

if s:lexima
  inoremap <silent><expr> <C-Space> compe#complete()
  inoremap <silent><expr> <CR>      compe#confirm(lexima#expand('<LT>CR>', 'i'))
  inoremap <silent><expr> <C-e>     compe#close('<C-e>')
endif
```


# Built-in sources

- nvim_lsp
- nvim_lua
- buffer
- path
- lamp
- vsnip


# Development

## Public API

The compe is under development so I will apply breaking change sometimes.

The below APIs are mark as public.

### Vim script

```viml
" Setup user configuration.
call compe#setup({ ... })

" Register and unregister source.
let l:id = compe#register_source('name', s:source)
call compe#unregister_source(l:id)

" Invoke completion.
call compe#complete()

" Confirm selected item.
call compe#confirm('<C-y>') " optional fallback key.

" Close completion menu.
call compe#close('<C-e>') " optional fallback key.

" Source helpers.
call compe#helper#*()
```

### Lua

```lua
-- Setup user configuration.
require'compe'.setup({ ... })

-- Register and unregister source.
local id = require'compe'.register_source(name, source)
require'compe'.unregister_source(id)

-- Source helpers.
require'compe'.helper.*
```

## Source configuration

The source configuration can be defined by `source.get_metadata` function.

- *priority*
  - Specify source priority.
- *filetypes*
  - Specify source enabling filetypes.
- *sort*
  - Specify the source candidates will be sorted or not.
- *dup*
  - Specify the source candidates will be allowed existing other same word candidate or not.
- *menu*
  - Specify item's menu (see `:help complete-items`)

