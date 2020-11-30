if exists('g:loaded_compe') || !has('nvim')
  finish
endif
let g:loaded_compe = v:true

augroup compe
  autocmd!
  autocmd CompleteDone * call s:on_complete_done()
  autocmd CompleteChanged * call s:on_complete_changed()
  autocmd InsertLeave * call s:on_insert_leave()
  autocmd TextChangedI,TextChangedP * call s:on_text_changed()
augroup END

"
" on_complete_changed
"
function! s:on_complete_changed() abort
  call luaeval('require"compe":on_complete_changed()')
endfunction

"
" on_complete_done
"
function! s:on_complete_done() abort
  call luaeval('require"compe":on_complete_done()')
endfunction

"
" on_insert_leave
"
function! s:on_insert_leave() abort
  call luaeval('require"compe":on_insert_leave()')
endfunction

"
" s:on_text_changed
"
function! s:on_text_changed() abort
  call luaeval('require"compe":on_text_changed()')
endfunction

call compe#pattern#set_defaults()

call compe#register_source('path', compe_path#source#create())
call compe#register_source('tags', compe_tags#source#create())
call compe#register_source('vsnip', compe_vsnip#source#create())
call compe_lamp#source#attach()

lua require'compe':register_source('buffer', require'compe_buffer')
lua require'compe':register_source('nvim_lua', require'compe_nvim_lua')
lua require'compe_nvim_lsp'.attach()

" setup
if has_key(g:, 'compe')
  call compe#setup(g:compe)
endif

