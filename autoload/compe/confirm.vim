let s:Position = vital#compe#import('VS.LSP.Position')
let s:CompletionItem = vital#compe#import('VS.LSP.CompletionItem')

function! compe#confirm#lsp(args) abort
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
  \   'expand_snippet': { args -> vsnip#anonymous(args.body) }
  \ })
endfunction

