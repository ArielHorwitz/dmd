-------------------------------- LSP ------------------------------------------

-- Refer to: https://github.com/lite-xl/lite-xl-lsp/blob/master/config.lua

local lspconfig = require "plugins.lsp.config"


-- Python
lspconfig.pylsp.setup {
  settings = {
    pylsp = {
      plugins = {
        flake8 = {
          maxLineLength = 88,
          enabled = true,
        },
        autopep8 = { enabled = false },
        yapf = { enabled = false },
        pycodestyle = { enabled = false },
        pydocstyle = { enabled = false },
        pyflakes = { enabled = false },
        pylint = { enabled = false },
      }
    }
  }
}

-- Lua
lspconfig.sumneko_lua.setup {
  command = {
    "/home/wiw/temp/lua-language-server/lua-language-server",
    "-E",
    "/home/wiw/temp/lua-language-server/main.lua",
  },
  settings = {
    Lua = {
      diagnostics = {
        enable = false
      }
    }
  }
}

-- Rust
lspconfig.rls.setup()

-- Bash
lspconfig.bashls.setup()

-- Dockerfile
lspconfig.dockerls.setup()

-- YAML
lspconfig.yamlls.setup()

