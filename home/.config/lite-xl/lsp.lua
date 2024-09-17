-------------------------------- LSP ------------------------------------------

-- Refer to: https://github.com/lite-xl/lite-xl-lsp/blob/master/config.lua

local lspconfig = require "plugins.lsp.config"


-- Bash
lspconfig.bashls.setup()

-- Rust
lspconfig.rust_analyzer.setup()

-- Python
lspconfig.pylsp.setup {
    settings = {
        pylsp = {
            plugins = {
                flake8 = {
                    -- ~>>>
                    maxLineLength = 88,
                    -- ~>>> think
                    maxLineLength = 100,
                    -- ~<<<
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
lspconfig.sumneko_lua.setup()

-- Dockerfile
lspconfig.dockerls.setup()

-- YAML
lspconfig.yamlls.setup()

-- SQL
lspconfig.sqlls.setup()
