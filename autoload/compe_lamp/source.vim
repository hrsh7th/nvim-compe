let s:Position = vital#lamp#import('VS.LSP.Position')
let s:MarkupContent = vital#lamp#import('VS.LSP.MarkupContent')

let s:state = {
\   'source_ids': [],
\   'cancellation_token': lamp#cancellation_token(),
\ }

"
" compe_lamp#source#attach
"
function! compe_lamp#source#attach() abort
  augroup compe_lamp#source#attach
    autocmd!
    autocmd User lamp#server#initialized call s:source()
    autocmd User lamp#server#exited call s:source()
  augroup END
  call s:source()
endfunction

"
" source
"
function! s:source() abort
  for l:source_id in s:state.source_ids
    call compe#unregister_source(l:source_id)
  endfor
  let s:state.source_ids = []

  let l:servers = lamp#server#registry#all()
  let l:servers = filter(l:servers, { _, server -> server.supports('capabilities.completionProvider') })
  let s:state.source_ids = map(copy(l:servers), { _, server ->
  \   compe#register_source('lamp', {
  \     'get_metadata': function('s:get_metadata', [server]),
  \     'determine': function('s:determine', [server]),
  \     'resolve': function('s:resolve', [server]),
  \     'documentation': function('s:documentation', [server]),
  \     'confirm': function('s:confirm', [server]),
  \     'complete': function('s:complete', [server]),
  \   })
  \ })
endfunction

"
" s:get_metadata
"
function! s:get_metadata(server) abort
  return {
  \   'priority': 1000,
  \   'menu': '[LSP]',
  \   'filetypes': a:server.filetypes
  \ }
endfunction

"
" s:determine
"
function! s:determine(server, context) abort
  if index(a:server.filetypes, a:context.filetype) == -1
    return {}
  endif

  return compe#helper#determine(a:context, {
  \   'trigger_characters': a:server.capabilities.get_completion_trigger_characters()
  \ })
endfunction

"
" resolve
"
function! s:resolve(server, args) abort
  let l:completed_item = a:args.completed_item
  if has_key(l:completed_item, 'user_data') &&
  \ has_key(l:completed_item.user_data, 'lamp') &&
  \ has_key(l:completed_item.user_data.lamp, 'completion_item')
    let l:ctx = {}
    function! l:ctx.callback(args, completion_item) abort
      let a:args.completed_item.user_data.lamp.completion_item = a:completion_item
      call a:args.callback(a:args.completed_item)
    endfunction
    call a:server.request(
    \   'completionItem/resolve',
    \   l:completed_item.user_data.lamp.completion_item
    \ ).then({ completion_item -> l:ctx.callback(a:args, completion_item) })
  else
    call a:args.callback(l:completed_item)
  endif
endfunction

"
" documentation
"
function! s:documentation(server, args) abort
  let l:completed_item = a:args.completed_item
  if has_key(l:completed_item, 'user_data') &&
  \ has_key(l:completed_item.user_data, 'lamp') &&
  \ has_key(l:completed_item.user_data.lamp, 'completion_item')
    let l:completion_item = l:completed_item.user_data.lamp.completion_item
    let l:document = []
    if has_key(l:completion_item, 'detail')
      let l:document += [printf('```%s', a:args.context.filetype)]
      let l:document += [l:completion_item.detail]
      let l:document += ['```']
    endif
    if has_key(l:completion_item, 'documentation')
      let l:document += [s:MarkupContent.normalize(l:completion_item.documentation)]
    endif
    call a:args.callback(l:document)
  else
    call a:args.abort()
  endif
endfunction

"
" confirm
"
function! s:confirm(server, args) abort
  call compe#confirmation#lsp({
  \   'completed_item': a:args.completed_item,
  \   'completion_item': a:args.completed_item.user_data.lamp.completion_item,
  \   'request_position': a:args.completed_item.user_data.lamp.complete_position,
  \ })
endfunction

"
" complete
"
function! s:complete(server, args) abort
  if index(a:server.filetypes, a:args.context.filetype) == -1
    return a:args.abort()
  endif

  call s:state.cancellation_token.cancel()
  let s:state.cancellation_token = lamp#cancellation_token()

  let l:context = {
  \   'triggerKind': a:args.trigger_character_offset > 0 ? 2 : (a:args.incomplete ? 3 : 1),
  \ }

  if a:args.trigger_character_offset > 0
    let l:context.triggerCharacter = a:args.context.before_char
  endif

  let l:complete_position = s:Position.cursor()
  let l:promise = a:server.request('textDocument/completion', {
  \   'textDocument': lamp#protocol#document#identifier(bufnr('%')),
  \   'position': l:complete_position,
  \   'context': l:context,
  \ }, {
  \   'cancellation_token': s:state.cancellation_token,
  \ })
  let l:promise = l:promise.catch({ -> a:args.abort() })
  let l:promise = l:promise.then({ response ->
  \   s:on_response(
  \     a:server,
  \     a:args,
  \     l:complete_position,
  \     response
  \   )
  \ })
endfunction

"
" on_response
"
function! s:on_response(server, args, complete_position, response) abort
  if index([type([]), type({})], type(a:response)) == -1
    return a:args.abort()
  endif

  call a:args.callback({
  \   'items': lamp#feature#completion#convert(
  \     a:server.name,
  \     a:complete_position,
  \     a:response,
  \   ),
  \   'incomplete': type(a:response) == type({}) ? get(a:response, 'isIncomplete', v:false) : v:false,
  \ })
endfunction


