if exists('g:loaded_compe') || !has('nvim')
  finish
endif
let g:loaded_compe = v:true

let g:compe_enabled = get(g:, 'compe_enabled', v:false)
let g:compe_debug = get(g:, 'compe_debug', v:false)
let g:compe_throttle_time = get(g:, 'compe_throttle_time', 0)
let g:compe_min_length = get(g:, 'compe_min_length', 1)
let g:compe_auto_preselect = get(g:, 'compe_auto_preselect', v:false)
let g:compe_source_timeout = get(g:, 'compe_source_timeout', 200)
let g:compe_incomplete_delay = get(g:, 'compe_incomplete_delay', 100)

augroup compe
  autocmd!
  autocmd CompleteDone * call s:on_complete_done()
  autocmd InsertLeave * call s:on_insert_leave()
  autocmd InsertCharPre * call s:on_insert_char_pre()
  autocmd TextChangedI,TextChangedP * call s:on_text_changed()
augroup END

"
" on_complete_done
"
function! s:on_complete_done() abort
  if g:compe_enabled
    if compe#is_selected_manually()
      call luaeval('require"compe":clear()')
    endif
  endif
endfunction

"
" on_insert_leave
"
function! s:on_insert_leave() abort
  if g:compe_enabled
    call luaeval('require"compe":clear()')
  endif
endfunction

"
" on_insert_char_pre
"
function! s:on_insert_char_pre() abort
  if g:compe_enabled
    " Check one-alphabetical char inserted.
    if strlen(v:char) == 1 && v:char =~# '[[:print:]]'
      call luaeval('require"compe":on_insert_char_pre()')
    endif
  endif
endfunction

"
" s:on_text_changed
"
function! s:on_text_changed() abort
  if g:compe_enabled
    call luaeval('require"compe":on_text_changed()')
  endif
endfunction

call compe#pattern#set_defaults()

