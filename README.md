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
- [FAQ](#faq)
- [Demo](#demo)
  - [Auto Import](#auto-import)
  - [LSP + Magic Completion](#lsp--rust_analyzers-magic-completion)
  - [Buffer Source Completion](#buffer-source-completion)
  - [Calc Completion](#calc-completion)
  - [Nvim Lua Completion](#nvim-lua-completion)
  - [Vsnip Completion](#vsnip-completion)
  - [Snippets.nvim Completion](#snippetsnvim-completion)
  - [Treesitter Completion](#treesitter-completion)
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

The `source` option is required if you want to enable but others can be omitted.

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
let g:compe.max_abbr_width = 100
let g:compe.max_kind_width = 100
let g:compe.max_menu_width = 100

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
let g:compe.source.treesitter = v:true
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
  max_abbr_width = 100;
  max_kind_width = 100;
  max_menu_width = 100;

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
    treesitter = true;
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
" NOTE: Order is important. You can't lazy loading lexima.vim.
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
- [vim_lsc](https://github.com/natebosch/vim-lsc)
- [vim-vsnip](https://github.com/hrsh7th/vim-vsnip)
- [ultisnips](https://github.com/SirVer/ultisnips)
- [snippets.nvim](https://github.com/norcalli/snippets.nvim)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)


## FAQ

#### How to use LSP snippet?

1. Set `snippetSupport=true` for LSP capabilities.

```lua
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

require'lspconfig'.rust_analyzer.setup {
  capabilities = capabilities,
}
```

2. Install `vim-vsnip`

`Plug 'hrsh7th/vim-vsnip'`

#### How to use tab to navigate completion menu?

`Tab` and `S-Tab` keys need to be mapped to `<C-n>` and `<C-p>` when completion menu is visible.
Following example will use `Tab` and `S-Tab` (shift+tab) to navigate completion menu and jump between [vim-vsnip](https://github.com/hrsh7th/vim-vsnip) placeholders when possible:

```lua
local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

-- Use (s-)tab to:
--- move to prev/next item in completion menuone
--- jump to prev/next snippet's placeholder
_G.tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-n>"
  elseif vim.fn.call("vsnip#available", {1}) == 1 then
    return t "<Plug>(vsnip-expand-or-jump)"
  else
    return t "<Tab>"
  end
end
_G.s_tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-p>"
  elseif vim.fn.call("vsnip#jumpable", {-1}) == 1 then
    return t "<Plug>(vsnip-jump-prev)"
  else
    return t "<S-Tab>"
  end
end

map("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
map("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
map("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
map("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
```

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

### Treesitter Completion

![treesitter.nvim](https://i.imgur.com/In7Kswu.gif)

### Tag Completion

![tag](https://i.imgur.com/KOAHcM2.gif)

### Spell Completion

![spell](https://i.imgur.com/r12rLBS.gif)

