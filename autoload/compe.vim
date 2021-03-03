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
" confirm
"
function! compe#confirm(...) abort
  let l:completeopts = split(&completeopt, ',')
  for l:opt in ['menuone', 'noselect']
    if index(l:completeopts, l:opt) == -1
      echohl ErrorMsg
      echomsg '[nvim-compe] You must set `set completeopt=menuone,noselect` in your vimrc.'
      echohl None
    endif
  endfor

  if mode()[0] ==# 'i' && complete_info(['selected']).selected != -1
    call luaeval('require"compe"._confirm_pre()')
    call feedkeys("\<Plug>(compe-confirm)")
  else
    call s:fallback(get(a:000, 0, v:null))
  endif
  return "\<Ignore>"
endfunction
inoremap <silent><nowait> <Plug>(compe-confirm) <C-y><C-r>=luaeval('require"compe"._confirm()')<CR>

"
" compe#close
"
function! compe#close(...) abort
  if mode()[0] ==# 'i' && pumvisible()
    return "\<C-e>\<C-r>=luaeval('require\"compe\"._close()')\<CR>"
  endif
  call s:fallback(get(a:000, 0, v:null))
  return "\<Ignore>"
endfunction

"
" compe#scroll
"
function! compe#scroll(args) abort
  let l:ctx = {}
  function! l:ctx.callback(args) abort
    let l:winids = s:Window.find({ winid -> !!getwinvar(winid, 'compe_documentation', v:false) })
    if !empty(l:winids)
      let l:delta = get(a:args, 'delta', 4)
      for l:winid in l:winids
        call s:Window.scroll(l:winid, s:Window.info(l:winid).topline + l:delta)
      endfor
    else
      call s:fallback(get(a:args, 'fallback', v:null))
    endif
  endfunction
  call timer_start(0, { -> l:ctx.callback(a:args) })
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
" fallback
"
function! s:fallback(fallback) abort
  if type(a:fallback) == v:t_string
    return feedkeys(a:fallback, 'n')
  elseif type(a:fallback) == v:t_dict
    if has_key(a:fallback, 'keys')
      return feedkeys(a:fallback.keys, get(a:fallback, 'mode', ''))
    endif
  endif
endfunction

