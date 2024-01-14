#!/bin/bash

set -e

# Create cli and parse arguments
spongecrab_args=$(
    CLI="nested target -f force -f verbose"
    NAME="flattendir"
    ABOUT="Recursively copy files from directory to a flat directory."
    spongecrab $CLI --name $NAME --about "$ABOUT" -- $@
) || { echo $spongecrab_args; exit 1 # Print help or errors and quit
}; eval $spongecrab_args # Evaluate results

# Verify arguments and prepare target dir
[[ -d $nested ]] || { tcprint "error]'$nested' is not a directory"; exit 1; }
[[ -d $target ]] && [[ -z $force ]] && {
    tcprint "error]'$target' already exists (override using --force)"
    exit 1
}
[[ -d $target ]] && rm -rf $target || true
[[ -n $verbose ]] && verbose="--verbose" || true
mkdir $target

# Flatten
[[ -n $verbose ]] && tcprint "debug]Flattening: '$nested' => '$target'" || true
find $nested -type f -exec cp $verbose --backup=numbered -t $target '{}' +
[[ -n $verbose ]] && tcprint "ok]Flattened." || true

