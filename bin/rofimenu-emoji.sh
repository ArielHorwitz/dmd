#! /bin/bash
set -e

DATA_DIR="${HOME}/.local/share/rofimenu-emoji"
EMOJIS_DATA="${DATA_DIR}/emojis.json"

# CLI
APP_NAME=$(basename "$0")
ABOUT="Select emojis from rofi"
CLI=(
    --prefix "args_"
    -o "emoji;Selected emoji"
    -f "update;Update emoji data"
    -f "run;Run in rofi;;r"
    -O "mode;Mode of descriptions [full, tags, groups, labels];full;m"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

if [[ $args_update ]] || [[ ! -f "$EMOJIS_DATA" ]] ; then
    mkdir -p "$DATA_DIR"
    curl -sSL https://www.emoji.family/api/emojis -o "$EMOJIS_DATA"
    printcolor -s ok "Updated emojis: $EMOJIS_DATA" >&2
fi

if [[ $args_run ]]; then
    rofi -show "emoji" -modes "emoji:$0"
    exit
fi

if [[ $args_emoji ]]; then
    emoji=$(printf "%s" "$args_emoji" | awk '{ printf "%s", $1 }')
    printf '%s' "$emoji" | xsel -ib
    exit
fi

case $args_mode in
    full   ) jq_filter='.[] | .emoji + "  " + .annotation + " [" + .group + " / " + .subgroup + "]  " + (.tags | .? | map("#" + .) | join(" "))'  ;;
    tags   ) jq_filter='.[] | .emoji + "  " + .annotation + " " + (.tags | .? | map("#" + .) | join(" "))'  ;;
    groups ) jq_filter='.[] | .emoji + "  " + .annotation + " [" + .group + " / " + .subgroup + "]"'  ;;
    labels ) jq_filter='.[] | .emoji + "  " + .annotation'  ;;
    *      ) exit_error "Unknown mode: $args_mode"
esac

jq -r "$jq_filter" < "$EMOJIS_DATA"
