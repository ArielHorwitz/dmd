#! /bin/bash
set -e

VERSION="2.46.0"
tarfile="gh_${VERSION}_linux_amd64.tar.gz"
tardir="gh_${VERSION}_linux_amd64"

if [[ ! -f /tmp/$tarfile ]]; then
    printcolor -ns ok "Downloading: "; echo $tarfile
    curl -L https://github.com/cli/cli/releases/download/v${VERSION}/${tarfile} -o /tmp/$tarfile
else
    printcolor -ns notice "Using existing archive: "; echo /tmp/$tarfile
fi

printcolor -s ok "Extracting archive"
tar -xf /tmp/$tarfile -C /tmp

printcolor -s ok "Installing binary and man pages"
sudo cp -r /tmp/$tardir/bin/* /bin
cp -r /tmp/$tardir/share $HOME/.local/share

printcolor -s ok "Cleaning up"
rm -r /tmp/$tardir

printcolor -ob -ou -fg "Installed:"
gh --version
