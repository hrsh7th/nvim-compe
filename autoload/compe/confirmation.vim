let s:Position = vital#compe#import('VS.LSP.Position')
let s:TextEdit = vital#compe#import('VS.LSP.TextEdit')
let s:CompletionItem = vital#compe#import('VS.LSP.CompletionItem')

"
" compe#confirmation#lsp
"
function! compe#confirmation#lsp(args) abort
  let l:current_line = getline('.')
  let l:completed_item = a:args.completed_item
  let l:completion_item = a:args.completion_item
  let l:suggest_position = { 'line': line('.') - 1, 'character': strchars(strpart(l:current_line, 0, l:completed_item.suggest_offset - 1)) }
  let l:current_position = s:Position.cursor()
  let l:request_position = a:args.request_position
  let l:ExpandSnippet = compe#confirmation#get_expand_snippet()
  if empty(l:ExpandSnippet)
    let l:ExpandSnippet = function('s:simple_expand_snippet')
  endif
  call s:CompletionItem.confirm({
  \   'suggest_position': l:suggest_position,
  \   'request_position': s:min(l:request_position, l:current_position),
  \   'current_position': l:current_position,
  \   'current_line': getline('.'),
  \   'completion_item': l:completion_item,
  \   'expand_snippet': l:ExpandSnippet,
  \ })
endfunction

"
" compe#confirmation#get_expand_snippet
"
function! compe#confirmation#get_expand_snippet() abort
  if exists('g:loaded_vsnip')
    return { args -> vsnip#anonymous(args.body) }
  elseif luaeval('pcall(require, "snippets")')
    return { args -> luaeval('require"snippets".expand_at_cursor((require"snippets".u.match_indentation(_A)))', args.body) }
  elseif luaeval('pcall(require, "luasnip")')
  	return { args -> luaeval('require"luasnip".lsp_expand(_A)', args.body)}
  elseif exists('g:did_plugin_ultisnips')
  	return { args -> UltiSnips#Anon(args.body) }
  endif
  return v:null
endfunction

"
" simple_expand_snippet
"
function! s:simple_expand_snippet(args) abort
  let l:body = substitute(a:args.body, '\$\d\|\${[^}]*}\|\$\w\+', '', 'g')
  let l:current_position = s:Position.cursor()
  call s:TextEdit.apply('%', [{
  \   'range': {
  \     'start': l:current_position,
  \     'end': l:current_position,
  \   },
  \   'newText': l:body,
  \ }])
endfunction

"
" return minimum position
"
function! s:min(pos1, pos2) abort
  if a:pos1.line < a:pos2.line
    return a:pos1
  elseif a:pos1.line == a:pos2.line
    if a:pos1.character < a:pos2.character
      return a:pos1
    endif
  endif
  return a:pos2
endfunction
