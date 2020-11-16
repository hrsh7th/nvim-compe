"
" compe_vsnip#source#create
"
function! compe_vsnip#source#create() abort
  return {
  \   'get_metadata': function('s:get_metadata'),
  \   'datermine': function('s:datermine'),
  \   'complete': function('s:complete'),
  \ }
endfunction

"
" documentation
"
function! s:documentation(args) abort
  let l:completed_item = a:args.completed_item
  if empty(get(l:completed_item, 'user_data', ''))
    return
  endif
  if type(l:completed_item.user_data) == type('')
    let l:user_data = json_decode(l:completed_item.user_data)
  else
    let l:user_data = l:completed_item.user_data
  endif
  if !has_key(l:user_data, 'vsnip')
    return
  endif

  call a:args.callback(l:user_data.vsnip.snippet)
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

