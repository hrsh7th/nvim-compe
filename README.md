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
  - [Highlight](#highlight)
- [Built-in sources](#built-in-sources)
  - [Common](#common)
  - [Neovim-specific](#neovim-specific)
  - [External-plugin](#external-plugin)
- [External sources](#external-sources)
- [FAQ](#faq)
  - [Can't get sorting to work correctly](#cant-get-sorting-to-work-correctly)
  - [How to use LSP snippet?](#how-to-use-lsp-snippet)
  - [How to use tab to navigate completion menu?](#how-to-use-tab-to-navigate-completion-menu)
  - [How to expand snippets from completion menu?](#how-to-expand-snippets-from-completion-menu)
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

- Simple core
- No flicker
- Lua source & Vim source
- Better matching algorithm
- Support LSP completion features (trigger character, isIncomplete, expansion)
- Respect VSCode/LSP API design

## Features

- VSCode compatible expansion handling
  - rust-analyzer's
    [Magic completion](https://rust-analyzer.github.io/manual.html#magic-completions)
  - vscode-html-languageserver-bin's closing tag completion
  - Other complex expansion are supported
- Flexible Custom Source API
  - The source can support `documentation` / `resolve` / `confirm`
- Better fuzzy matching algorithm
  - `gu` can be matched `get_user`
  - `fmodify` can be matched `fnamemodify`
  - See [matcher.lua](./lua/compe/matcher.lua#L57) for implementation details
- Buffer source carefully crafted
  - The buffer source will index buffer words by filetype specific regular
    expression if needed

## Usage

Detailed docs in [here](./doc/compe.txt) or `:help compe`.

### Prerequisite

Neovim version 0.5.0 or above (not released yet, use nightlies or build from source).

You must set `completeopt` to `menuone,noselect` which can be easily done
as follows.

Using Vim script

```viml
set completeopt=menuone,noselect
```

Using Lua

```lua
vim.o.completeopt = "menuone,noselect"
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
let g:compe.resolve_timeout = 800
let g:compe.incomplete_delay = 400
let g:compe.max_abbr_width = 100
let g:compe.max_kind_width = 100
let g:compe.max_menu_width = 100
let g:compe.documentation = v:true

let g:compe.source = {}
let g:compe.source.path = v:true
let g:compe.source.buffer = v:true
let g:compe.source.calc = v:true
let g:compe.source.nvim_lsp = v:true
let g:compe.source.nvim_lua = v:true
let g:compe.source.vsnip = v:true
let g:compe.source.ultisnips = v:true
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
  resolve_timeout = 800;
  incomplete_delay = 400;
  max_abbr_width = 100;
  max_kind_width = 100;
  max_menu_width = 100;
  documentation = true;

  source = {
    path = true;
    buffer = true;
    calc = true;
    nvim_lsp = true;
    nvim_lua = true;
    vsnip = true;
    ultisnips = true;
  };
}
```

### Mappings

```viml
inoremap <silent><expr> <C-Space> compe#complete()
inoremap <silent><expr> <CR>      compe#confirm('<CR>')
inoremap <silent><expr> <C-e>     compe#close('<C-e>')
inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })
inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })
```

If you use [cohama/lexima.vim](https://github.com/cohama/lexima.vim)

```viml
" NOTE: Order is important. You can't lazy loading lexima.vim.
let g:lexima_no_default_rules = v:true
call lexima#set_default_rules()
inoremap <silent><expr> <C-Space> compe#complete()
inoremap <silent><expr> <CR>      compe#confirm(lexima#expand('<LT>CR>', 'i'))
inoremap <silent><expr> <C-e>     compe#close('<C-e>')
inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })
inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })
```

If you use [Raimondi/delimitMate](https://github.com/Raimondi/delimitMate)

```viml
inoremap <silent><expr> <C-Space> compe#complete()
inoremap <silent><expr> <CR>      compe#confirm({ 'keys': "\<Plug>delimitMateCR", 'mode': '' })
inoremap <silent><expr> <C-e>     compe#close('<C-e>')
inoremap <silent><expr> <C-f>     compe#scroll({ 'delta': +4 })
inoremap <silent><expr> <C-d>     compe#scroll({ 'delta': -4 })
```

### Highlight

You can change documentation window's highlight group via following.

```viml
highlight link CompeDocumentation NormalFloat
```


## Built-in sources

### Common

- buffer
- path
- tags
- spell
- calc
- omni (Warning: It has a lot of side-effect.)

### Neovim-specific

- nvim_lsp
- nvim_lua

### External-plugin

- [vim_lsp](https://github.com/prabirshrestha/vim-lsp)
- [vim_lsc](https://github.com/natebosch/vim-lsc)
- [vim-vsnip](https://github.com/hrsh7th/vim-vsnip)
- [ultisnips](https://github.com/SirVer/ultisnips)
- [snippets.nvim](https://github.com/norcalli/snippets.nvim)
- [luasnip](https://github.com/L3MON4D3/LuaSnip)
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) (Warning: it sometimes really slow.)

## External sources

- [tabnine](https://github.com/tzachar/compe-tabnine)
- [zsh](https://github.com/tamago324/compe-zsh)
- [conjure](https://github.com/tami5/compe-conjure)
- [dadbod](https://github.com/kristijanhusak/vim-dadbod-completion)
- [latex-symbols](https://github.com/GoldsteinE/compe-latex-symbols)
- [tmux](https://github.com/andersevenrud/compe-tmux)

## FAQ

### Can't get it work.

If you are enabling the `omni` source, please try to disable it.

### Incredibly lagging.

If you are enabling the `treesitter` source, please try to disable it.

### Does not work function signature window.

The signature help is out of scope of compe.
It should be another plugin e.g. [lsp_signature.nvim](https://github.com/ray-x/lsp_signature.nvim)

If you are enabling the `treesitter` source, please try to disable it.

### How to remove `Pattern not found`?

You can set `set shortmess+=c` in your vimrc.


### How to use LSP snippet?

1. Set `snippetSupport=true` for LSP capabilities.

   ```lua
   local capabilities = vim.lsp.protocol.make_client_capabilities()
   capabilities.textDocument.completion.completionItem.snippetSupport = true
   capabilities.textDocument.completion.completionItem.resolveSupport = {
     properties = {
       'documentation',
       'detail',
       'additionalTextEdits',
     }
   }

   require'lspconfig'.rust_analyzer.setup {
     capabilities = capabilities,
   }
   ```

2. Install `vim-vsnip`

   ```viml
   Plug 'hrsh7th/vim-vsnip'
   ```

   or `snippets.nvim`

   ```viml
   Plug 'norcalli/snippets.nvim'
   ```

   or `UltiSnips`

   ```viml
   Plug 'SirVer/ultisnips'
   ```

### How to use tab to navigate completion menu?

`Tab` and `S-Tab` keys need to be mapped to `<C-n>` and `<C-p>` when completion
menu is visible. Following example will use `Tab` and `S-Tab` (shift+tab) to
navigate completion menu and jump between
[vim-vsnip](https://github.com/hrsh7th/vim-vsnip) placeholders when possible:

```lua
local t = function(str)
  return vim.api.nvim_replace_termcodes(str, true, true, true)
end

local check_back_space = function()
    local col = vim.fn.col('.') - 1
    if col == 0 or vim.fn.getline('.'):sub(col, col):match('%s') then
        return true
    else
        return false
    end
end

-- Use (s-)tab to:
--- move to prev/next item in completion menuone
--- jump to prev/next snippet's placeholder
_G.tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-n>"
  elseif vim.fn.call("vsnip#available", {1}) == 1 then
    return t "<Plug>(vsnip-expand-or-jump)"
  elseif check_back_space() then
    return t "<Tab>"
  else
    return vim.fn['compe#complete']()
  end
end
_G.s_tab_complete = function()
  if vim.fn.pumvisible() == 1 then
    return t "<C-p>"
  elseif vim.fn.call("vsnip#jumpable", {-1}) == 1 then
    return t "<Plug>(vsnip-jump-prev)"
  else
    -- If <S-Tab> is not working in your terminal, change it to <C-h>
    return t "<S-Tab>"
  end
end

vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
```

### How to expand snippets from completion menu?

Use `compe#confirm()` mapping, as described in section [Mappings](#mappings).


### ESC does not close the completion menu

Another plugin might be interfering with it. [`vim-autoclose`](https://github.com/Townk/vim-autoclose)
does this. You can check the mapping of `<ESC>` by running

```
imap <ESC>
```

`vim-autoclose`'s function looks similar to this:

```
<Esc> *@pumvisible() ? '<C-E>' : '<C-R>=<SNR>110_FlushBuffer()<CR><Esc>'
```

In the particular case of `vim-autoclose`, the problem can be fixed by adding this setting:

```
let g:AutoClosePumvisible = {"ENTER": "<C-Y>", "ESC": "<ESC>"}
```

Other plugins might need other custom settings.

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
