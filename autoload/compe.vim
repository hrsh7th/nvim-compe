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
  return compe#source#vim_bridge#register(a:name, a:source)
endfunction

"
" compe#register_source
"
function! compe#unregister_source(id) abort
  call compe#source#vim_bridge#unregister(a:id)
endfunction

"
" compe#complete
"
function! compe#complete() abort
  if mode()[0] ==# 'i'
    return "\<C-r>=luaeval('require\"compe\"._complete()')\<CR>"
  endif
  return "\<Ignore>"
endfunction

"
" compe#confirm
"
let s:confirming = v:false
inoremap <silent><expr><Plug>(compe-confirm-before) <SID>confirm_state(v:true)
inoremap <silent><expr><Plug>(compe-confirm-after) <SID>confirm_state(v:false)
function! s:confirm_state(state) abort
  let s:confirming = a:state
  return "\<Ignore>"
endfunction
function! compe#confirm(...) abort
  let l:completeopts = split(&completeopt, ',')
  for l:opt in ['menu', 'menuone', 'noselect']
    if index(l:completeopts, l:opt) == -1
      echohl ErrorMsg
      echomsg '[nvim-compe] You must set `set completeopt=menu,menuone,noselect` in your vimrc.'
      echohl None
    endif
  endfor

  let l:fallback = get(a:000, 0, v:null)
  if mode()[0] ==# 'i' && complete_info(['selected']).selected != -1
    call feedkeys("\<Plug>(compe-confirm-before)", '')
    call feedkeys("\<C-y>", 'n')
    call feedkeys("\<Plug>(compe-confirm-after)", '')
  else
    call s:fallback(get(a:000, 0, v:null))
  endif
  return "\<Ignore>"
endfunction

"
" compe#reduce
"
function! compe#reduce(...) abort
  if empty(v:completed_item) && pumvisible()
    call luaeval('require"compe"._reduce()')
  else
    call s:fallback(get(a:000, 0, v:null))
  endif
  return "\<Ignore>"
endfunction

"
" compe#close
"
function! compe#close(...) abort
  if mode()[0] ==# 'i' && pumvisible()
    return "\<C-e>\<C-r>=luaeval('require\"compe\"._close()')\<CR>"
  else
    call s:fallback(get(a:000, 0, v:null))
  endif
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
" compe#_is_confirming
"
function! compe#_is_confirming() abort
  return s:confirming
endfunction

"
" fallback
"
function! s:fallback(fallback) abort
  if type(a:fallback) == v:t_string
    call feedkeys(a:fallback, 'n')
  elseif type(a:fallback) == v:t_dict
    call feedkeys(get(a:fallback, 'keys', ''), get(a:fallback, 'mode', ''))
  endif
endfunction
