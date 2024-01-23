#! /bin/bash

[[ -n $1 ]] && [[ $1 -ne 0 ]] && timeout="-t $1" && timeout_indicator="[$1s]"
[[ -n $2 ]] && prompt="$2" || prompt="Continue?"
# Prompt
printf "%s \e[35m(Y/n)\e[2;37m%s\e[0m " "$prompt" "$timeout_indicator"
read $timeout -n 1 answer || answer_timeout=1
[[ $answer_timeout -eq 1 ]] && echo
[[ $answer_timeout -eq 0 ]] && [[ -n $answer ]] && echo
# Deny
[[ "nN" == *$answer* ]] && [[ -n $answer ]] && exit 1
# Accept
exit 0

