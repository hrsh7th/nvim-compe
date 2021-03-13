let s:base_bridge_id = 0
let s:sources = {}

"
" compe#vim_bridge#register
"
function! compe#vim_bridge#register(name, source) abort
  let s:base_bridge_id += 1

  let l:bridge_id = a:name . '_' . s:base_bridge_id
  let s:sources[l:bridge_id] = a:source
  let s:sources[l:bridge_id].id = luaeval('require"compe"._register_vim_source(_A[1], _A[2], _A[3])', [
  \   a:name,
  \   l:bridge_id,
  \   filter(['get_metadata', 'determine', 'documentation', 'complete', 'confirm', 'resolve'], 'has_key(a:source, v:val)')
  \ ])
  return s:sources[l:bridge_id].id
endfunction

"
" compe#vim_bridge#unregister
"
function! compe#vim_bridge#unregister(id) abort
  for [l:bridge_id, l:source] in items(s:sources)
    if l:source.id == a:id
      unlet s:sources[l:bridge_id]
      break
    endif
  endfor
  call luaeval('require"compe".unregister_source(_A[1])', [a:id])
endfunction

"
" compe#vim_bridge#get_metadata
"
function! compe#vim_bridge#get_metadata(bridge_id) abort
  if has_key(s:sources, a:bridge_id) && has_key(s:sources[a:bridge_id], 'get_metadata')
    return s:sources[a:bridge_id].get_metadata()
  endif
  return {}
endfunction

"
" compe#vim_bridge#determine
"
function! compe#vim_bridge#determine(bridge_id, context) abort
  if has_key(s:sources, a:bridge_id) && has_key(s:sources[a:bridge_id], 'determine')
    return s:sources[a:bridge_id].determine(a:context)
  endif
  return {}
endfunction

"
" compe#vim_bridge#documentation
"
function! compe#vim_bridge#documentation(bridge_id, args) abort
  if has_key(s:sources, a:bridge_id) && has_key(s:sources[a:bridge_id], 'documentation')
    let a:args.callback = s:callback(a:args.callback)
    let a:args.abort = s:callback(a:args.abort)
    call s:sources[a:bridge_id].documentation(a:args)
  endif
endfunction

"
" compe#vim_bridge#complete
"
function! compe#vim_bridge#complete(bridge_id, args) abort
  if has_key(s:sources, a:bridge_id) && has_key(s:sources[a:bridge_id], 'complete')
    let a:args.callback = s:callback(a:args.callback)
    let a:args.abort = s:callback(a:args.abort)
    call s:sources[a:bridge_id].complete(a:args)
  endif
endfunction

"
" compe#vim_bridge#resolve
"
function! compe#vim_bridge#resolve(bridge_id, args) abort
  if has_key(s:sources, a:bridge_id) && has_key(s:sources[a:bridge_id], 'resolve')
    let a:args.callback = s:callback(a:args.callback)
    call s:sources[a:bridge_id].resolve(a:args)
  endif
endfunction

"
" compe#vim_bridge#confirm
"
function! compe#vim_bridge#confirm(bridge_id, args) abort
  if has_key(s:sources, a:bridge_id) && has_key(s:sources[a:bridge_id], 'confirm')
    call s:sources[a:bridge_id].confirm(a:args)
  endif
endfunction

"
" callback
"
function! s:callback(callback_id) abort
  return { ... -> luaeval('require"compe"._on_callback(_A[1], unpack(_A[2]))', [a:callback_id, a:000]) }
endfunction

