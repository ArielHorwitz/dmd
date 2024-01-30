#! /usr/bin/bash

alias startup="~/.config/startup.sh"
alias resource="source ~/.bashrc" # Reread .bashrc
alias c="clear"
alias xo="xdg-open"
alias lsl="exa -l --group-directories-first --color=always"
alias lsa="exa -la --group-directories-first --color=always"
alias lsr="exa -laTR --group-directories-first --color=always"
alias cpi="cp -i"
alias tarz="tar -vzcf"
alias taru="tar -vkxf"
alias tarl="tar -tf"
alias rp="rhinopuffin"
alias i3windetails='xprop | grep -iE "wm_class|wm_window_role|wm_window_type|wm_name"'
alias historylog="HISTTIMEFORMAT='%c ' history | bat"

alias watcha="watch "

# Python
alias pyvenv="python -m venv venv && pyactivate"
alias pyactivate="source venv/bin/activate"
alias pipi="pip install --upgrade pip && [[ -f requirements.txt ]] && pip install -r requirements.txt"
alias py="python main.py"
alias pyflint="black --fast .; isort --profile black -l 88 .; flake8 --max-line-length 88 ."

# Rust
alias crun="cargo run --"
alias crunq="cargo run -q --"
alias crunb="cargo run --bin"
alias cclip="cargo clippy --"
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
view_source() {
    bat $(which $@)
}

set_wallpaper() {
    sudo cp -f $1 /usr/share/backgrounds/desktop.png
    feh --bg-fill --no-xinerama '/usr/share/backgrounds/desktop.png'
}

set_lockscreen() {
    sudo cp -f $1 /usr/share/backgrounds/lockscreen.png
}

batl() {
    bat -l log $@
}

