
"
" compe#complete
"
function! compe#complete() abort
  call luaeval('require"compe":on_manual_complete()')
  return ''
endfunction

"
" compe#confirm
"
function! compe#confirm(...) abort
  if complete_info(['selected']).selected != -1
    call luaeval('require"compe":clear()')
    return "\<C-y>"
  endif
  return get(a:000, 0, '')
endfunction

"
" compe#close
"
function! compe#close(...) abort
  if pumvisible()
    call luaeval('require"compe":clear()')
  endif
  return get(a:000, 0, '')
endfunction

