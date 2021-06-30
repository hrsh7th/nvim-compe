if exists('g:loaded_compe') || !has('nvim')
  finish
endif
let g:loaded_compe = v:true

augroup compe
  autocmd!
  autocmd CompleteChanged * call s:on_complete_changed()
  autocmd InsertEnter * call s:on_insert_enter()
  autocmd InsertLeave * call s:on_insert_leave()
  autocmd TextChangedI,TextChangedP * call s:on_text_changed()
  autocmd User CompeConfirmDone silent
augroup END

"
" on_complete_changed
"
function! s:on_complete_changed() abort
  call luaeval('require"compe"._on_complete_changed()')
endfunction

"
" on_insert_enter
"
function! s:on_insert_enter() abort
  call luaeval('require"compe"._on_insert_enter()')
endfunction

"
" on_insert_enter
"
function! s:on_insert_leave() abort
  call luaeval('require"compe"._on_insert_leave()')
endfunction

"
" s:on_text_changed
"
function! s:on_text_changed() abort
  call luaeval('require"compe"._on_text_changed()')
endfunction

if !hlexists('CompeDocumentation')
  highlight link CompeDocumentation NormalFloat
endif

if !hlexists('CompeDocumentationBorder')
  highlight link CompeDocumentationBorder CompeDocumentation
endif

"
" setup
"
if has_key(g:, 'compe')
  call compe#setup(g:compe)
endif
