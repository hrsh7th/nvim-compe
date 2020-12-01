"
" Public API
"

"
" compe#setup
"
function! compe#setup(config) abort
  call luaeval('require"compe".setup(_A[1])', [a:config])
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
inoremap <silent> <Plug>(compe-complete) <C-r>=luaeval('require"compe"._complete()')<CR>
function! compe#complete() abort
  call feedkeys("\<Plug>(compe-complete)")
  return ''
endfunction

"
" compe#confirm
"
function! compe#confirm(...) abort
  if complete_info(['selected']).selected != -1
    return "\<C-y>"
  endif
  return get(a:000, 0, '')
endfunction

"
" compe#close
"
function! compe#close(...) abort
  if pumvisible()
    return "\<C-e>"
  endif
  return get(a:000, 0, '')
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

