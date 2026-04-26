#! /bin/bash
set -e

APP_NAME=$(basename "${0%.*}")
ABOUT="Pick an icon name from an installed theme via fuzzel and load into clipboard"
CLI=(
    --prefix "args_"
    -O "theme;Icon theme to browse (skips theme picker);;t"
    -f "no-inherit;Skip inherited themes"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

ICON_SEARCH_PATHS=(
    "$HOME/.local/share/icons"
    "$HOME/.icons"
    "/usr/local/share/icons"
    "/usr/share/icons"
)

theme_dirs_for() {
    local theme=$1
    local found=0
    for base in "${ICON_SEARCH_PATHS[@]}"; do
        if [[ -d "$base/$theme" ]]; then
            printf '%s\n' "$base/$theme"
            found=1
        fi
    done
    (( found )) || return 1
}

list_installed_themes() {
    for base in "${ICON_SEARCH_PATHS[@]}"; do
        [[ -d $base ]] || continue
        find "$base" -mindepth 2 -maxdepth 2 -name index.theme -printf '%h\n' 2>/dev/null
    done | xargs -I{} basename {} | sort -u
}

inheritance_chain() {
    local start=$1
    local -A visited=()
    local queue=("$start")
    local chain=()
    while (( ${#queue[@]} > 0 )); do
        local current=${queue[0]}
        queue=("${queue[@]:1}")
        [[ -z ${visited[$current]:-} ]] || continue
        visited[$current]=1
        chain+=("$current")
        local line=""
        while IFS= read -r dir; do
            [[ -f "$dir/index.theme" ]] || continue
            line=$(grep -E '^Inherits=' "$dir/index.theme" | head -1 | cut -d= -f2-) || true
            [[ -n $line ]] && break
        done < <(theme_dirs_for "$current")
        [[ -n $line ]] || continue
        local IFS=','
        read -ra parents <<< "$line"
        for p in "${parents[@]}"; do
            p=${p// /}
            [[ -n $p ]] && queue+=("$p")
        done
    done
    [[ -n ${visited[hicolor]:-} ]] || chain+=("hicolor")
    printf '%s\n' "${chain[@]}"
}

collect_icon_names() {
    local theme=$1
    while IFS= read -r dir; do
        find "$dir" -type f \( -name '*.svg' -o -name '*.png' -o -name '*.xpm' \) -printf '%f\n' 2>/dev/null \
            | sed 's/\.[^.]*$//'
    done < <(theme_dirs_for "$theme") | sort -u | awk -v t="$theme" '{ printf "%s\t%s\n", $0, t }'
}

if [[ -z $args_theme ]]; then
    args_theme=$(list_installed_themes | fuzzel --dmenu --prompt "theme > " --mesg "Pick an icon theme") || exit 0
    [[ -n $args_theme ]] || exit 0
fi

theme_dirs_for "$args_theme" > /dev/null || {
    msg="theme not found: $args_theme"
    printf 'icon-picker: %s\n' "$msg" >&2
    notify-send --urgency=critical "icon-picker" "$msg" 2>/dev/null || :
    exit 1
}

if [[ $args_no_inherit ]]; then
    themes=("$args_theme")
else
    mapfile -t themes < <(inheritance_chain "$args_theme")
fi

selection=$(
    for t in "${themes[@]}"; do collect_icon_names "$t"; done \
        | awk -F'\t' '!seen[$1]++' \
        | sort -f \
        | awk -F'\t' '{ printf "%s (%s)\0icon\x1f%s\n", $1, $2, $1 }' \
        | fuzzel --dmenu --icon-theme="$args_theme" --mesg "Pick an icon and copy name to clipboard (theme: $args_theme)"
) || exit 0
[[ -n $selection ]] || exit 0

icon_name=${selection% (*)}
printf '%s' "$icon_name" | clipcatctl load
