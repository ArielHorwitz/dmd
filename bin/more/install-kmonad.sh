#! /bin/bash

set -e

sudo echo "Root privileges aquired."
DATADIR=$PWD/`dirname "$0"`
TMPDIR="/tmp/install-kmonad/"
echo "Temporary working directory: $TMPDIR"
rm -rf $TMPDIR
mkdir -p $TMPDIR
cd $TMPDIR

# Download KMonad v0.4.2
URL="https://github.com/kmonad/kmonad/releases/download/0.4.2/kmonad"
echo "Downloading..."
echo "  $URL"
wget -q --output-document kmonad $URL
chmod +x kmonad
sudo mv kmonad /bin/kmonad

# Clean up
echo "Cleaning up temporary working directory $TMPDIR"
rm -rf $TMPDIR

