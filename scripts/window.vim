" This script is placed here instead of `plugins` dir to avoid autoloading.
" It will be loaded only when necessary to show some info, e.g. on error.


function! s:window(name)

  " Split new bottom horizontal (full width) window
  botright new

  " Set associated buffer name
  exec "f " . a:name

  return win_getid()
endfunction


function! NvimLspPythonWindow(txt)
  let l:window_id = s:window('[nvim-lsp-python]')
  let l:buffer_number = winbufnr(l:window_id)
  let l:line_number = nvim_buf_line_count(l:buffer_number)

  " Show `txt` lines in the buffer of the splitted window.
  call appendbufline(l:buffer_number, l:line_number, a:txt)

  call setbufvar(l:buffer_number, '&modifiable', 0)
endfunction
