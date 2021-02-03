# nvim-compe

Auto completion plugin for nvim.

## Table Of Contents
- [Concept](#concept)
- [Features](#features)
- [Usage](#usage)
  - [Prerequisite](#prerequisite)
  - [Vim script Config](#vim-script-config)
  - [Lua Config](#lua-config)
  - [Mappings](#mappings)
- [Built-in Sources](#built-in-sources)
    - [Common](#common)
    - [Neovim-specific](#neovim-specific)
    - [External-plugin](#external-plugin)
- [Demo](#demo)
  - [Auto Import](#auto-import)
  - [LSP + Magic Completion](#lsp--rust_analyzers-magic-completion)
  - [Buffer Source Completion](#buffer-source-completion)
  - [Calc Completion](#calc-completion)
  - [Nvim Lua Completion](#nvim-lua-completion)
  - [Vsnip Completion](#vsnip-completion)
  - [Snippets.nvim Completion](#snippetsnvim-completion)
  - [Tag Completion](#tag-completion)
  - [Spell Completion](#spell-completion)


## Concept

- Lua source & Vim source
- Better matching algorithm
- Support LSP completion features (trigger character, isIncomplete)
- Effort to avoid flicker
- Respect VSCode/LSP API design


## Features

- VSCode compatible expansion handling
  - rust-analyzer's [Magic completion](https://rust-analyzer.github.io/manual.html#magic-completions)
  - vscode-html-languageserver-bin's closing tag completion
  - Other complex expansion are supported
- Flexible Custom Source API
  - The source can support `documentation` / `resolve` / `confirm`
- Better fuzzy matching algorithm
  - `gu` can be matched `get_user`
  - `fmodify` can be matched `fnamemodify`
  - See [matcher.lua](./lua/compe/matcher.lua#L57) for implementation details if you're interested
- Buffer source carefully crafted
  - The buffer source will index buffer words by filetype specific regular expression if needed

## Usage

Detailed docs in [here](./doc/compe.txt)

### Prerequisite

You must set `completeopt` to `menu,menuone,noselect` which can be easily done as follows.

Using Vim script

```viml
set completeopt=menu,menuone,noselect
```

Using Lua

```lua
vim.o.completeopt = "menu,menuone,noselect"
```

The `enabled` and `source` options are required if you want to enable but others can be omitted.

#### Vim script Config
```viml
let g:compe = {}
let g:compe.enabled = v:true
let g:compe.autocomplete = v:true
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
let g:compe.source.calc = v:true
let g:compe.source.vsnip = v:true
let g:compe.source.nvim_lsp = v:true
let g:compe.source.nvim_lua = v:true
let g:compe.source.spell = v:true
let g:compe.source.tags = v:true
let g:compe.source.snippets_nvim = v:true
```

#### Lua Config
```lua
require'compe'.setup {
  enabled = true;
  autocomplete = true;
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
    calc = true;
    vsnip = true;
    nvim_lsp = true;
    nvim_lua = true;
    spell = true;
    tags = true;
    snippets_nvim = true;
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
" NOTE: Order is important.
let g:lexima_no_default_rules = v:true
call lexima#set_default_rules()
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

## Built-in sources

#### Common

- buffer
- path
- tags
- spell
- calc

#### Neovim-specific

- nvim_lsp
- nvim_lua

#### External-plugin

- [vim_lsp](https://github.com/prabirshrestha/vim-lsp)
- [vim-vsnip](https://github.com/hrsh7th/vim-vsnip)
- [ultisnips](https://github.com/SirVer/ultisnips)
- [snippets.nvim](https://github.com/norcalli/snippets.nvim)

## Demo

### Auto Import

![auto import](https://i.imgur.com/GJSKxWK.gif)

### LSP + [rust_analyzer's Magic Completion](https://rust-analyzer.github.io/manual.html#magic-completions)

![lsp](https://i.imgur.com/pMxHkYG.gif)

### Buffer Source Completion

![buffer](https://i.imgur.com/qCfeb5d.gif)

### Calc Completion

![calc](https://i.imgur.com/gfoP9ff.gif)

### Nvim Lua Completion

![nvim lua](https://i.imgur.com/zGfVz2M.gif)

### Vsnip Completion

![vsnip](https://i.imgur.com/y2wNDtC.gif)

### Snippets.nvim Completion

![snippets.nvim](https://i.imgur.com/404KJ7C.gif)

### Tag Completion

![tag](https://i.imgur.com/KOAHcM2.gif)

### Spell Completion

![spell](https://i.imgur.com/r12rLBS.gif)

