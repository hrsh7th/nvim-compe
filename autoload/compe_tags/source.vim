"
" compe_tags#source#create
"
function! compe_tags#source#create() abort
  return {
  \   'get_metadata': function('s:get_metadata'),
  \   'datermine': function('s:datermine'),
  \   'documentation': function('s:documentation'),
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
" s:documentation
"
function! s:documentation(args) abort
  let l:word = get(a:args.completed_item, 'word', '')
  if empty(l:word)
    return a:args.abort()
  endif
  let l:tags = uniq(map(taglist(l:word), 'v:val.filename'))
  if len(l:tags) > 10
    let l:tags = l:tags[0:9] + [printf('...and %d more', len(l:tags[10:]))]
  endif
  return a:args.callback(l:tags)
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
