"
" compe_vsnip#source#create
"
function! compe_vsnip#source#create() abort
  return {
  \   'get_metadata': function('s:get_metadata'),
  \   'determine': function('s:determine'),
  \   'documentation': function('s:documentation'),
  \   'complete': function('s:complete'),
  \ }
endfunction

"
" documentation
"
function! s:documentation(args) abort
  let l:completed_item = a:args.completed_item
  if empty(get(l:completed_item, 'user_data', ''))
    return a:args.abort()
  endif
  if type(l:completed_item.user_data) == type('')
    let l:user_data = json_decode(l:completed_item.user_data)
  else
    let l:user_data = l:completed_item.user_data
  endif
  if !has_key(l:user_data, 'vsnip')
    return a:args.abort()
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
" s:determine
"
function! s:determine(context) abort
  return compe#helper#determine(a:context)
endfunction

"
" s:complete
"
function! s:complete(args) abort
  call a:args.callback({
  \   'items': vsnip#get_complete_items(bufnr('%'))
  \ })
endfunction

