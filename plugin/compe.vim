if exists('g:loaded_compe') || !has('nvim')
  finish
endif
let g:loaded_compe = v:true

augroup compe
  autocmd!
  autocmd CompleteDone * call s:on_complete_done()
  autocmd CompleteChanged * call s:on_complete_changed()
  autocmd InsertEnter * call s:on_insert_enter()
  autocmd TextChangedI,TextChangedP * call s:on_text_changed()
augroup END

"
" on_complete_changed
"
function! s:on_complete_changed() abort
  call luaeval('require"compe"._on_complete_changed()')
endfunction

"
" on_complete_done
"
function! s:on_complete_done() abort
  call luaeval('require"compe"._on_complete_done()')
endfunction

"
" on_insert_enter
"
function! s:on_insert_enter() abort
  call luaeval('require"compe"._on_insert_enter()')
endfunction

"
" s:on_text_changed
"
function! s:on_text_changed() abort
  call luaeval('require"compe"._on_text_changed()')
endfunction

"
" setup vim sources.
"
call compe#register_source('path', compe_path#source#create())
call compe#register_source('tags', compe_tags#source#create())
call compe#register_source('vsnip', compe_vsnip#source#create())
call compe_lamp#source#attach()

"
" setup lua sources.
"
lua require'compe'.register_source('buffer', require'compe_buffer')
lua require'compe'.register_source('nvim_lua', require'compe_nvim_lua')
lua require'compe_nvim_lsp'.attach()

"
" setup
"
if has_key(g:, 'compe')
  call compe#setup(g:compe)
endif

