let s:Position = vital#compe#import('VS.LSP.Position')
let s:TextEdit = vital#compe#import('VS.LSP.TextEdit')
let s:CompletionItem = vital#compe#import('VS.LSP.CompletionItem')

"
" compe#confirmation#lsp
"
function! compe#confirmation#lsp(args) abort
  let l:completed_item = a:args.completed_item
  let l:completion_item = a:args.completion_item
  let l:current_position = s:Position.cursor()
  let l:suggest_position = { 'line': line('.') - 1, 'character': l:current_position.character - strchars(l:completed_item.word) }
  let l:request_position = a:args.request_position
  call s:CompletionItem.confirm({
  \   'suggest_position': l:suggest_position,
  \   'request_position': l:request_position,
  \   'current_position': l:current_position,
  \   'current_line': getline('.'),
  \   'completion_item': l:completion_item,
  \   'expand_snippet': function('s:expand_snippet'),
  \ })
endfunction

"
" expand_snippet
"
function! s:expand_snippet(args) abort
  if exists('g:loaded_vsnip')
    call vsnip#anonymous(a:args.body)
  else
    call s:simple_expand_snippet(a:args.body)
  endif
endfunction

"
" simple_expand_snippet
"
function! s:simple_expand_snippet(body) abort
  let l:body = substitute(a:body, '\$\d\|\${[^}]*}\|\$\w\+', '', 'g')
  let l:current_position = s:Position.cursor()
  call s:TextEdit.apply('%', [{
  \   'range': {
  \     'start': l:current_position,
  \     'end': l:current_position,
  \   },
  \   'newText': l:body,
  \ }])
endfunction

