unalias -a

alias resource="unset BASHPROFILES_INIT_SOURCED; source ~/.profile"
alias c="clear"
alias xo="xdg-open"
alias cpi="cp -i"
alias tarz="tar -czf"
alias taru="tar -xf"
alias tarl="tar -tf"
alias rp="rhinopuffin"
alias gp="geckopanda"
alias batn="bat --style=rule,snip,numbers"
alias batf="bat --style=full"
alias batj="bat --style=full -l json"

alias bri="br -I"
alias ls='ls --color=auto'
alias grep='grep --colour=auto'
alias egrep='egrep --colour=auto'
alias fgrep='fgrep --colour=auto'
alias printenv='printenv -0 | sort -z | tr "\0" "\n"'

alias lastcmd="HISTTIMEFORMAT='' history 2 | head -n1 | awk '{\$1=\"\"; print substr(\$0, 2)}'"
alias lastcmdcopy="lastcmd | clipcatctl load"
alias historylog="HISTTIMEFORMAT='%c ' history | bat"
alias watcha="watch "

# Python
alias uvr="uv run"
alias pycalc="python -qic 'from math import *; import cmath;'"

pyproject_scripts() {
    python -c "
import tomllib
from pathlib import Path
project = tomllib.loads(Path('pyproject.toml').read_text())
print('\n'.join(f'{k:<20} {v}' for k, v in project['project']['scripts'].items()))
"
}

# Rust
alias cr="cargo run --"
alias crq="cargo run -q --"
alias crb="cargo run --bin"
alias rustbt_on="export RUST_BACKTRACE=1"
alias rustbt_off="export RUST_BACKTRACE=0"
alias rustbt_full="export RUST_BACKTRACE=full"

# SSH
alias "ssh-keygen"="ssh-keygen -t ed25519"
alias scrat="screen -xRRS"

# Docker
alias dkdaemon="sudo systemctl start docker"
alias dklast="docker ps -la"
alias dkall="docker images -a && echo && docker ps -a"
dkbash() {
    docker container exec -i $(docker ps -lq) /bin/bash
}
dkkill() {
    docker kill $(docker ps -lq)
}

# Miscallaneous
view-source() {
    bat $(which $@)
}

nohupout() {
    nohup "$@" >/dev/null 2>&1 &
}


function br {
    local cmd cmd_file code
    cmd_file=$(mktemp)
    if broot --outcmd "$cmd_file" -sphd "$@"; then
        cmd=$(<"$cmd_file")
        command rm -f "$cmd_file"
        eval "$cmd"
    else
        code=$?
        command rm -f "$cmd_file"
        return "$code"
    fi
}
