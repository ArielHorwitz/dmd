#! /bin/bash
set -e

# CLI
APP_NAME=$(basename "$0")
ABOUT="Set power mode from rofi"
CLI=(
    --prefix "args_"
    -o "mode;Power mode"
    -f "run;Run in rofi;;r"
)
CLI=$(spongecrab --name "$APP_NAME" --about "$ABOUT" "${CLI[@]}" -- "$@") || exit 1
# echo "$CLI" >&2
eval "$CLI" || exit 1

if [[ $args_run ]]; then
    rofi -show "power" -modes "power:$0"
fi

case "$args_mode" in
    suspend   ) nohup hyprlock & sleep 1 && systemctl suspend ;;
    hibernate ) systemctl hibernate ;;
    poweroff  ) systemctl poweroff ;;
    reboot    ) systemctl reboot ;;
    *         )
        echo "suspend"
        echo "hibernate"
        echo "poweroff"
        echo "reboot"
        ;;
esac
