#! /bin/bash
set -e

LOGDIR=/tmp/logs-$USER
DISPLAYS_FILE=$HOME/.config/hardware/displays

APP_NAME=$(basename "$0")
ABOUT='Move between desktops of i3 workspaces.'
CLI=(
    --prefix "args_"
    -p "desktop;Desktop index"
    -f "move;Move focused element to desktop index;;m"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

mapfile -t displays < $DISPLAYS_FILE
desktop_index=$args_desktop
workspaces=(
    ${desktop_index}1
    ${desktop_index}2
    ${desktop_index}3
)

echo displays: ${displays[@]}
echo workspaces: ${workspaces[@]}

if [[ -n $args_move ]]; then
    i3-msg "move to workspace ${workspaces[1]}"
else
    switch_command=(
        focus output ${displays[0]}\; workspace ${workspaces[0]}\;
        focus output ${displays[1]}\; workspace ${workspaces[1]}\;
        focus output ${displays[2]}\; workspace ${workspaces[2]}\;
        focus output ${displays[1]}\;
    )
    i3-msg "${switch_command[@]}"
fi
