# nvim-compe

Auto completion plugin for nvim.

## Table Of Contents
- [Concept](#concept)
- [Usage](#usage)
  - [Prerequisite](#prerequisite)
  - [Configuring in Vimscript](#configuring-in-vimscript)
  - [Configuring in Lua](#configuring-in-lua)
  - [Mappings](#mappings)
  - [Source Configuration](#source-configuration)
- [Builtin Sources](#builtin-sources)
- [Development](#development)
  - [Example Source](#example-source)
  - [The Source](#the-source)
  - [Public API](#public-api)
    - [Vimscript](#vim-script)
    - [Lua](#lua)


## Concept

- Lua source & Vim source
- Better matching algorithm
- Support LSP completion features (trigger character, isIncomplete)


## Usage

The `source` option is required but others can be omitted.

### Prerequisite
You must set `completeopt` to `menu,menuone,noselect` which can be easily done as follows.

Using Vimscript
```viml
set completeopt=menu,menuone,noselect
```
or using Lua
```lua
vim.o.completeopt = "menu,menuone,noselect"
```

### Configuring in Vimscript

If you're using `init.vim`, here are the available options for `nvim-compe`.

```viml
let g:compe = {}
let g:compe.enabled = v:true " whether or not nvim-compe is enabled. default: `true`.
let g:compe.debug = v:false " whether or not nvim-compe should display debug info. default: `false`
let g:compe.min_length = 1 " minimal length to trigger completion. default: `1`
" controls nvim-compe preselect behaviour. default: `enable`
" enable: preselect completion item only if the source told nvim-compe to do so. Eg. completion from `gopls`
" disable: never preselect completion item regardless of source
" always: always preselect completion item regardless of source
let g:compe.preselect = 'enable' " default: `enable`
let g:compe.throttle_time = 80 " throttle nvim-compe completion menu. default: `80`
let g:compe.source_timeout = 200 " timeout for nvim-compe to get completion items. default: `200`
let g:compe.incomplete_delay = 400 " delay for LSP's `isIncomplete`. default: `400`
let g:compe.allow_prefix_unmatch = v:false

-- define your nvim-compe sources here
-- you MUST fill this field
let g:compe.source = {}
let g:compe.source.path = v:true " path completion. default: `false`
let g:compe.source.buffer = v:true " buffer completion. default: `false`
let g:compe.source.vsnip = v:true " vsnip completion, make sure you have `vim-vsnip` installed. default: `false`
let g:compe.source.nvim_lsp = v:true " nvim builtin LSP completion. default: `false`
let g:compe.source.nvim_lua = v:true " nvim's lua stdlib completion. default: `false`
let g:compe.source.your_awesome_source = {
  " you can also override completion source configuration
  " by setting it to a `table` instead of `boolean`
  " see `Source Configuration` for more information
  \}
```

### Configuring in Lua

If you're using `init.lua`, you must call the `setup` function that `nvim-compe` provides.

```lua
require'compe'.setup {
  enabled = true; -- whether or not nvim-compe is enabled. default: `true`.
  debug = false; -- whether or not nvim-compe should display debug info. default: `false`
  min_length = 1; -- minimal length to trigger completion. default: `1`
  -- controls nvim-compe preselect behaviour. default: `enable`
  -- enable: preselect completion item only if the source told nvim-compe to do so. Eg. completion from `gopls`
  -- disable: never preselect completion item regardless of source
  -- always: always preselect completion item regardless of source
  preselect = 'enable'; -- default: `enable`
  throttle_time = 80; -- throttle nvim-compe completion menu. default: `80`
  source_timeout = 200; -- timeout for nvim-compe to get completion items. default: `200`
  incomplete_delay = 400; -- delay for LSP's `isIncomplete`. default: `400`
  allow_prefix_unmatch = false;

  -- define your nvim-compe sources here
  -- you MUST fill this field
  source = {
    path = true; -- path completion. default: `false`
    buffer = true; -- buffer completion. default: `false`
    vsnip = true; -- vsnip completion, make sure you have `vim-vsnip` installed. default: `false`
    nvim_lsp = true; -- nvim builtin LSP completion. default: `false`
    nvim_lua = true; -- nvim's lua stdlib completion. default: `false`
    your_awesome_source = {
      -- you can also override completion source configuration
      -- by setting it to a `table` instead of `boolean`
      -- see `Source Configuration` for more information
    };
  };
}
```

### Mappings
If you don't use any autopair plugin.
```viml
inoremap <silent><expr> <C-Space> compe#complete()
inoremap <silent><expr> <CR>      compe#confirm('<CR>')
inoremap <silent><expr> <C-e>     compe#close('<C-e>')
```

If you use [cohama/lexima.vim](https://github.com/cohama/lexima.vim)
```viml
inoremap <silent><expr> <C-Space> compe#complete()
inoremap <silent><expr> <CR>      compe#confirm(lexima#expand('<LT>CR>', 'i'))
inoremap <silent><expr> <C-e>     compe#close('<C-e>')
```

### Source Configuration

The sources can be configured by `let g:compe.source['source_name'] = { ...configuration... }` in Vimscript or passing the configuration inside `sources['source_name']` table in Lua.

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


## Built-in sources

- buffer
- path
- tags
- nvim_lsp
- nvim_lua
- vim_lsp
- lamp
- vsnip
- ultisnips



## Development

### Example source

You can see example on [vim-dadbod-completion](https://github.com/kristijanhusak/vim-dadbod-completion)

- implementation
  - https://github.com/kristijanhusak/vim-dadbod-completion/blob/master/autoload/vim_dadbod_completion/compe.vim
- registration
  - https://github.com/kristijanhusak/vim-dadbod-completion/blob/master/after/plugin/vim_dadbod_completion.vim#L4


### The source

The source is defined as dict that has `get_metadata`/`determine`/`complete` and `documentation(optional)`.

- *get_metadata*
  - This function should return the default source configuration. see `Source configuration` section.
- *determine*
  - This function should return dict as `{ keyword_pattern_offset = 1-origin number; trigger_character_offset = 1-origin number}`.
  - If this function returns empty, nvim-compe will do nothing.
- *complete*
  - This function should callback the completed items as `args.callback({ items = items })`.
  - If you want to stop the completion process, you should call `args.abort()`.
- *documentation*
  - You can provide documentation for selected items.


### Public API

The compe is under development so I will apply breaking change sometimes.

The below APIs are mark as public.

#### Vim script

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

#### Lua

```lua
-- Setup user configuration.
require'compe'.setup({ ... })

-- Register and unregister source.
local id = require'compe'.register_source(name, source)
require'compe'.unregister_source(id)

-- Source helpers.
require'compe'.helper.*
```

