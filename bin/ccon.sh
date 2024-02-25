#! /bin/bash
set -e

APP_NAME=$(basename "$0")
ABOUT="Convert between hex and RGB."
CLI=(
    --prefix "args_"
    -C "colors;Colors to convert"
    -O "delimiter;Delimiter in RGB format;,;d"
    -f "from-rgb;Convert from RGB format instead of hex;;r"
    -f "leading-hash;Print leading hash in hex format;;l"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

[[ ${#args_delimiter} -gt 0 ]] || exit_error "Delimiter must be a single character"

rgb_to_hex() {
    [[ -z $args_leading_hash ]] || printf '#'
    printf "%02X%02X%02X" $1 $2 $3
}

hex_to_rgb() {
  if [[ $1 =~ ^#?([a-fA-F0-9]{6})$ ]]; then
    hex="${BASH_REMATCH[1]}"
    r=$((16#${hex:0:2}))
    g=$((16#${hex:2:2}))
    b=$((16#${hex:4:2}))
    printf "${r}${args_delimiter}${g}${args_delimiter}${b}"
  else
    echo "Invalid hex string $1"
  fi
}

convert_from_hex() {
    local hex
    for hex in ${args_colors[@]}; do
        hex_to_rgb $hex
        echo
    done
}

convert_from_rgb() {
    set -e
    local rgb
    for rgb in ${args_colors[@]}; do
        r=$(cut -d$args_delimiter -f1 <<< $rgb) || exit_error "Missing red value"
        g=$(cut -d$args_delimiter -f2 <<< $rgb) || exit_error "Missing green value"
        b=$(cut -d$args_delimiter -f3- <<< $rgb) || exit_error "Missing blue value"
        rgb_to_hex $r $g $b
        echo
    done
}

if [[ -n $args_from_rgb ]]; then
    convert_from_rgb
else
    convert_from_hex
fi

