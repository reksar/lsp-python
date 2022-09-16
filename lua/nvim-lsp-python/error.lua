local function map_quote(lines)
  local quoted = {}

  for _, line in pairs(lines) do
    quoted[#quoted+1] = "'"..line.."'"
  end

  return quoted
end


local function vimlines(txt)
  -- Transform `txt` from "line1\nline2" to "['line1', 'line2']"

  local lines = vim.fn.split(txt, "\n")
  local quoted = map_quote(lines)
  local comma_separated = vim.fn.join(quoted, ",")
  return "["..comma_separated.."]"
end


local function show_window(txt)

  -- Load window API.
  local plugin_path = vim.fn.expand("<sfile>:p:h:h")
  local window = vim.fn.expand(plugin_path .. "/scripts/window.vim")
  vim.cmd("source " .. window)

  -- Show `txt` `lines` in splitted window on `VimEnter`.
  vim.cmd("au VimEnter * ++once call NvimLspPythonWindow("..vimlines(txt)..")")
end


local function show_err_msg(txt)
  vim.cmd("echohl ErrorMsg")
  vim.cmd("echomsg '"..txt.."'")
  vim.cmd("echohl Normal")
end


return function(rc, msg, log)
  local err_msg = "[E"..rc.."] "..msg
  local err_log = err_msg .. "\n\n" .. log
  show_window(err_log)
  show_err_msg(err_msg)
end
