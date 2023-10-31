#! /usr/bin/bash
#
# ~/.bashrc
#

# Aliases
alias resource="source ~/.bashrc" # Reread .bashrc
alias xo="xdg-open"
alias lsl="exa -l --group-directories-first"
alias lsa="exa -la --group-directories-first"
alias lsr="exa -lR --group-directories-first --git-ignore"
alias cpi="cp -i"
alias i3windetails='xprop | grep -iE "wm_class|wm_window_role|wm_window_type|wm_name"'
alias historylog="HISTTIMEFORMAT='%c ' history | bat"

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
" --warn clippy::indexing_slicing"\
""

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

# shopt
shopt -s histappend
shopt -s expand_aliases
shopt -s checkwinsize  # https://tiswww.case.edu/php/chet/bash/FAQ (E11)


# ---------------------------------------------------------

[[ $- != *i* ]] && return

colors() {
	local fgc bgc vals seq0

	printf "Color escapes are %s\n" '\e[${value};...;${value}m'
	printf "Values 30..37 are \e[33mforeground colors\e[m\n"
	printf "Values 40..47 are \e[43mbackground colors\e[m\n"
	printf "Value  1 gives a  \e[1mbold-faced look\e[m\n\n"

	# foreground colors
	for fgc in {30..37}; do
		# background colors
		for bgc in {40..47}; do
			fgc=${fgc#37} # white
			bgc=${bgc#40} # black

			vals="${fgc:+$fgc;}${bgc}"
			vals=${vals%%;}

			seq0="${vals:+\e[${vals}m}"
			printf "  %-9s" "${seq0:-(default)}"
			printf " ${seq0}TEXT\e[m"
			printf " \e[${vals:+${vals+$vals;}}1mBOLD\e[m"
		done
		echo; echo
	done
}

use_color=true

# Set colorful PS1 only on colorful terminals.
# dircolors --print-database uses its own built-in database
# instead of using /etc/DIR_COLORS.  Try to use the external file
# first to take advantage of user additions.  Use internal bash
# globbing instead of external grep binary.
safe_term=${TERM//[^[:alnum:]]/?}   # sanitize TERM
match_lhs=""
[[ -f ~/.dir_colors   ]] && match_lhs="${match_lhs}$(<~/.dir_colors)"
[[ -f /etc/DIR_COLORS ]] && match_lhs="${match_lhs}$(</etc/DIR_COLORS)"
[[ -z ${match_lhs}    ]] \
	&& type -P dircolors >/dev/null \
	&& match_lhs=$(dircolors --print-database)
[[ $'\n'${match_lhs} == *$'\n'"TERM "${safe_term}* ]] && use_color=true

if ${use_color} ; then
	# Enable colors for ls, etc.  Prefer ~/.dir_colors #64489
	if type -P dircolors >/dev/null ; then
		if [[ -f ~/.dir_colors ]] ; then
			eval $(dircolors -b ~/.dir_colors)
		elif [[ -f /etc/DIR_COLORS ]] ; then
			eval $(dircolors -b /etc/DIR_COLORS)
		fi
	fi

	if [[ ${EUID} == 0 ]] ; then
		PS1='\[\033[01;31m\][\h\[\033[01;36m\] \W\[\033[01;31m\]]\$\[\033[00m\] '
	else
		PS1='\[\e[0;34m\]╌╌╌\[\e[0;35m\] \u@\H\[\e[01;36m\] \w \[\e[0;34m\]╌╌╌\[\e[m\]\n\[\e[1;32m\]\$\[\e[0m\] '
	fi

	alias ls='ls --color=auto'
	alias grep='grep --colour=auto'
	alias egrep='egrep --colour=auto'
	alias fgrep='fgrep --colour=auto'
else
	if [[ ${EUID} == 0 ]] ; then
		# show root@ when we don't have colors
		PS1='\u@\h \W \$ '
	else
		PS1='\u@\h \w \$ '
	fi
fi

unset use_color safe_term match_lhs sh

# xhost +local:root > /dev/null 2>&1

#
# # ex - archive extractor
# # usage: ex <file>
ex ()
{
  if [ -f $1 ] ; then
    case $1 in
      *.tar.bz2)   tar xjf $1   ;;
      *.tar.gz)    tar xzf $1   ;;
      *.bz2)       bunzip2 $1   ;;
      *.rar)       unrar x $1     ;;
      *.gz)        gunzip $1    ;;
      *.tar)       tar xf $1    ;;
      *.tbz2)      tar xjf $1   ;;
      *.tgz)       tar xzf $1   ;;
      *.zip)       unzip $1     ;;
      *.Z)         uncompress $1;;
      *.7z)        7z x $1      ;;
      *)           echo "'$1' cannot be extracted via ex()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}
