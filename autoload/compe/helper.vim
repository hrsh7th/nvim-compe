"
" compe#helper#datermine
"
function! compe#helper#datermine(context, ...) abort
  return luaeval('require"compe".helper.datermine(_A[1], _A[2])', [a:context, get(a:000, 0, v:false)])
endfunction

"
" compe#helper#get_keyword_pattern
"
function! compe#helper#get_keyword_pattern(filetype) abort
  return luaeval('require"compe".helper.get_keyword_pattern(_A[1])', [a:filetype])
endfunction

"
" compe#helper#get_default_pattern
"
function! compe#helper#get_default_pattern() abort
  return luaeval('require"compe".helper.get_default_pattern()')
endfunction

