#!/usr/bin/bash

# Git clone a single directory from a repo

set -e

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <clone-url> <repo-dir> <download-dir> [--delete]" >&2
  exit 1
fi

# Create temporary working directory
TMPDIR=/tmp/clonedir/
echo "Creating temporary directory: $TMPDIR"
rm -rf $TMPDIR
mkdir -p $TMPDIR

# Clone
echo "Cloning: $1"
git clone --quiet --no-checkout --depth=1 --filter=tree:0 $1 $TMPDIR
cd $TMPDIR
git sparse-checkout set --quiet --no-cone $2
echo "Sparse checkout: $2"
git checkout

# Move files to download directory
[[ $4 = "--delete" ]] && echo "Deleting: $3" && rm -rf $3
mkdir -p $3
echo "Moving files to: $3"
mv $2 $3

# Clean up temporary files
echo "Cleaning up..."
rm -rf $TMPDIR

