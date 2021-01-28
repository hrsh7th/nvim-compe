# nvim-compe

Auto completion plugin for nvim.

## Table Of Contents
- [Concept](#concept)
- [Usage](#usage)
  - [Prerequisite](#prerequisite)
  - [Available Options](#available-options)
  - [Example Configuration](#example-configuration)
    - [Vimscript Config](#vimscript-config)
    - [Lua Config](#lua-config)
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

### Available Options

- `compe.enabled (bool)`: Whether or not nvim-compe is enabled. default: `true`.
- `compe.debug (bool)`: Whether or not nvim-compe should display debug info. default: `false`
- `compe.min_length (number)`: Minimal characters length to trigger completion. default: `1`
- `compe.preselect ("enable" | "disable" | "always")`
   Controls nvim-compe preselect behaviour. default: `enable`
   - `enable`: Preselect completion item only if the source told nvim-compe to do so. Eg. completion from `gopls`
   - `disable`: Never preselect completion item regardless of source
   - `always`: Always preselect completion item regardless of source

- `compe.throttle_time (number)`: Throttle nvim-compe completion menu. default: `80`
- `compe.source_timeout (number)`: Timeout for nvim-compe to get completion items. default: `200`
- `compe.incomplete_delay (number)`: Delay for LSP's `isIncomplete`. default: `400`
- `compe.allow_prefix_unmatch`: TODO???

- `compe.source.path (bool)`: Path completion. default: `false`
- `compe.source.buffer (bool)`: Buffer completion. default: `false`
- `compe.source.vsnip (bool)`: Vsnip completion, make sure you have `vim-vsnip` installed. default: `false`
- `compe.source.nvim_lsp (bool)`: Nvim's builtin LSP completion. default: `false`
- `compe.source.nvim_lua (bool)`: Nvim's Lua "stdlib" completion. default: `false`
- `compe.source.your_awesome_source (table | dict)`: Override source configuration using a custom `table`(lua) or `dictionary`(vimscript).

### Example Configuration

Both Vimscript and Lua example are using the default value.

#### Vimscript Config
```viml
let g:compe = {}
let g:compe.enabled = v:true
let g:compe.debug = v:false
let g:compe.min_length = 1
let g:compe.preselect = 'enable'
let g:compe.throttle_time = 80
let g:compe.source_timeout = 200
let g:compe.incomplete_delay = 400
let g:compe.allow_prefix_unmatch = v:false

let g:compe.source = {}
let g:compe.source.path = v:true
let g:compe.source.buffer = v:true
let g:compe.source.vsnip = v:true
let g:compe.source.nvim_lsp = v:true
let g:compe.source.nvim_lua = v:true
let g:compe.source.your_awesome_source = {}
```

#### Lua
```lua
require'compe'.setup {
  enabled = true;
  debug = false;
  min_length = 1;
  preselect = 'enable';
  throttle_time = 80;
  source_timeout = 200;
  incomplete_delay = 400;
  allow_prefix_unmatch = false;

  source = {
    path = true;
    buffer = true;
    vsnip = true;
    nvim_lsp = true;
    nvim_lua = true;
    your_awesome_source = {};
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

If you use [Raimondi/delimitMate](https://github.com/Raimondi/delimitMate)
```viml
inoremap <silent><expr> <C-Space> compe#complete()
inoremap <silent><expr> <CR>      compe#confirm({ 'keys': "\<Plug>delimitMateCR", 'mode': '' })
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

#### common

- buffer
- path
- tags
- spell

#### neovim-specific

- nvim_lsp
- nvim_lua

#### external-plugin

- vim_lsp
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

