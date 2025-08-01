#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Select unicode characters from rofi"
CLI=(
    --prefix "args_"
    -o "character;Selected character"
    -f "force-generate;Force generating from scratch;;f"
    -f "run;Run in rofi;;r"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1


# Category mapping
declare -A categories=(
    ["Lu"]="uppercase letter"
    ["Ll"]="lowercase letter"
    ["Lt"]="titlecase letter"
    ["Lm"]="modifier letter"
    ["Lo"]="other letter"
    ["Mn"]="nonspacing mark"
    ["Mc"]="spacing mark"
    ["Me"]="enclosing mark"
    ["Nd"]="decimal number"
    ["Nl"]="letter number"
    ["No"]="other number"
    ["Pc"]="connector punctuation"
    ["Pd"]="dash punctuation"
    ["Ps"]="open punctuation"
    ["Pe"]="close punctuation"
    ["Pi"]="initial punctuation"
    ["Pf"]="final punctuation"
    ["Po"]="other punctuation"
    ["Sm"]="math symbol"
    ["Sc"]="currency symbol"
    ["Sk"]="modifier symbol"
    ["So"]="other symbol"
    ["Zs"]="space separator"
    ["Zl"]="line separator"
    ["Zp"]="paragraph separator"
    ["Cc"]="control"
    ["Cf"]="format"
    ["Cs"]="surrogate"
    ["Co"]="private use"
    ["Cn"]="unassigned"
)

DATA_DIR="${HOME}/.local/share/rofimenu-unicode"
SOURCE_DATA_FILE="${DATA_DIR}/UnicodeData.txt"
PROCESSED_DATA_FILE="${DATA_DIR}/unicode_processed.txt"
UNICODE_SOURCE_DATA_URL="https://www.unicode.org/Public/UCD/latest/ucd/UnicodeData.txt"

download_source() {
    set -e
    mkdir -p "$DATA_DIR"
    curl -sSL $UNICODE_SOURCE_DATA_URL -o "$SOURCE_DATA_FILE"
}

process_source_data() {
    set -e
    while IFS=';' read -r code name category _rest; do
        [[ "$category" != "Cc" && "$category" != "Cn" ]] || continue
        cat_name="${categories[$category]:-unknown}"
        char=$(printf "\u$code")
        printf '%s %s [%s] [%s]\n' "$char" "${name,,}" "$cat_name" "$code"
    done < "$SOURCE_DATA_FILE"
}

do_download=
do_process=
[[ -f "$SOURCE_DATA_FILE" ]] || do_download=1
[[ -f "$PROCESSED_DATA_FILE" ]] || do_process=1
[[ "$PROCESSED_DATA_FILE" -nt "$SOURCE_DATA_FILE" ]] || do_process=1
if [[ $args_force_generate ]]; then
    do_download=1
    do_process=1
fi

if [[ $do_download ]]; then
    printcolor -s ok "Downloading..." >&2
    download_source
fi

if [[ $do_process ]]; then
    printcolor -s ok "Processing..." >&2
    process_source_data > "$PROCESSED_DATA_FILE"
fi


extract_first_unicode() {
    set -e
    printf "%s" "$args_character" | python3 -c 'import sys; print(sys.stdin.read(1), end="")'
}

if [[ $args_run ]]; then
    rofi -show "unicode" -modes "unicode:$0"
    exit
fi

if [[ $args_character ]]; then
    char=$(extract_first_unicode "$args_character")
    printf "%s" "$char" | xsel -ib
    exit
fi

cat "$PROCESSED_DATA_FILE"
