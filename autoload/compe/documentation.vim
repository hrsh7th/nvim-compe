let s:Buffer = vital#compe#import('VS.Vim.Buffer')
let s:Markdown = vital#compe#import('VS.Vim.Syntax.Markdown')
let s:Window = vital#compe#import('VS.Vim.Window')
let s:MarkupContent = vital#compe#import('VS.LSP.MarkupContent')
let s:FloatingWindow = vital#compe#import('VS.Vim.Window.FloatingWindow')

let s:window = s:FloatingWindow.new()
call s:window.set_var('&wrap', 1)
call s:window.set_var('&conceallevel', 2)
call s:window.set_bufnr(s:Buffer.create())
call setbufvar(s:window.get_bufnr(), '&buftype', 'nofile')
call setbufvar(s:window.get_bufnr(), '&bufhidden', 'hide')
call setbufvar(s:window.get_bufnr(), '&buflisted', 0)

"
" compe#documentation#show
"
function! compe#documentation#open(document) abort
  let l:document = split(s:MarkupContent.normalize(a:document), "\n", v:true)
  call deletebufline(s:window.get_bufnr(), 1, '$')
  call setbufline(s:window.get_bufnr(), 1, l:document)

  let l:size = s:window.get_size({
  \   'maxwidth': float2nr(&columns * 0.4),
  \   'maxheight': float2nr(&lines * 0.3),
  \ })

  let l:pos = s:get_screenpos(pum_getpos(), l:size)
  if empty(l:pos)
    return s:window.close()
  endif

  if pumvisible()
    call s:window.open({
    \   'row': l:pos[0] + 1,
    \   'col': l:pos[1] + 1,
    \   'width': l:size.width,
    \   'height': l:size.height,
    \ })
    call s:Window.do(s:window.get_winid(), { -> s:Markdown.apply() })
  endif
endfunction

"
" compe#documentation#close
"
function! compe#documentation#close() abort
  call s:window.close()
endfunction

"
" get_screenpos
"
function! s:get_screenpos(event, size) abort
  if empty(a:event)
    return []
  endif

  let l:col_if_right = a:event.col + a:event.width + 1 + (a:event.scrollbar ? 1 : 0)
  let l:col_if_left = a:event.col - a:size.width - 2

  if a:size.width >= (&columns - l:col_if_right)
    let l:col = l:col_if_left
  else
    let l:col = l:col_if_right
  endif

  if l:col <= 0
    return []
  endif
  if &columns <= l:col + a:size.width
    return []
  endif

  return [a:event.row, l:col]
endfunction

