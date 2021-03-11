let s:Buffer = vital#compe#import('VS.Vim.Buffer')
let s:Markdown = vital#compe#import('VS.Vim.Syntax.Markdown')
let s:Window = vital#compe#import('VS.Vim.Window')
let s:MarkupContent = vital#compe#import('VS.LSP.MarkupContent')
let s:FloatingWindow = vital#compe#import('VS.Vim.Window.FloatingWindow')

let s:window = s:FloatingWindow.new()
call s:window.set_var('&wrap', 1)
call s:window.set_var('&conceallevel', 2)
call s:window.set_var('&breakindent', 1)
call s:window.set_var('&winhighlight', 'NormalFloat:CompeDocumentation')
call s:window.set_var('compe_documentation', 1)
call s:window.set_bufnr(s:Buffer.create())
call setbufvar(s:window.get_bufnr(), '&buftype', 'nofile')
call setbufvar(s:window.get_bufnr(), '&bufhidden', 'hide')
call setbufvar(s:window.get_bufnr(), '&buflisted', 0)
call setbufvar(s:window.get_bufnr(), '&swapfile', 0)

let s:document_cache = {}
let s:state = {}
let s:timer = 0

"
" compe#documentation#show
"
function! compe#documentation#open(document) abort
  if getcmdwintype() !=# ''
    return s:window.close()
  endif

  let l:ctx = {}
  function! l:ctx.callback(document) abort
    if !pumvisible()
      return
    endif

    " Ensure normalized document
    let l:document = type(a:document) == type([]) ? join(a:document, "\n") : a:document
    if !has_key(s:document_cache, l:document)
      let l:normalize_document = map(split(s:MarkupContent.normalize(l:document), "\n"), '" " . v:val . " "')
      silent call deletebufline(s:window.get_bufnr(), 1, '$')
      silent call setbufline(s:window.get_bufnr(), 1, l:normalize_document)
      let s:document_cache[l:document] = {}
      let s:document_cache[l:document].document = l:normalize_document
      let s:document_cache[l:document].size = s:window.get_size({ 'maxwidth': float2nr(&columns * 0.4), 'maxheight': float2nr(&lines * 0.3), })
    endif
    let l:size = s:document_cache[l:document].size
    let l:document = s:document_cache[l:document].document
    let l:pos = s:get_screenpos(pum_getpos(), l:size)
    if empty(l:pos)
      return s:window.close()
    endif

    let l:state = { 'pos': l:pos, 'size': l:size, 'document': l:document }
    if s:state == l:state
      return
    endif
    let s:state = l:state

    silent call s:window.open({
    \   'row': l:pos[0] + 1,
    \   'col': l:pos[1] + 1,
    \   'width': l:size.width,
    \   'height': l:size.height,
    \ })
    silent call s:Window.do(s:window.get_winid(), { -> s:Markdown.apply() })
  endfunction
  call timer_stop(s:timer)
  let s:timer = timer_start(0, { -> l:ctx.callback(a:document) })
endfunction

"
" compe#documentation#close
"
function! compe#documentation#close() abort
  let s:document_cache = {}
  let s:state = {}
  call timer_stop(s:timer)
  let s:timer = timer_start(0, { -> s:window.close() })
endfunction

"
" get_screenpos
"
function! s:get_screenpos(event, size) abort
  if empty(a:event)
    return []
  endif

  let l:col_if_right = a:event.col + a:event.width + (a:event.scrollbar ? 1 : 0)
  let l:col_if_left = a:event.col - a:size.width - 1

  if a:event.col > float2nr(&columns * 0.6)
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

