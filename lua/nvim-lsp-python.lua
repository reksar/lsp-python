local rc, msg, log = require("nvim-lsp-python.ensure")()

if rc == 0 then
  require("nvim-lsp-python.config")(msg)
else
  require("nvim-lsp-python.error")(rc, msg, log)
end
