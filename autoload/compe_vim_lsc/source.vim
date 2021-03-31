let s:MarkupContent = vital#compe#import('VS.LSP.MarkupContent')

let s:source_ids = []

"
" compe_vim_lsc#source#attach
"
function! compe_vim_lsc#source#attach() abort
  augroup compe_vim_lsc
    autocmd!
    autocmd InsertEnter * call s:source()
  augroup END
endfunction

"
" source
"
function! s:source() abort
  for l:source_id in s:source_ids
    call compe#unregister_source(l:source_id)
  endfor
  let s:source_ids = []

  for l:server in lsc#server#current()
    call add(s:source_ids, compe#register_source('vim_lsc', s:create(l:server)))
  endfor
endfunction

"
" create
"
function! s:create(server) abort
  return {
  \   'get_metadata': function('s:get_metadata', [a:server]),
  \   'determine': function('s:determine', [a:server]),
  \   'complete': function('s:complete', [a:server]),
  \   'resolve': function('s:resolve', [a:server]),
  \   'documentation': function('s:documentation', [a:server]),
  \   'confirm': function('s:confirm', [a:server]),
  \ }
endfunction
"
" get_metadata
"
function! s:get_metadata(server) abort
  return {
  \   'priority': 1000,
  \   'menu': '[LSP]',
  \   'dup': 1,
  \ }
endfunction

"
" determine
"
function! s:determine(server, context) abort
  return compe#helper#determine(a:context, {
  \   'trigger_characters': get(get(a:server.capabilities, 'completion', {}), 'triggerCharacters', []),
  \ })
endfunction

"
" complete
"
function! s:complete(server, args) abort
  let l:request = lsc#params#documentPosition()
  let l:request.context = {}
  let l:request.context.triggerKind = a:args.trigger_character_offset > 0 ? 2 : (a:args.incomplete ? 3 : 1)
  if a:args.trigger_character_offset > 0
    let l:request.context.triggerCharacter = a:args.context.before_char
  endif

  call lsc#file#flushChanges()
  call a:server.request('textDocument/completion', l:request, function('s:on_complete', [a:args, l:request]))
endfunction
function! s:on_complete(args, request, response) abort
  if a:response is# v:null
    return a:args.abort()
  endif
  call a:args.callback(compe#helper#convert_lsp({
  \   'keyword_pattern_offset': a:args.keyword_pattern_offset,
  \   'context': a:args.context,
  \   'request': a:request,
  \   'response': a:response,
  \ }))
endfunction

"
" resolve
"
function! s:resolve(server, args) abort
  if get(get(a:server.capabilities, 'completion', {}), 'resolveProvider', v:false)
    let l:completion_item = a:args.completed_item.user_data.compe.completion_item
    call a:server.request('completionItem/resolve', l:completion_item, function('s:on_resolve', [a:args]))
  else
    call a:args.callback(a:args.completed_item)
  endif
endfunction
function! s:on_resolve(args, response) abort
  call a:args.callback(a:response)
endfunction

"
" documentation
"
function! s:documentation(server, args) abort
  let l:completion_item = a:args.completed_item.user_data.compe.completion_item
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
endfunction

"
" confirm
"
function! s:confirm(server, args) abort
  call compe#confirmation#lsp({
  \   'completed_item': a:args.completed_item,
  \   'completion_item': a:args.completed_item.user_data.compe.completion_item,
  \   'request_position': a:args.completed_item.user_data.compe.request_position,
  \ })
endfunction

