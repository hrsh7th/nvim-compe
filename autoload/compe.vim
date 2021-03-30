let s:Window = vital#compe#import('VS.Vim.Window')

"
" Public API
"

"
" compe#setup
"
function! compe#setup(config, ...) abort
  call luaeval('require"compe".setup(_A[1], _A[2])', [a:config, get(a:, 1, v:null)])
endfunction

"
" compe#register_source
"
function! compe#register_source(name, source) abort
  if matchstr(a:name, '^\w\+$') ==# ''
    throw "compe: the source's name must be \w\+"
  endif
  return compe#vim_bridge#register(a:name, a:source)
endfunction

"
" compe#register_source
"
function! compe#unregister_source(id) abort
  call compe#vim_bridge#unregister(a:id)
endfunction

"
" compe#complete
"
function! compe#complete(...) abort
  if mode()[0] ==# 'i'
    call timer_start(0, { -> luaeval('require"compe"._complete(_A)', { 'manual': v:true }) })
  endif
  return "\<Ignore>"
endfunction

"
" confirm
"
let g:___compe_confirm_option = {}
inoremap <silent><nowait> <Plug>(compe-confirm) <C-r>=luaeval('require"compe"._confirm_pre()')<CR><C-y><C-r>=luaeval('require"compe"._confirm(_A)', g:___compe_confirm_option)<CR>
function! compe#confirm(...) abort
  " Check completeopt
  for l:opt in ['menuone', 'noselect']
    if stridx(&completeopt, l:opt) == -1
      echohl ErrorMsg
      echomsg '[nvim-compe] You must set `set completeopt=menuone,noselect` in your vimrc.'
      echohl None
    endif
  endfor

  let l:option = s:normalize(get(a:000, 0, {}))
  let l:select = get(l:option, 'select', v:false)
  let l:selected = complete_info(['selected']).selected != -1
  if mode()[0] ==# 'i' && pumvisible() && (l:select || l:selected)
    let g:___compe_confirm_option = l:option
    let l:confirm = ''
    let l:confirm .= l:select && !l:selected ? "\<C-n>" : ''
    let l:confirm .= "\<Plug>(compe-confirm)"
    call feedkeys(l:confirm)
  else
    call s:fallback(l:option)
  endif
  return "\<Ignore>"
endfunction

"
" compe#close
"
function! compe#close(...) abort
  if mode()[0] ==# 'i' && pumvisible()
    return "\<C-e>\<C-r>=luaeval('require\"compe\"._close()')\<CR>"
  endif
  call s:fallback(s:normalize(get(a:000, 0, {})))
  return "\<Ignore>"
endfunction

"
" compe#scroll
"
function! compe#scroll(option) abort
  let l:ctx = {}
  function! l:ctx.callback(option) abort
    let l:winids = s:Window.find({ winid -> !!getwinvar(winid, 'compe_documentation', v:false) })
    if !empty(l:winids)
      let l:delta = get(a:option, 'delta', 4)
      for l:winid in l:winids
        call s:Window.scroll(l:winid, s:Window.info(l:winid).topline + l:delta)
      endfor
    else
      call s:fallback(a:option)
    endif
  endfunction
  call timer_start(0, { -> l:ctx.callback(s:normalize(a:option)) })
  return "\<Ignore>"
endfunction

"
" Private API
"

"
" compe#_is_selected_manually
"
function! compe#_is_selected_manually() abort
  return pumvisible() && !empty(v:completed_item) ? v:true : v:false
endfunction

"
" compe#_has_completed_item
"
function! compe#_has_completed_item() abort
  return !empty(v:completed_item) ? v:true : v:false
endfunction

"
" normalize
"
function! s:normalize(option) abort
  if type(a:option) == v:t_string
    return { 'keys': a:option, 'mode': 'n' }
  endif
  return a:option
endfunction

"
" fallback
"
function! s:fallback(option) abort
  if has_key(a:option, 'keys') && !empty(a:option.keys)
    call feedkeys(a:option.keys, get(a:option, 'mode', 'n'))
  endif
endfunction

