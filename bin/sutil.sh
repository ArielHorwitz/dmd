#! /bin/bash

if [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
    echo "
sutil - Scripting utilities for bash.

USAGE: source sutil [MAINTAINER]
"
    exit 1
fi

# Short-circuit if sourced already
[[ $SUTIL_SOURCED ]] && return 0

# Debug to console using ifprint.
sdebug() { [[ -n $SUTIL_DEBUG ]] && ifprint debug]$@; }

# Debug to console using ifprint.
sdebug_enabled() { [[ -n $SUTIL_DEBUG ]] }

# Exit with message and error code
exit_with_error() {
    cprint error]$1
    cprint warn]Please report bugs to: $MAINTAINER
    exit 1
}

# Return with message and error code
return_with_error() {
    cprint error]$1
    cprint warn]Please report bugs to: $MAINTAINER
    return 1
}

# Prompt the user for yes/no. Defaults to no.
prompt_ask() {
    options=$1
    [[ -n $2 ]] && timeout="-t $2"
    printf "\e[35m(y/N)\e[37;2m[$options/$2]\e[0m "
    read $timeout -n 1 answer
    [[ $options != *n* ]] && [[ -n $answer ]] && echo
    # Accept
    [[ "yY" == *$answer* ]] && [[ -n $answer ]] && return 0
    # Deny
    [[ $options == *q* ]] && exit 1
    return 1
}

# Prompt the user for yes/no. Defaults to yes.
prompt_confirm() {
    options=$1
    [[ -n $2 ]] && timeout="-t $2"
    # Prompt
    printf "\e[35mContinue? (Y/n)\e[37;2m[$options/$2]\e[0m "
    read $timeout -n 1 answer
    # Newline
    [[ $options != *n* ]] && [[ -n $answer ]] && echo
    # Deny
    if [[ "nN" == *$answer* ]] && [[ -n $answer ]]; then
        [[ $options == *q* ]] && exit 1
        return 1
    fi
    # Accept
    return 0
}

# Exit with error if a variable has no value
assert_var() {
    [[ -z ${1} ]] || exit_with_error "Missing \"$1\" environment variable."
    return 0
}

srcenv() {
    sdebug "Sourcing env: ~/.iukenv"
    source "~/.iukenv" || exit_with_error "Failed to source ~/.iukenv"
    ALL_NAMES="$@"
    sdebug "Checking sourced: $ALL_NAMES"
    while [[ -n $@ ]]; do
        [[ -z $1 ]] && break
        NAME=$1
        VALUE=${!1}
        shift
        sdebug "Exporting $NAME: $VALUE"
        assert_var $NAME
        export ${NAME}=$VALUE
    done
    sdebug "Sourced environment variables"
    return 0
}

printnuenv() {
    cset debug
    printenv | sort | grep IUK
    creset
    return 0
}

can_file() {
    [[ ! -e $1 ]] || [[ -f $1 ]]
}

try_cd() {
    cd $1 || exit_with_error "Failed to change to directory: $1"
    sdebug "Changed directory: $1"
    return 0
}

all_colors() {
    for i in {0..255}; do
        printf '\e[%sm %s \e[m' "$i" "$i"
        [[ $(expr $i % 10) = 9 ]] && printf "\n"
    done

    echo
}

# Set maintainer
[[ -n $1 ]] && MAINTAINER=$1 && shift 1
if [[ -z $MAINTAINER ]]; then
    MAINTAINER="<unknown maintainer>"
    tcprint notice]Maintainer unknown.
fi

SUTIL_SOURCED=1

