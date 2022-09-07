local function shellout(txt)

  -- The return code `rc` must be the last `txt` line.
  local rc_start, rc_end = txt:find("%d+%s*$")
  local rc = txt:sub(rc_start, rc_end)

  -- (rc_start - 1) ends with "\n"
  -- (rc_start - 2) - without last "\n"
  local out = txt:sub(1, rc_start - 2)

  return tonumber(rc), out
end


local function shell(cmd)
  local shell = io.popen(cmd)
  local txt = shell:read("*all")
  shell:close()
  return shellout(txt)
end


local vi = vim.fn
local plugin_path = vi.expand("<sfile>:p:h:h")
local ext = vi.has("win32") and ".bat" or ".sh"
local ensure = vi.expand(plugin_path .. "/scripts/ensure" .. ext)
local venv = vi.expand(vi.stdpath("data") .. "/lsp/python")
local ensure_pylsp = ensure .. " \""..venv.."\""

-- The `out` is a `cmd` to run *pylsp* when `rc` is 0
-- or an error message otherwise.
local rc, out = shell(ensure_pylsp)

if rc == 0 then
  require("lspconfig").pylsp.setup{
    cmd = {out},
  }
end
