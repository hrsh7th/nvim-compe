let s:MarkupContent = vital#compe#import('VS.LSP.MarkupContent')
let s:FloatingWindow = vital#compe#import('VS.Vim.Window.FloatingWindow')

let s:window = s:FloatingWindow.new()

"
" compe#documentation#show
"
function! compe#documentation#open(event, document) abort
  if !compe#is_selected_manually()
    return
  endif

  let l:pos = s:get_screenpos(a:event, a:document)
  if empty(l:pos)
    return s:window.close()
  endif

  call s:window.open({
  \   'row': l:pos[0],
  \   'col': l:pos[1],
  \   'maxwidth': float2nr(&columns * 0.4),
  \   'maxheight': float2nr(&lines * 0.4),
  \   'filetype': 'markdown',
  \   'contents': split(s:MarkupContent.normalize(a:document), "\n", v:true),
  \ })
endfunction

"
" compe#documentation#close
"
function! compe#documentation#close() abort
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

  " create y.
  let l:pum_scrolloff = min([4, float2nr(a:event.height / 2)]) " TODO: calculate `4` from Vim script.
  let l:pum_scrolloff -= max([0, l:current_item_index - (a:event.size - l:pum_scrolloff)])
  let l:row = a:event.row + min([l:current_item_index, float2nr(a:event.height) - l:pum_scrolloff])

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

  return [l:row, l:col]
endfunction

