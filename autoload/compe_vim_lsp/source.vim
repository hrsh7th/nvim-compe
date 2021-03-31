let s:MarkupContent = vital#compe#import('VS.LSP.MarkupContent')

let s:state = {
\   'source_ids': [],
\ }

"
" compe_vim_lsp#source#attach
"
function! compe_vim_lsp#source#attach() abort
  augroup compe#source#lsp#attach
    autocmd!
    autocmd User lsp_server_init call s:source()
    autocmd User lsp_server_exit call s:source()
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

  let l:server_names = []
  for l:server_name in lsp#get_server_names()
    let l:capabilities = lsp#get_server_capabilities(l:server_name)
    if !has_key(l:capabilities, 'completionProvider')
      continue
    endif
    let s:state.source_ids += [compe#register_source('vim_lsp', {
    \   'get_metadata': function('s:get_metadata', [l:server_name]),
    \   'determine': function('s:determine', [l:server_name]),
    \   'complete': function('s:complete', [l:server_name]),
    \   'resolve': function('s:resolve', [l:server_name]),
    \   'documentation': function('s:documentation', [l:server_name]),
    \   'confirm': function('s:confirm', [l:server_name]),
    \ })]
  endfor
endfunction

"
" s:get_metadata
"
function! s:get_metadata(server_name) abort
  let l:option = lsp#get_server_info(a:server_name)
  return {
  \   'priority': 1000,
  \   'menu': '[LSP]',
  \   'dup': 1,
  \   'filetypes': get(l:option, 'allowlist', v:null),
  \   'ignored_filetypes': get(l:option, 'blocklist', v:null),
  \ }
endfunction

"
" s:determine
"
function! s:determine(server_name, context) abort
  let l:capabilities = lsp#get_server_capabilities(a:server_name)
  return compe#helper#determine(a:context, {
  \   'trigger_characters': s:get(l:capabilities, ['completionProvider', 'triggerCharacters'], [])
  \ })
endfunction

"
" complete
"
function! s:complete(server_name, args) abort
  let l:request = {}
  let l:request.textDocument = lsp#get_text_document_identifier()
  let l:request.position = lsp#get_position()
  let l:request.context = {}
  let l:request.context.triggerKind = a:args.trigger_character_offset > 0 ? 2 : (a:args.incomplete ? 3 : 1)
  if a:args.trigger_character_offset > 0
    let l:request.context.triggerCharacter = a:args.context.before_char
  endif

  call lsp#callbag#pipe(
  \   lsp#request(a:server_name, {
  \     'method': 'textDocument/completion',
  \     'params': l:request,
  \   }),
  \   lsp#callbag#subscribe({
  \     'next': { x -> s:on_complete(a:args, l:request, x.response) },
  \   })
  \ )
endfunction
function! s:on_complete(args, request, response) abort
  if !has_key(a:response, 'result')
    return a:args.abort()
  endif
  if a:response.result is# v:null
    return a:args.abort()
  endif
  call a:args.callback(compe#helper#convert_lsp({
  \   'keyword_pattern_offset': a:args.keyword_pattern_offset,
  \   'context': a:args.context,
  \   'request': a:request,
  \   'response': a:response.result,
  \ }))
endfunction

"
" resolve
"
function! s:resolve(server_name, args) abort
  let l:capabilities = lsp#get_server_capabilities(a:server_name)
  if s:get(l:capabilities, ['completionProvider', 'resolveProvider'], v:false)
    let l:completion_item = a:args.completed_item.user_data.compe.completion_item
    call lsp#callbag#pipe(
    \   lsp#request(a:server_name, {
    \     'method': 'completionItem/resolve',
    \     'params': a:args.completed_item.user_data.compe.completion_item,
    \   }),
    \   lsp#callbag#subscribe({
    \     'next': { x -> s:on_resolve(a:args, x.response) },
    \   })
    \ )
  else
    call a:args.callback(a:args.completed_item)
  endif
endfunction
function! s:on_resolve(args, response) abort
  if has_key(a:response, 'result')
    let a:args.completed_item.user_data.compe.completion_item = a:response.result
  endif
  call a:args.callback(a:args.completed_item)
endfunction

"
" documentation
"
function! s:documentation(server_name, args) abort
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

"
" get
"
function! s:get(dict, keys, ...) abort
  let l:default = get(a:000, 0, v:null)
  let l:V = a:dict
  for l:key in a:keys
    let l:type = type(l:V)
    if !(l:type == v:t_dict && has_key(l:V, l:key))
      return l:default
    endif
    let l:V = l:V[l:key]
  endfor
  return l:V
endfunction
