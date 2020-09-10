if exists('g:loaded_compe') || !has('nvim')
  finish
endif
let g:loaded_compe = v:true

let g:compe_enabled = get(g:, 'compe_enabled', v:false)
let g:compe_debug = get(g:, 'compe_debug', v:false)
let g:compe_min_length = get(g:, 'compe_min_length', 1)
let g:compe_auto_preselect = get(g:, 'compe_auto_preselect', v:false)

augroup compe
  autocmd!
  autocmd InsertCharPre * call s:on_insert_char_pre()
  autocmd TextChangedI,TextChangedP * call s:on_text_changed()
augroup END

"
" s:on_insert_char_pre
"
function! s:on_insert_char_pre() abort
  if g:compe_enabled
    call luaeval('require"compe":on_insert_char_pre()')
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

if g:compe_enabled
  lua require'compe':register_lua_source('buffer', require'compe_buffer')
  call compe_lamp#source#register()
  call compe_vsnip#source#register()
  call compe_path#source#register()
  call compe#pattern#set_defaults()
end

