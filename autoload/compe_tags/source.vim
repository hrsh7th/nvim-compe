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
  let word = get(a:args.completed_item, 'word', '')
  if empty(word)
    return
  endif
  let tags = map(taglist(word), 'v:val.filename')
  if len(tags) > 10
    let tags = tags[0:9] + [printf('...and %d more', len(tags[10:]))]
  endif
  return a:args.callback(tags)
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
