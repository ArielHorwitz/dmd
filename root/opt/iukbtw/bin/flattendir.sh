#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <nested-dir> [--clean]" >&2
  exit 1
fi

set -e

echo "Flattening: $1"
find $1 -mindepth 2 -type f -exec mv --backup=numbered -t $1 '{}' +
echo "Flat."

if [[ $2 = "--clean" ]] ; then
  echo "Cleaning up..."
  rm -f $1/*~
  find $1 -mindepth 1 -type d -exec rm -rf '{}' +
fi

