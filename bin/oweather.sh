#! /bin/bash

set -e

CACHE_DIR=$HOME/.local/share/oweather
DEFAULT_DISPLAY_COLOR='255_150_220'

# Command line interface (based on `spongecrab --generate`)
APP_NAME=$(basename "$0")
ABOUT="Get weather from https://openweathermap.org OneCall API 3.0"
# Argument syntax: "<arg_name>;<help_text>;<default_value>;<short_name>"
CLI=(
    -o "display;Display mode: summary,json,none;summary"
    -O "display_color;Color in summary;$DEFAULT_DISPLAY_COLOR"
    -f "nocolor;Disable color in summary"
    -f "nounits;Disable units in summary"
    -f "noicons;Disable icons in summary"
    -O "cache_timeout;How long is the cache valid in seconds;600;t"
    -f "force;Ignore existing cached response;;f"
    -f "verbose;Print details to stderr;;v"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
eval "$CLI" || exit 1

# Configuration
config_file=$HOME/.config/${APP_NAME}/config.toml
config_keys=(_api_key _lat _lon)
config_default='
# api_key = \"<YOUR_API_KEY>\"
# lat = 0.0
# lon = 0.0
'
tt_out=$(mktemp 'tt_out.XXXXXXXXXX'); tt_err=$(mktemp 'tt_err.XXXXXXXXXX'); tigerturtle -WD "$config_default" -p "config__" $config_file -- ${config_keys[@]} >$tt_out 2>$tt_err && { eval $(<$tt_out); rm $tt_out; rm $tt_err; } || { echo "$(<$tt_err)" >&2; rm $tt_out; rm $tt_err; exit 1; }


display_color=$(echo $display_color | sed 's/_/;/g')

# Cache
[[ -d $CACHE_DIR ]] || mkdir -p $CACHE_DIR
response_cache=$CACHE_DIR/response.json

# API call parameters
exclude=
apipoint="https://api.openweathermap.org/data/3.0/onecall"
url="$apipoint?units=metric&lat=$config__lat&lon=$config__lon&exclude=$exclude&appid=$config__api_key"

[[ -z $verbose ]] || echo "Calling: $url" 1>&2

is_cache_valid() {
    [[ -z $force ]] || return 1
    [[ -f "$response_cache" ]] || return 1
    current_time=$(date +%s)
    last_update=$(stat -c %Y "$response_cache")
    elapsed_time=$((current_time - last_update))
    [[ -z $verbose ]] || echo "Cache age: $elapsed_time / $cache_timeout" 1>&2
    return $((elapsed_time > cache_timeout))
}

if is_cache_valid ; then
    [[ -z $verbose ]] || echo "Valid cached response exists" 1>&2
else
    [[ -z $verbose ]] || echo "Updating cache" 1>&2
    curl --silent --connect-timeout 10 $url > "$response_cache"
    touch "$response_cache" # Update timestamp
fi

[[ -z $verbose ]] || printf "$(< $response_cache)\n" 1>&2


display_summary() {
    color="\e[38;2;${display_color}m"
    faded="\e[38;2;128;128;128m"
    reset="\e[0m"
    if [[ $nocolor ]]; then
        color=""
        faded=""
        reset=""
    fi
    # temp
    temp=$(jq '.current.temp' "$response_cache")
    [[ -n $noicons ]] || printf "${color}${reset}"
    printf "%.0f" "$temp"
    [[ -n $nounits ]] || printf "${faded}${reset}"
    # wind
    printf " "
    wind=$(jq '.current.wind_speed' "$response_cache")
    [[ -n $noicons ]] || printf "${color}${reset} "
    printf "$wind"
    [[ -n $nounits ]] || printf " ${faded}km/h${reset}"
    # pres
    printf " "
    pres=$(jq '.current.pressure' "$response_cache")
    [[ -n $noicons ]] || printf "${color}${reset}"
    printf "$pres"
    [[ -n $nounits ]] || printf " ${faded}hPa${reset}"
    # humidity
    printf " "
    [[ -n $noicons ]] || printf "${color}${reset}"
    hum=$(jq '.current.humidity' "$response_cache")
    printf "$hum"
    [[ -n $nounits ]] || printf "${faded}%%${reset}"
    # visibility
    printf " "
    [[ -n $noicons ]] || printf "${color} ${reset}"
    vis=$(jq '.current.visibility' "$response_cache")
    printf "%.1f" "$((vis / 1000))"
    [[ -n $nounits ]] || printf " ${faded}km${reset}"
    # desc
    printf " "
    desc=$(jq '.current.weather[0].description' "$response_cache" | xargs)
    printf "[${color}$desc${reset}]\n"
}

case $display in
    summary)   display_summary ;;
    json)      cat "$response_cache" ;;
    current)   jq '.current' "$response_cache" ;;
    hourly)    jq ".hourly[0]" "$response_cache" ;;
    daily)     jq '.daily[0]' "$response_cache" ;;
    none)      ;;
    *)         echo "unknown display mode: '$display'" ;;
esac

