"
" compe_vsnip#source#register
"
function! compe_vsnip#source#register() abort
  call compe#source#vim_bridge#register('vsnip', {
  \   'get_metadata': function('s:get_metadata'),
  \   'datermine': function('s:datermine'),
  \   'complete': function('s:complete'),
  \ })
endfunction

"
" s:get_metadata
"
function! s:get_metadata() abort
  return {
  \   'priority': 50,
  \   'menu': '[VSNIP]',
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
function! s:complete(args) abort
  call a:args.callback({
  \   'items': vsnip#get_complete_items(bufnr('%'))
  \ })
endfunction

