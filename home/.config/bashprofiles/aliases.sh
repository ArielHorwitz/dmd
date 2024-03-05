#! /usr/bin/bash

unalias -a

alias startup="~/.config/startup.sh"
alias resource="source ~/.bashrc" # Reread .bashrc
alias c="clear"
alias xo="xdg-open"
alias cpi="cp -i"
alias tarz="tar -vzcf"
alias taru="tar -vkxf"
alias tarl="tar -tf"
alias rp="rhinopuffin"
alias gp="geckopanda"
alias oa="openassistant -q"
alias oam="openassistant 0 | markdown"

alias ls='ls --color=auto'
alias grep='grep --colour=auto'
alias egrep='egrep --colour=auto'
alias fgrep='fgrep --colour=auto'

alias historylog="HISTTIMEFORMAT='%c ' history | bat"
alias watcha="watch "

# Python
alias pyvenv="python -m venv venv && pyactivate"
alias pyactivate="source venv/bin/activate"
alias pipi="pip install --upgrade pip && [[ -f requirements.txt ]] && pip install -r requirements.txt"
alias py="python main.py"
alias pyflint="black --fast .; isort --profile black -l 88 .; flake8 --max-line-length 88 ."

# Rust
alias cr="cargo run --"
alias crq="cargo run -q --"
alias crf="cargo fmt; cargo run -q --"
alias rustbt_on="export RUST_BACKTRACE=1"
alias rustbt_off="export RUST_BACKTRACE=0"
alias rustbt_full="export RUST_BACKTRACE=full"
alias baconm="bacon clippy -- --"\
" --warn clippy::panic"\
" --warn clippy::unwrap_used"\
" --warn clippy::unwrap_in_result"\
" --warn clippy::str_to_string"\
" --warn clippy::verbose_file_reads"\
""
#" --warn clippy::indexing_slicing"\

# SSH
alias keygen="ssh-keygen -t ed25519 -C 'ariel.ninja' && cat ~/.ssh/id_ed25519.pub"
alias sshadd="eval '$(ssh-agent -s)' && ssh-add ~/.ssh/id_ed25519.pub"

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

blog() {
    bat -l log $@
}

mkcd() {
    mkdir -p $1 && cd $1
}

cdl() {
    cd $1 && lsl
}

starttest() {
    rm -rf /tmp/terminaltest
    mkcd /tmp/terminaltest
    tcprint "debug]Empty test directory."
}
