function! health#compe#check() abort
  call s:snippet()
  call s:mapping()
endfunction

function! s:snippet() abort
  call health#report_start('compe:snippet')
  if !empty(compe#confirmation#get_expand_snippet())
    call health#report_ok('snippet engine detected.')
  else
    call health#report_info('snippet engine is not detected.')
  endif
endfunction

function! s:mapping() abort
  call health#report_start('compe:mapping')
  call feedkeys('i', 'n')
  call feedkeys("\<Plug>(compe-checkhealth-check)", 'x')
endfunction
inoremap <expr><Plug>(compe-checkhealth-check) <SID>_mapping()
function! s:_mapping() abort
  let l:mappings = execute('imap')
  let l:mappings = split(l:mappings, "\n")
  let l:mappings = filter(l:mappings, 'v:val =~# "compe#"')

  let l:msgs = []
  for l:name in ['compe#complete', 'compe#confirm', 'compe#close', 'compe#scroll']
    let l:found = v:false
    for l:mapping in l:mappings
      if l:mapping =~# l:name
        call health#report_ok(printf('`%s` is mapped: (`%s`)', l:name, l:mapping))
        let l:found = v:true
        break
      endif
    endfor
    if !l:found
      call health#report_info(printf('`%s` is not mapped', l:name))
    endif
  endfor
  return "\<Ignore>"
endfunction

