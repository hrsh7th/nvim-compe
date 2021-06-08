let s:Buffer = vital#compe#import('VS.Vim.Buffer')
let s:Markdown = vital#compe#import('VS.Vim.Syntax.Markdown')
let s:Window = vital#compe#import('VS.Vim.Window')
let s:MarkupContent = vital#compe#import('VS.LSP.MarkupContent')
let s:FloatingWindow = vital#compe#import('VS.Vim.Window.FloatingWindow')

let s:window = s:FloatingWindow.new()
call s:window.set_var('&wrap', 1)
call s:window.set_var('&conceallevel', 2)
call s:window.set_var('&breakindent', 1)
call s:window.set_var('&linebreak', 1)
call s:window.set_var('&winhighlight', 'NormalFloat:CompeDocumentation')
call s:window.set_var('compe_documentation', 1)

let s:document_cache = {}
let s:state = {}
let s:timer = 0

"
" compe#documentation#show
"
function! compe#documentation#open(text) abort
  if getcmdwintype() !=# '' || !pumvisible()
    return compe#documentation#close()
  endif
  call timer_stop(s:timer)
  call s:ensure_buffer()

  " Ensure normalized document
  let l:text = type(a:text) == type([]) ? join(a:text, "\n") : a:text
  if !has_key(s:document_cache, l:text)
    let l:normalized = s:MarkupContent.normalize(l:text)
    let l:document = map(split(l:normalized, "\n"), 'v:val !=# "" ? " " . v:val . " " : ""')
    silent call nvim_buf_set_lines(s:window.get_bufnr(), 0, -1, v:false, l:document)
    let s:document_cache[l:text] = {}
    let s:document_cache[l:text].normalized = l:normalized
    let s:document_cache[l:text].document = l:document
    let s:document_cache[l:text].size = s:window.get_size({ 'maxwidth': float2nr(&columns * 0.4), 'maxheight': float2nr(&lines * 0.3), })
  elseif get(s:state, 'text', '') !=# l:text
    silent call nvim_buf_set_lines(s:window.get_bufnr(), 0, -1, v:false, s:document_cache[l:text].document)
  endif
  let l:document = s:document_cache[l:text].document
  let l:size = s:document_cache[l:text].size

  let l:state = extend({ 'pos': pum_getpos() }, s:document_cache[l:text])
  if s:state == l:state
    return
  endif
  let s:state = l:state

  let l:pos = s:get_screenpos(s:state.pos, l:size)
  if empty(l:pos)
    return compe#documentation#close()
  endif

  silent call s:window.open({
  \   'row': l:pos[0] + 1,
  \   'col': l:pos[1] + 1,
  \   'width': l:state.size.width,
  \   'height': l:state.size.height,
  \ })
  silent call s:Window.do(s:window.get_winid(), { -> s:Markdown.apply({ 'text': s:state.normalized }) })
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

"
" ensure_buffer
"
function! s:ensure_buffer() abort
  if !bufexists(s:window.get_bufnr())
    call s:window.set_bufnr(s:Buffer.create())
    call setbufvar(s:window.get_bufnr(), '&buftype', 'nofile')
    call setbufvar(s:window.get_bufnr(), '&buflisted', 0)
    call setbufvar(s:window.get_bufnr(), '&swapfile', 0)
  endif
endfunction
