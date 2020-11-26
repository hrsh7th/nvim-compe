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
  let l:keyword_pattern_offset = compe#pattern#get_keyword_pattern_offset(a:context)
  if l:keyword_pattern_offset > 0
    return {
    \   'keyword_pattern_offset': l:keyword_pattern_offset
    \ }
  endif
  return {}
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
