#!/bin/bash

set -e
snakeviz --version

ARGV=( "$@" )
FILE_NAME="$1.prof"
COMMAND=$2
PRE_COMMAND=$3
POST_COMMAND=$4

$PRE_COMMAND
python -m cProfile -o $FILE_NAME $COMMAND
$POST_COMMAND
$PRE_COMMAND
time $2
$POST_COMMAND
echo
snakeviz -s $FILE_NAME
