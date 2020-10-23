"
" compe#pattern#defaults
"
function! compe#pattern#set_defaults() abort
  call compe#pattern#set('vim', {
  \   'keyword_pattern': '\h\(\w\|\#\)*',
  \ })
  call compe#pattern#set('php', {
  \   'keyword_pattern': '\%(\$\w*\|\h\w*\)',
  \ })
endfunction

"
" compe#pattern#set
"
function! compe#pattern#set(filetype, config) abort
  call luaeval("require'compe.pattern':set(_A[1], _A[2])", [a:filetype, a:config])
endfunction

"
" compe#pattern#get_keyword_pattern_offset
"
function! compe#pattern#get_keyword_pattern_offset(context) abort
  return luaeval("require'compe.pattern':get_keyword_pattern_offset(_A[1])", [a:context])
endfunction

