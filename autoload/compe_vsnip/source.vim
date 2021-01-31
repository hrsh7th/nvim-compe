"
" compe_vsnip#source#create
"
function! compe_vsnip#source#create() abort
  return {
  \   'get_metadata': function('s:get_metadata'),
  \   'determine': function('s:determine'),
  \   'documentation': function('s:documentation'),
  \   'complete': function('s:complete'),
  \   'confirm': function('s:confirm'),
  \ }
endfunction

"
" documentation
"
function! s:documentation(args) abort
  call a:args.callback(json_decode(a:args.completed_item.user_data.compe).vsnip.snippet)
endfunction

"
" s:get_metadata
"
function! s:get_metadata() abort
  return {
  \   'priority': 50,
  \   'menu': '[Vsnip]',
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
  let l:ctx = {}
  function! l:ctx.callback(item) abort
    let a:item.user_data = { 'compe': a:item.user_data }
    return a:item
  endfunction
  call a:args.callback({
  \   'items': map(vsnip#get_complete_items(bufnr('%')), { _, item -> l:ctx.callback(item) })
  \ })
endfunction

"
" confirm
"
function! s:confirm(args) abort
  call vsnip#anonymous(join(json_decode(a:args.completed_item.user_data.compe).vsnip.snippet, "\n"), {
  \   'prefix': a:args.completed_item.word,
  \ })
endfunction

