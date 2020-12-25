let s:MarkupContent = vital#compe#import('VS.LSP.MarkupContent')
let s:FloatingWindow = vital#compe#import('VS.Vim.Window.FloatingWindow')

let s:window = s:FloatingWindow.new()
let s:border = s:FloatingWindow.new()

"
" compe#documentation#show
"
function! compe#documentation#open(document) abort
  if !compe#_is_selected_manually()
    return
  endif

  let l:document = split(s:MarkupContent.normalize(a:document), "\n", v:true)

  let l:pos = s:get_screenpos(pum_getpos(), l:document)
  if empty(l:pos)
    call s:border.close()
    return s:window.close()
  endif

  call s:window.open({
  \   'row': l:pos[0],
  \   'col': l:pos[1],
  \   'maxwidth': float2nr(&columns * 0.4),
  \   'maxheight': float2nr(&lines * 0.4),
  \   'filetype': 'markdown',
  \   'contents': l:document,
  \ })

  let l:width = float2nr(&columns * 0.4)
  let l:height = float2nr(&lines * 0.4)
  let l:top = '╭' . repeat('─', l:width - 2) . '╮'
  let l:mid = '│' . repeat(' ', l:width - 2) . '│'
  let l:bot = '╰' . repeat('─', l:width - 2) . '╯'
  let l:lines = [l:top] + repeat([l:mid], l:height - 2) + [l:bot]


  call s:border.open({
  \   'row': l:pos[0],
  \   'col': l:pos[1],
  \   'maxwidth': l:width,
  \   'maxheight': l:height,
  \   'filetype': 'markdown',
  \   'contents': l:lines,
  \ })

endfunction

"
" compe#documentation#close
"
function! compe#documentation#close() abort
  call s:window.close()
  call s:border.close()
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

  " create x.
  let l:doc_width = s:window.get_size({ 'contents': a:document }).width
  let l:col_if_right = a:event.col + a:event.width + 1 + (a:event.scrollbar ? 1 : 0)
  let l:col_if_left = a:event.col - l:doc_width - 2

  " use more big space.
  if a:event.col > (&columns - l:col_if_right)
    let l:col = l:col_if_left
  else
    let l:col = l:col_if_right
  endif

  if l:col <= 0
    return []
  endif
  if &columns <= l:col + l:doc_width
    return []
  endif

  return [a:event.row, l:col]
endfunction



