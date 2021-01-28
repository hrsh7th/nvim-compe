let s:base_bridge_id = 0
let s:sources = {}

"
" compe#source#vim_bridge#register
"
function! compe#source#vim_bridge#register(name, source) abort
  let s:base_bridge_id += 1

  let l:bridge_id = a:name . '_' . s:base_bridge_id
  let s:sources[l:bridge_id] = a:source
  let s:sources[l:bridge_id].id = luaeval('require"compe"._register_vim_source(_A[1], _A[2])', [a:name, l:bridge_id])
  return s:sources[l:bridge_id].id
endfunction

"
" compe#source#vim_bridge#unregister
"
function! compe#source#vim_bridge#unregister(id) abort
  for [l:bridge_id, l:source] in items(s:sources)
    if l:source.id == a:id
      unlet s:sources[l:bridge_id]
      break
    endif
  endfor
  call luaeval('require"compe".unregister_source(_A[1])', [a:id])
endfunction

"
" compe#source#vim_bridge#get_metadata
"
function! compe#source#vim_bridge#get_metadata(bridge_id) abort
  if has_key(s:sources, a:bridge_id) && has_key(s:sources[a:bridge_id], 'get_metadata')
    return s:sources[a:bridge_id].get_metadata()
  endif
  return {}
endfunction

"
" compe#source#vim_bridge#determine
"
function! compe#source#vim_bridge#determine(bridge_id, context) abort
  if has_key(s:sources, a:bridge_id) && has_key(s:sources[a:bridge_id], 'determine')
    return s:sources[a:bridge_id].determine(a:context)
  endif
  return {}
endfunction

"
" compe#source#vim_bridge#documentation
"
function! compe#source#vim_bridge#documentation(bridge_id, args) abort
  if has_key(s:sources, a:bridge_id) && has_key(s:sources[a:bridge_id], 'documentation')
    let a:args.callback = { document ->
    \   luaeval('require"compe.vim_bridge".documentation_on_callback(_A[1], _A[2])', [a:bridge_id, document])
    \ }
    let a:args.abort = { ->
    \   luaeval('require"compe.vim_bridge".documentation_on_abort(_A[1])', [a:bridge_id])
    \ }
    call s:sources[a:bridge_id].documentation(a:args)
  endif
endfunction

"
" compe#source#vim_bridge#complete
"
function! compe#source#vim_bridge#complete(bridge_id, args) abort
  if has_key(s:sources, a:bridge_id) && has_key(s:sources[a:bridge_id], 'complete')
    let a:args.callback = { result ->
    \   luaeval('require"compe.vim_bridge".complete_on_callback(_A[1], _A[2])', [a:bridge_id, result])
    \ }
    let a:args.abort = { ->
    \   luaeval('require"compe.vim_bridge".complete_on_abort(_A[1])', [a:bridge_id])
    \ }
    call s:sources[a:bridge_id].complete(a:args)
  endif
endfunction

