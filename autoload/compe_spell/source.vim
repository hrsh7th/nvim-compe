"
" compe_spell#source#create
"
function! compe_spell#source#create() abort
  return {
  \   'get_metadata': function('s:get_metadata'),
  \   'determine': function('s:determine'),
  \   'complete': function('s:complete')
  \ }
endfunction

"
" s:get_metadata
"
function! s:get_metadata() abort
  return {
  \   'priority': 90,
  \   'menu': '[Spell]'
  \ }
endfunction

"
" s:determine
"
function! s:determine(context) abort
  return compe#helper#determine(a:context)
endfunction

"
" s:complete
"
function! s:complete(context) abort
  call a:context.callback({
  \   'items': spellsuggest(a:context.input),
  \   'incomplete': v:true
  \ })
endfunction

