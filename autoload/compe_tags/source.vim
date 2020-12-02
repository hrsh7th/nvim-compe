"
" compe_tags#source#create
"
function! compe_tags#source#create() abort
  return {
  \   'get_metadata': function('s:get_metadata'),
  \   'datermine': function('s:datermine'),
  \   'complete': function('s:complete')
  \ }
endfunction

"
" s:get_metadata
"
function! s:get_metadata() abort
  return {
  \   'priority': 90,
  \   'menu': '[TAG]'
  \ }
endfunction

"
" s:datermine
"
function! s:datermine(context) abort
  return compe#helper#datermine(a:context)
endfunction

"
" s:complete
"
function! s:complete(context) abort
  call a:context.callback({
  \   'items': getcompletion(a:context.input, 'tag'),
  \   'incomplete': v:true
  \ })
endfunction
