local snippets = require 'plugins.snippets'

snippets.add {
    trigger  = 'rfn',
    info     = 'Rust function',
    desc     = 'A function for Rust with a Result return type',
    format   = 'lsp',
    template = [[
fn ${1:func}() -> Result<()> {
    ${0:Ok(())}
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
    trigger  = 'sfn',
    info     = 'Shell function',
    desc     = 'A function for shellscript',
    format   = 'lsp',
    template = [[
${1:shell_function}() {
    set -e
    $0
}]]
}

snippets.add {
    trigger  = 'sif',
    info     = 'Shell if statement',
    desc     = 'If statement for shellscript',
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
    desc     = 'Print a Python variable with an f-string',
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
