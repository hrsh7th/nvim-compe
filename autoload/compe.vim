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
  return compe#source#vim_bridge#register(a:name, a:source)
endfunction

"
" compe#register_source
"
function! compe#unregister_source(id) abort
  call compe#source#vim_bridge#unregister(a:id)
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
" compe#confirm
"
let s:confirming = v:false
inoremap <silent><expr><Plug>(compe-confirm-before) <SID>confirm_state(v:true)
inoremap <silent><expr><Plug>(compe-confirm-after) <SID>confirm_state(v:false)
function! s:confirm_state(state) abort
  let s:confirming = a:state
  return "\<Ignore>"
endfunction
function! compe#confirm(...) abort
  let l:completeopts = split(&completeopt, ',')
  for l:opt in ['menuone', 'noselect']
    if index(l:completeopts, l:opt) == -1
      echohl ErrorMsg
      echomsg '[nvim-compe] You must set `set completeopt=menuone,noselect` in your vimrc.'
      echohl None
    endif
  endfor

  let l:fallback = get(a:000, 0, v:null)
  if mode()[0] ==# 'i' && complete_info(['selected']).selected != -1
    call luaeval('require"compe"._confirm_pre()', v:null)
    call feedkeys("\<Plug>(compe-confirm-before)", '')
    call feedkeys("\<C-y>", 'n')
    call feedkeys("\<Plug>(compe-confirm-after)", '')
  elseif type(l:fallback) == v:t_string
    call feedkeys(l:fallback, 'n')
  elseif type(l:fallback) == v:t_dict
    call feedkeys(get(l:fallback, 'keys', ''), get(l:fallback, 'mode', ''))
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

  let l:fallback = get(a:000, 0, v:null)
  if type(l:fallback) == v:t_string
    call feedkeys(l:fallback, 'n')
  elseif type(l:fallback) == v:t_dict
    call feedkeys(get(l:fallback, 'keys', ''), get(l:fallback, 'mode', ''))
  endif
  return "\<Ignore>"
endfunction

"
" compe#scroll
"
function! compe#scroll(args) abort
  let l:delta = get(a:args, 'delta', 4)

  let l:ctx = {}
  function! l:ctx.callback(delta) abort
    for l:winid in s:Window.find({ winid -> !!getwinvar(winid, 'compe_documentation', v:false) })
      call s:Window.scroll(l:winid, s:Window.info(l:winid).topline + a:delta)
    endfor
  endfunction
  call timer_start(0, { -> l:ctx.callback(l:delta) })
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
" compe#_is_confirming
"
function! compe#_is_confirming() abort
  return s:confirming
endfunction
