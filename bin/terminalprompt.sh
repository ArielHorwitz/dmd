#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "${0%.*}")
ABOUT="Spawn a terminal and prompt the user for text."
CLI=(
    --prefix "args_"
    -o "prompt-text;Prompt text"
    -O "width;Terminal width;1500;W"
    -O "height;Terminal height;70;H"
    -O "size;Terminal text size;25;s"
    -O "background;Terminal text background color;'#000022';b"
    -O "foreground;Terminal text foreground color;'#0088cc';f"
    -O "prompt-title;Title for prompt terminal;Text prompt;T"
    -e "textprompt_args;Arguments for textprompt script"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1


temp_file=$(mktemp)
terminal_window_class="terminal-userprompt"
bash_command="printf '$args_prompt_text'; textprompt ${args_textprompt_args[@]} > $temp_file"
alacritty_args=(
    --title "$args_prompt_title"
    -o "font.size=$args_size"
    -o "colors.primary.background='$args_background'"
    -o "colors.primary.foreground='$args_foreground'"
    --class $terminal_window_class
    --command bash -c "$bash_command"
)

alacritty "${alacritty_args[@]}" &

alacritty_pid=$!
alacritty_wid=
while [[ -z $alacritty_wid ]]; do
    alacritty_wid=$(xdotool search --pid "$alacritty_pid" || :)
    sleep 0.05
done

i3-msg "[class=$terminal_window_class] floating enable; border pixel 2" >/dev/null
sleep 0.05
xdotool windowsize $alacritty_wid $args_width $args_height
i3-msg "[class=$terminal_window_class] move position center" >/dev/null

while ps -p $alacritty_pid >/dev/null; do sleep 0.05; done
printf "%s" "$(< $temp_file)"
rm -f $temp_file
