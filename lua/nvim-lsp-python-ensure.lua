local function shell(cmd)
  return io.popen(cmd):read("*all")
end


local function parse(shell_output)

  -- The return code `rc` must be the last `shell_output` line.
  -- If no errors occur, then `rc == 0`.
  local rc_start, rc_end = shell_output:find("%d+%s*$")
  local rc = shell_output:sub(rc_start, rc_end)

  -- NOTE: [rc_start - 1] is the trailing "\n".
  local rest = shell_output:sub(1, rc_start - 2)

  -- The last line of the `rest` is the `msg` associated with `rc`.
  -- The `msg` is assumed to be the `cmd` to run Python LSP if `rc == 0`.
  local msg_start, msg_end = rest:find("\n-[^\n]-$")
  -- Cut the leading "\n".
  if rest:sub(msg_start, msg_start) == "\n" then
    msg_start = msg_start + 1
  end
  local msg = rest:sub(msg_start, msg_end)

  -- All previous `rest` lines are the `log` (the shell output).
  -- The `log` is assumed to be empty if `rc == 0`, but that doesn't matter.
  local log = rest:sub(1, msg_start - 1)

  return tonumber(rc), msg, log
end


local function ensure_cmd()

  -- LSP will be installed to this Python venv if not exists globally.
  local vimdata = vim.fn.stdpath("data")
  local venv = vim.fn.expand(vimdata .. "/lsp/python")

  -- Main shell script to ensure a Python LSP.
  local is_win = vim.fn.has("win32") == 1
  local sh = is_win and ".bat" or ".sh"
  local plugin_path = vim.fn.expand("<sfile>:p:h:h")
  local scripts = vim.fn.expand(plugin_path .. "/scripts")
  local ensure_script = vim.fn.expand(scripts .. "/ensure" .. sh)

  return ensure_script .. " \""..venv.."\""
end


return function()
  return parse(shell(ensure_cmd()))
end
