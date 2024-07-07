------------------------------- Plugins ---------------------------------------

local config = require "core.config"


-- Builtin plugins
config.plugins.autocomplete.max_height = 15
config.plugins.autocomplete.min_len = 1
config.plugins.autoreload.always_show_nagview = true
config.plugins.bracketmatch.line_size = 4
config.plugins.drawwhitespace = { enabled = true, show_leading = false, show_middle_min = 2 }
config.plugins.lineguide.width = 3
config.plugins.lineguide.enabled = true
config.plugins.lineguide.rulers = { [1] = 80, [2] = 100, [3] = 120 }
config.plugins.linewrapping.enable_by_default = true
config.plugins.linewrapping.mode = "word"
config.plugins.lsp.mouse_hover_delay = 750
config.plugins.lsp.more_yielding = true
config.plugins.lsp.symbolstree_visibility = "hide"

local snippets = require 'plugins.snippets'

snippets.add {
    trigger  = 'rfn',
    info     = 'Rust function',
    desc     = 'A function for rust',
    format   = 'lsp',
    template = [[
fn ${0:func}() -> Result<()> {
    Ok(())
}]]
}

snippets.add {
    trigger  = 'cb',
    info     = 'codeblock',
    desc     = 'Codeblock for markdown',
    format   = 'lsp',
    template = [[
```${0:markdown}
```
]]
}

snippets.add {
    trigger  = 'sf',
    info     = 'Shell function',
    desc     = 'A function for bash',
    format   = 'lsp',
    template = [[
${0:shell_function}() {
    set -e
}]]
}

snippets.add {
    trigger  = 'sif',
    info     = 'Shell if statement',
    desc     = 'If statement for bash',
    format   = 'lsp',
    template = [=[
if [[ -n \$${1:arg} ]]; then
    $0
fi
]=]
}

snippets.add {
    trigger  = 'ppf',
    info     = 'Python f-string',
    desc     = 'Python print f-string',
    format   = 'lsp',
    template = [[print(f'{${0:expression}=}')]]
}

snippets.add {
    trigger  = 'doc',
    info     = 'Python docstring',
    desc     = 'Python docstring',
    format   = 'lsp',
    template = [["""${0:DOCSTRING_PLACEHOLDER}"""]]
}

snippets.add {
    trigger  = 'ifname',
    info     = 'if name main',
    desc     = 'Boilerplate for python main script file',
    format   = 'lsp',
    template = [[

def main():
    ${0:pass}

if __name__ == "__main__":
    main()]]
}
