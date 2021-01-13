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
    let l:option = lsp#get_server_info(l:server_name)
    let s:state.source_ids += [compe#register_source('vim_lsp', {
    \   'get_metadata': function('s:get_metadata', [
    \     get(l:option, 'allowlist', v:null),
    \     get(l:option, 'blocklist', v:null)
    \   ]),
    \   'datermine': function('s:datermine', [server_name]),
    \   'complete': function('s:complete', [server_name]),
    \ })]
  endfor
endfunction

"
" s:get_metadata
"
function! s:get_metadata(allowlist, blocklist) abort
  return {
  \   'priority': 1000,
  \   'menu': '[LSP]',
  \   'filetypes': a:allowlist,
  \ }
endfunction

"
" s:datermine
"
function! s:datermine(server_name, context) abort
  let l:capabilities = lsp#get_server_capabilities(a:server_name)

  let l:trigger_characters = []
  if type(l:capabilities.completionProvider) == type({}) && has_key(l:capabilities.completionProvider, 'triggerCharacters')
    let l:trigger_characters = l:capabilities.completionProvider.triggerCharacters
  endif
  return compe#helper#datermine(a:context, {
  \   'trigger_characters': l:trigger_characters
  \ })
endfunction

"
" complete
"
function! s:complete(server_name, args) abort
  let l:context = {
  \   'triggerKind': a:args.trigger_character_offset > 0 ? 2 : (a:args.incomplete ? 3 : 1),
  \ }

  if a:args.trigger_character_offset > 0
    let l:context.triggerCharacter = a:args.context.before_char
  endif

  let l:position = lsp#get_position()
  call lsp#callbag#pipe(
  \   lsp#request(a:server_name, {
  \     'method': 'textDocument/completion',
  \     'params': {
  \       'textDocument': lsp#get_text_document_identifier(),
  \       'position': l:position,
  \       'context': l:context,
  \     }
  \   }),
  \   lsp#callbag#subscribe({
  \     'next': { x -> s:on_response(a:server_name, a:args, l:position, x.response) },
  \   })
  \ )
endfunction

"
" on_response
"
function! s:on_response(server_name, args, complete_position, response) abort
  if !has_key(a:response, 'result')
    return a:args.abort()
  endif

  let l:result = lsp#omni#get_vim_completion_items({
  \   'server': lsp#get_server_info(a:server_name),
  \   'position': a:complete_position,
  \   'response': a:response,
  \ })
  call a:args.callback({
  \   'items': l:result.items,
  \   'incomplete': l:result.incomplete,
  \ })
endfunction

