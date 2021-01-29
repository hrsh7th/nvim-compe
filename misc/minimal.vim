if has('vim_starting')
  set encoding=utf-8
endif
scriptencoding utf-8

if &compatible
  set nocompatible
endif

let s:plug_dir = expand('/tmp/plugged/vim-plug')
if !isdirectory(s:plug_dir)
  execute printf('!curl -fLo %s/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim', s:plug_dir)
  let s:installed = v:true
end

execute 'set runtimepath+=' . s:plug_dir
call plug#begin(s:plug_dir)
Plug 'hrsh7th/nvim-compe'
" Plug 'neovim/nvim-lspconfig'
call plug#end()


if exists('s:installed')
  PlugInstall
endif

" Options or settings here.


