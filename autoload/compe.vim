let s:Window = vital#compe#import('VS.Vim.Window')

"
" Public API
"

"
" compe#setup
"
function! compe#setup(config, ...) abort
  call luaeval('require"compe".setup(_A[1], _A[2])', [a:config, get(a:, 1, v:null)])
endfunction

"
" compe#register_source
"
function! compe#register_source(name, source) abort
  if matchstr(a:name, '^\w\+$') ==# ''
    throw "compe: the source's name must be \w\+"
  endif
  return compe#vim_bridge#register(a:name, a:source)
endfunction

"
" compe#register_source
"
function! compe#unregister_source(id) abort
  call compe#vim_bridge#unregister(a:id)
endfunction

"
" compe#complete
"
function! compe#complete(...) abort
  if mode()[0] ==# 'i'
    call timer_start(0, { -> luaeval('require"compe"._complete(_A)', { 'manual': v:true }) })
  endif
  return "\<Ignore>"
endfunction

"
" confirm
"
inoremap <silent> <Plug>(compe-confirm) <C-r>=luaeval('require"compe"._confirm()')<CR>
function! compe#confirm(...) abort
  let l:completeopts = split(&completeopt, ',')
  for l:opt in ['menuone', 'noselect']
    if index(l:completeopts, l:opt) == -1
      echohl ErrorMsg
      echomsg '[nvim-compe] You must set `set completeopt=menuone,noselect` in your vimrc.'
      echohl None
    endif
  endfor

  let l:option = s:normalize(get(a:000, 0, {}))
  let l:index = complete_info(['selected']).selected
  let l:select = get(l:option, 'select', v:false)
  let l:selected = l:index != -1
  if mode()[0] ==# 'i' && pumvisible() && (l:select || l:selected)
    let l:info = luaeval('require"compe"._confirm_pre(_A)', (l:selected ? l:index + 1 : 1))
    if !empty(l:info)
      call feedkeys(repeat("\<BS>", strchars(getline('.')[l:info.offset - 1 : col('.') - 2], 1)), 'n')
      call feedkeys(l:info.item.word, 'n')
      call feedkeys("\<Plug>(compe-confirm)", '')
    else
      return "\<C-y>" " fallback for other plugin's completion menu
    endif
    return "\<Ignore>"
  endif
  return s:fallback(l:option)
endfunction

"
" compe#close
"
function! compe#close(...) abort
  if mode()[0] ==# 'i' && pumvisible()
    return "\<C-e>\<C-r>=luaeval('require\"compe\"._close()')\<CR>"
  endif
  return s:fallback(s:normalize(get(a:000, 0, {})))
endfunction

"
" compe#scroll
"
function! compe#scroll(option) abort
  let l:delta = get(a:option, 'delta', 4)
  let l:foo = luaeval('require("compe.float").scroll(_A)', l:delta)
  return "\<Ignore>"
endfunction

"
" Private API
"

"
" compe#_is_selected_manually
"
function! compe#_is_selected_manually() abort
  return pumvisible() && !empty(v:completed_item) ? v:true : v:false
endfunction

"
" compe#_has_completed_item
"
function! compe#_has_completed_item() abort
  return !empty(v:completed_item) ? v:true : v:false
endfunction

"
" normalize
"
function! s:normalize(option) abort
  if type(a:option) == v:t_string
    return { 'keys': a:option, 'mode': 'n' }
  endif
  return a:option
endfunction

"
" fallback
"
function! s:fallback(option) abort
  if has_key(a:option, 'keys') && get(a:option, 'mode', 'n') !=# 'n'
    call feedkeys(a:option.keys, a:option.mode)
    return "\<Ignore>"
  endif
  return get(a:option, 'keys', "\<Ignore>")
endfunction

