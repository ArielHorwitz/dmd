#! /bin/bash
set -e

HIST=~/.cache/run-menu-history
mkdir -p "$(dirname "$HIST")"
touch "$HIST"

cmd=$(fuzzel --dmenu --prompt '$ ' --mesg "Run a command" < "$HIST")
[[ -n $cmd ]] || exit 0

{ printf '%s\n' "$cmd"; grep -vxF -- "$cmd" "$HIST" || :; } > "$HIST.tmp"
mv "$HIST.tmp" "$HIST"

setsid -f sh -c "$cmd"
