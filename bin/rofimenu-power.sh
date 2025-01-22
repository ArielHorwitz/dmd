#! /bin/bash
set -e

print_options() {
	set -e
	echo "suspend"
	echo "hibernate"
	echo "poweroff"
	echo "reboot"
}

case "$1" in
	suspend   ) loginctl lock-session && systemctl suspend ;;
	hibernate ) systemctl hibernate ;;
	poweroff  ) systemctl poweroff ;;
	reboot    ) systemctl reboot ;;
	*         ) print_options ;;
esac
