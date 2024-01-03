#! /bin/bash

if [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
    echo "
Print with formatting using iukformat.

USAGE: tcprint OPTIONS]TEXT

# EXAMPLES
tcprint error]Error encountered!
tcprint debug]Processing entries...
tcprint black red bu]Black on red, bold and underline text.
"
    exit 1
fi

raw=$@
if [[ $raw == *']'* ]]; then
    options=$(echo "$raw" | cut -d']' -f1)
    text=$(echo "$raw" | cut -d']' -f2-)
else
    options=""
    text="$raw"
fi
format=$(tcformat $options)
printf $format "$text"
# debugging
# echo raw: \"$raw\"
# echo opt: \"$options\"
# echo txt: \"$text\"
# echo fmt: \"$format\"

