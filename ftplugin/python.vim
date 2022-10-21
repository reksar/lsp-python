function! s:is_lsp_running()
  " TODO
  return 0
endfunction


if exists('s:venv') || s:is_lsp_running()
  finish
endif


" The arg will be passed to the main shell script. Python lang server will be
" installed into this `venv` dir if does not exists globally.
const s:venv = expand(stdpath('data') . '/lsp/python')

const s:plugin_path = finddir('pack/nvim-lsp-python', &packpath)
const s:scripts_path = expand(s:plugin_path . '/scripts')


function! s:ensure_cmd()
  " Main shell cmd to *ensure* a Python lang server.
  const ext = has('win32') ? '.bat' : '.sh'
  const script = expand(s:scripts_path . '/ensure' . ext)
  return [script, s:venv]
endfunction


function! s:reversed_indexes(collection)
  const start = len(a:collection) - 1
  const end = 0
  const step = -1
  return range(start, end, step)
endfunction


function! s:last(lines)    " will we shoot ?
  " Returns last not empty line if possible.
  for i in s:reversed_indexes(a:lines)
    if len(a:lines[i])
      return a:lines[i]
    endif
  endfor
  return ''
endfunction


function! s:pylsp_cmd(log)
  " The `last` `log` line must be a `pylsp_cmd` to run the Python lang server.
  const pylsp_cmd = s:last(a:log)
  " Translate '\' -> '/' instead of backslash escaping in Windows path.
  return fnamemodify(pylsp_cmd, ':gs?\?/?')
endfunction


function! s:run_lang_server(log)
  exe 'lua require("nvim-lsp-python")("'.s:pylsp_cmd(a:log).'")'
  LspStart
endfunction


function! s:show_window(text)
  const window_api = expand(s:scripts_path . '/window.vim')
  exe 'source ' . window_api
  call NvimLspPythonWindow(a:text)
  delfunction NvimLspPythonWindow
endfunction


function! s:show_err(rc, log)
  " The `last` `log` line must be the main error message.
  const msg = s:last(a:log)
  const err_msg = '[E'.a:rc.'] '.msg
  echomsg err_msg
  const err_log = [err_msg, '', ''] + a:log
  call s:show_window(err_log)
endfunction


function! s:bat_encoding()
  const DEFAULT_ENCODING = 850
  " Should be "blah-blah-blah: <encoding>"
  silent const chcp = system('chcp')
  const encoding = str2nr(matchstr(chcp, ':\s*\zs\d\+'))
  return encoding ? encoding : DEFAULT_ENCODING
endfunction


function! s:decode_bat_output(lines)
  const utf8 = map(a:lines, {_, line -> iconv(line, s:bat_encoding(), 'utf-8')})
  " Windows-like line ending - Carriage Return / <CR> / ^M / Ctrl+M
  const CR = nr2char(13)
  " Trim the trailing <CR> char.
  return map(utf8, {_, line -> line[-1:] == CR ? line[:-2] : line})
endfunction


function! s:decode_shell_output(lines)
  " It's expected that all is OK with the UNIX shell output.
  return has('win32') ? s:decode_bat_output(a:lines) : a:lines
endfunction


function! s:job_finish(job_id, rc, event) dict
  const log = s:decode_shell_output(self.log)
  if a:rc
    call self.err(a:rc, log)
  else
    call self.then(log)
  endif
endfunction


function! s:job_log(job_id, data, event) dict
  call extend(self.log, a:data)
endfunction


function! s:job_start(settings)
  " Runs `cmd` and fills the `job.log` array with the *stdout* and *stderr*
  " lines. Then processes the `job.log` with the either `then` or `err`
  " callback on `cmd` exit.
  "
  " The `settings` dict should contain items:
  "   * 'cmd' - (array of str) to run in a shell.
  "   * 'then' - function(log) callback to process `job.log` if no errors.
  "   * 'err' - function(rc, log) callback to process an error.

  let job = a:settings
  let job.log = []

  return jobstart(job.cmd, {
  \  'on_stdout': function('s:job_log', job),
  \  'on_stderr': function('s:job_log', job),
  \  'on_exit': function('s:job_finish', job),
  \})
endfunction


call s:job_start({
\  'cmd': s:ensure_cmd(),
\  'then': function('s:run_lang_server'),
\  'err': function('s:show_err'),
\})
