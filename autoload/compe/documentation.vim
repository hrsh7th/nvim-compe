let s:MarkupContent = vital#compe#import('VS.LSP.MarkupContent')
let s:FloatingWindow = vital#compe#import('VS.Vim.Window.FloatingWindow')

let s:window = s:FloatingWindow.new()
let s:border = s:FloatingWindow.new()

"
" compe#documentation#show
"
function! compe#documentation#open(document) abort
  call compe#documentation#close()
  if !compe#_is_selected_manually()
    return
  endif

  let l:document = split(s:MarkupContent.normalize(a:document), "\n", v:true)
  let l:layout = s:get_screenpos(pum_getpos(), l:document)
  if empty(l:layout)
    return
  endif

  let l:maxwidth = float2nr(&columns * 0.4)
  let l:maxheight = float2nr(&lines * 0.4)

  call s:window.open({
  \   'row': l:layout.row + 1,
  \   'col': l:layout.col + 1,
  \   'maxwidth': l:maxwidth - 2,
  \   'maxheight': l:maxheight - 2,
  \   'filetype': 'markdown',
  \   'contents': l:document,
  \   'winhl': 'NormalFloat:Normal',
  \ })

  let l:borders = []
  call add(l:borders, '╭' . repeat('─', min([l:layout.width, l:maxwidth])) . '╮')
  for l:i in range(0, min([l:layout.height, l:maxheight - 2]) - 1)
    call add(l:borders, '│' . repeat(' ', min([l:layout.width, l:maxwidth])) . '│')
  endfor
  call add(l:borders, '╰' . repeat('─', min([l:layout.width, l:maxwidth])) . '╯')
  call s:border.open({
  \   'row': l:layout.row,
  \   'col': l:layout.col,
  \   'maxwidth': l:maxwidth,
  \   'maxheight': l:maxheight,
  \   'filetype': 'border',
  \   'contents': l:borders,
  \   'winhl': 'NormalFloat:Normal',
  \ })
  redraw!
endfunction

"
" compe#documentation#close
"
function! compe#documentation#close() abort
  call s:border.close()
  call s:window.close()
endfunction

"
" get_floatwin_screenpos
"
function! s:get_screenpos(event, document) abort
  if empty(a:event)
    return []
  endif

  let l:total_item_count = a:event.size
  let l:current_item_index = max([complete_info(['selected']).selected, 0]) " NOTE: sometimes vim returns -2.

  " compute content width.
  let l:size = s:window.get_size({ 'contents': a:document })
  let l:size.width += 2 " for borders.
  let l:size.height += 2 " for borders.

  " create x.
  let l:col_if_right = a:event.col + a:event.width + (a:event.scrollbar ? 1 : 0)
  let l:col_if_left = a:event.col - l:size.width - 1

  " use more big space.
  if a:event.col > (&columns - l:col_if_right)
    let l:col = l:col_if_left - 1
  else
    let l:col = l:col_if_right + 1
  endif

  if l:col <= 0 || &columns <= l:col + l:size.width
    return {}
  endif

  return {
  \   'width': l:size.width - 2,
  \   'height': l:size.height - 2,
  \   'row': a:event.row,
  \   'col': l:col
  \ }
endfunction

