let s:accept_pattern = '\%([^<[:digit:][:blank:]~\./]\{-1,}\)'
let s:prefix_pattern = '\%(\~/\|\./\|\.\./\|/\)'
let s:name_pattern = '[^/\\:\*?<>\|]'

"
" compe_path#source#register
"
function! compe_path#source#register() abort
  call compe#source#vim_bridge#register('path', {
  \   'get_metadata': function('s:get_metadata'),
  \   'datermine': function('s:datermine'),
  \   'complete': function('s:complete')
  \ })
endfunction

"
" s:get_metadata
"
function! s:get_metadata() abort
  return {
  \   'sort': v:false,
  \   'priority': 100,
  \ }
endfunction

"
" s:datermine
"
function! s:datermine(context) abort
  let [l:_, l:keyword_pattern_offset, l:__] = matchstrpos(a:context.before_line, '/' . s:name_pattern . '*$')
  let l:keyword_pattern_offset += 1
  if l:keyword_pattern_offset > 0
    return {
    \   'keyword_pattern_offset': l:keyword_pattern_offset
    \ }
  end
  return {}
endfunction

"
" s:complete
"
function! s:complete(args) abort
  let l:input = matchstr(a:args.context.before_line, s:accept_pattern . '\zs' . s:prefix_pattern . '\%(' . s:name_pattern . '\+/\)*$')
  let l:input = substitute(s:absolute(l:input), '[^/]*$', '', 'g')

  if !isdirectory(l:input) && !filereadable(l:input)
    return a:args.abort()
  endif

  let l:items = sort(map(globpath(l:input, '*', v:true, v:true), function('s:convert', [l:input])), function('s:sort'))
  call a:args.callback({ 'items': l:items })
endfunction

"
" convert
"
function! s:convert(input, key, path) abort
  let l:part = fnamemodify(a:path, ':t')
  if isdirectory(a:path)
    let l:menu = '[d]'
    let l:abbr = '/' . l:part
  else
    let l:menu = '[f]'
    let l:abbr =  l:part
  endif

  return {
  \   'word': '/' . l:part,
  \   'abbr': l:abbr,
  \   'menu': l:menu
  \ }
endfunction

"
" sort
"
function! s:sort(item1, item2) abort
  if a:item1.menu ==# '[d]' && a:item2.menu !=# '[d]'
    return -1
  endif
  if a:item1.menu !=# '[d]' && a:item2.menu ==# '[d]'
    return 1
  endif
  return 0
endfunction


"
" absolute
"
function! s:absolute(input) abort
  if a:input =~# '^\V./' || a:input =~# '^\V../'
    return s:append_slash(resolve(expand('%:p:h') . '/' . a:input))
  elseif a:input =~# '^\V~/'
    return s:append_slash(expand(a:input))
  endif
  return a:input
endfunction

"
" append_slash
"
function! s:append_slash(path) abort
  if a:path[-1:-1] ==# '/'
    return a:path
  endif
  return a:path . '/'
endfunction

