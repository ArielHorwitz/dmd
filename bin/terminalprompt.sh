#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Spawn a terminal and prompt the user for text."
CLI=(
    --prefix "args_"
    -o "prompt-text;Prompt text"
    -O "width;Terminal width;1500;W"
    -O "height;Terminal height;50;H"
    -O "size;Terminal text size;25;s"
    -O "background;Terminal text background color;'#000022';b"
    -O "foreground;Terminal text foreground color;'#0088cc';f"
    -O "prompt-title;Title for prompt terminal;Text prompt;T"
    -f "hide;Hide input text"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1


temp_file=$(mktemp)
terminal_window_class="terminal-userprompt-$RANDOM-_make_window_float_"
[[ -z $args_hide ]] || read_args='-s'

bash_command="printf '$args_prompt_text'; read $read_args buffer; printf \"\$buffer\" > $temp_file"
alacritty_args=(
    --title "$args_prompt_title"
    -o "font.size=$args_size"
    -o "colors.primary.background='$args_background'"
    -o "colors.primary.foreground='$args_foreground'"
    --class "$terminal_window_class"
    --command bash -c "$bash_command"
)

alacritty "${alacritty_args[@]}" &
alacritty_pid=$!

while [[ ! $(hyprctl clients -j | jq -r '.[].class' | grep "$terminal_window_class") ]]; do
    sleep 0.05
done

hyprctl dispatch focuswindow "initialclass:$terminal_window_class" >/dev/null
hyprctl dispatch setfloating >/dev/null
hyprctl dispatch resizeactive exact "$args_width" "$args_height" >/dev/null
hyprctl dispatch centerwindow >/dev/null

while ps -p $alacritty_pid >/dev/null; do sleep 0.05; done
printf "%s" "$(< "$temp_file")"
rm -f "$temp_file"
