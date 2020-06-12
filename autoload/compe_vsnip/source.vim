"
" compe_vsnip#source#register
"
function! compe_vsnip#source#register() abort
  call compe#source#vim_bridge#register('vsnip', {
  \   'get_metadata': function('s:get_metadata'),
  \   'get_item_metadata': function('s:get_item_metadata'),
  \   'datermine': function('s:datermine'),
  \   'complete': function('s:complete'),
  \ })
endfunction

"
" s:get_metadata
"
function! s:get_metadata() abort
  return {
  \   'priority': 50
  \ }
endfunction

"
" s:get_item_metadata
"
function! s:get_item_metadata(item) abort
  return {
  \   'menu': '[v]',
  \ }
endfunction

"
" s:datermine
"
function! s:datermine(context) abort
  let [l:_, l:keyword_pattern_offset, l:__] = matchstrpos(a:context.before_line, '\h\w*$')
  if l:keyword_pattern_offset != -1
    return {
    \   'keyword_pattern_offset': l:keyword_pattern_offset + 1
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

