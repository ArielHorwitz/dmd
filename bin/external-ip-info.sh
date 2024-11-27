#! /bin/bash
set -e

info=$(curl -sSL 'https://ipinfo.io/json')

ip=$(echo "$info" | jq -r '.ip')
org=$(echo "$info" | jq -r '.org')

printcolor -nfm "$ip"
printcolor -nfy -ob " @ "
printcolor -nfc "$org"
echo
