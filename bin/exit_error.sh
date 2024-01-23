#! /bin/bash

tcprint error]$1 >&2
[[ -z $2 ]] || tcprint warn]Please report bugs to: $2 >&2
exit 1

