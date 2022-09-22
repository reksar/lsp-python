function! s:ensure_lang_server(scripts_path)

  " Main shell script to *ensure* a Python lang server.
  const ext = has('win32') ? '.bat' : '.sh'
  const script = expand(a:scripts_path . '/ensure' . ext)

  " The arg will be passed to the main shell script. Python lang server will be
  " installed into this `venv` dir if does not exists globally.
  const venv = expand(stdpath('data') . '/lsp/python')

  return [script, venv]
endfunction


function! s:reversed_indexes(collection)
  const start_i = len(a:collection) - 1
  const end_i = 0
  const step = -1
  return range(start_i, end_i, step)
endfunction


function! s:last(lines)
  " Returns last not empty line if possible.

  for i in s:reversed_indexes(a:lines)
    if len(a:lines[i])
      return a:lines[i]
    endif
  endfor

  return ''
endfunction


function! s:run_lang_server(log)
  " The `last` `log` line must be a `cmd` to run Python lang server.
  const cmd = s:last(a:log)
  exe 'lua require("nvim-lsp-python")("'.cmd.'")'
  LspStart
endfunction


function! s:show_err(scripts_path, rc, log)

  " The `last` `log` line must be an error message.
  const msg = s:last(a:log)

  const err_msg = '[E'.a:rc.'] '.msg
  echomsg err_msg

  const err_log = [err_msg, '', ''] + a:log
  const window_api = expand(a:scripts_path . '/window.vim')
  exe 'source ' . window_api
  call NvimLspPythonWindow(err_log)
  delfunction NvimLspPythonWindow
endfunction


function! s:job_finish(job_id, rc, event) dict
  if a:rc
    call self.err(a:rc, self.log)
  else
    call self.then(self.log)
  endif
endfunction


function! s:job_log(job_id, data, event) dict
  call extend(self.log, a:data)
endfunction


function! s:job_start(settings)
  let job = a:settings
  let job.log = []

  return jobstart(job.cmd, {
  \  'on_stdout': function('s:job_log', job),
  \  'on_stderr': function('s:job_log', job),
  \  'on_exit': function('s:job_finish', job),
  \})
endfunction


const s:plugin_path = finddir('pack/nvim-lsp-python', &packpath)
const s:scripts_path = expand(s:plugin_path . '/scripts')

call s:job_start({
\  'cmd': s:ensure_lang_server(s:scripts_path),
\  'then': function('s:run_lang_server'),
\  'err': function('s:show_err', [s:scripts_path]),
\})
