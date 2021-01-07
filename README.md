# nvim-compe

Auto completion plugin for nvim.


# Concept

- Lua source & Vim source
- Better matching algorithm
- Support LSP completion features (trigger character, isIncomplete)


# Usage

The `source` option is required but others can be omitted.

```viml

" You must set this option.
set completeopt=menu,menuone,noselect

if s:viml
  let g:compe = {}
  let g:compe.enabled = v:true
  let g:compe.debug = v:false
  let g:compe.min_length = 1
  let g:compe.preselect = 'enable' || 'disable' || 'always'
  let g:compe.throttle_time = ... number ...
  let g:compe.source_timeout = ... number ...
  let g:compe.incomplete_delay = ... number ...
  let g:compe.allow_prefix_unmatch = v:false

  let g:compe.source = {}
  let g:compe.source.path = v:true
  let g:compe.source.buffer = v:true
  let g:compe.source.vsnip = v:true
  let g:compe.source.nvim_lsp = v:true
  let g:compe.source.nvim_lua = { ... overwrite source configuration ... }
endif

if s:lua
lua <<EOF
require'compe'.setup {
  enabled = true;
  debug = false;
  min_length = 1;
  preselect = 'enable' || 'disable' || 'always';
  throttle_time = ... number ...;
  source_timeout = ... number ...;
  incomplete_delay = ... number ...;
  allow_prefix_unmatch = false;

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

## Source configuration

The sources can be configured by `let g:compe.source['source_name'] = { ...configuration... }`.

- *priority*
  - Specify source priority.
- *filetypes*
  - Specify source filetypes.
- *ignored_filetypes*
  - Specify filetypes that should not use this source.
- *sort*
  - Specify source is sortable or not.
- *dup*
  - Specify source candidates can have the same word another item.
- *menu*
  - Specify item's menu (see `:help complete-items`)


# Built-in sources

- buffer
- path
- tags
- nvim_lsp
- nvim_lua
- lamp
- vsnip


# Development

## Example source

You can see example on [vim-dadbod-completion](https://github.com/kristijanhusak/vim-dadbod-completion)

- implementation
  - https://github.com/kristijanhusak/vim-dadbod-completion/blob/master/autoload/vim_dadbod_completion/compe.vim
- registration
  - https://github.com/kristijanhusak/vim-dadbod-completion/blob/master/after/plugin/vim_dadbod_completion.vim#L4


## The source

The source is defined as dict that has `get_metadata`/`datermine`/`complete` and `documentation(optional)`.

- *get_metadata*
  - This function should return the default source configuration. see `Source configuration` section.
- *datermine*
  - This function should return dict as `{ keyword_pattern_offset = 1-origin number; trigger_character_offset = 1-origin number}`.
  - If this function returns empty, nvim-compe will do nothing.
- *complete*
  - This function should callback the completed items as `args.callback({ items = items })`.
  - If you want to stop the completion process, you should call `args.abort()`.
- *documentation*
  - You can provide documentation for selected items.


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

