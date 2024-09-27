#! /bin/bash

unalias -a

alias resource="source ~/.bashrc" # Reread .bashrc
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

alias ls='ls --color=auto'
alias grep='grep --colour=auto'
alias egrep='egrep --colour=auto'
alias fgrep='fgrep --colour=auto'
alias printenv='printenv | sort'

alias historylog="HISTTIMEFORMAT='%c ' history | bat"
alias watcha="watch "

# Python
alias pyactivate="source venv/bin/activate"
alias pipr="pip install -r requirements.txt"
alias py="python main.py"

# Rust
alias cr="cargo run --"
alias crq="cargo run -q --"
alias crb="cargo run --bin"
alias rustbt_on="export RUST_BACKTRACE=1"
alias rustbt_off="export RUST_BACKTRACE=0"
alias rustbt_full="export RUST_BACKTRACE=full"

# SSH
alias "ssh-keygen"="ssh-keygen -t ed25519"

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

set-wallpaper() {
    sudo cp -f $1 /usr/share/backgrounds/desktop.png
    feh --bg-fill --no-xinerama '/usr/share/backgrounds/desktop.png'
}

set-lockscreen() {
    sudo cp -f $1 /usr/share/backgrounds/lockscreen.png
}

mkcd() {
    mkdir -p $1 && cd $1
}

cdre() {
    cd $PWD
}

cdl() {
    cd $1 && lsl
}

starttest() {
    mkcd /tmp/terminaltest-$RANDOM
    printcolor -s debug "New test directory."
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
