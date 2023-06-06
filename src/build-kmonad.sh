#!/bin/bash

set -e

sudo systemctl start docker

# Build the Docker image which will contain the binary.
docker build -t kmonad-builder git://github.com/kmonad/kmonad.git

# Spin up an ephemeral Docker container from the built image, to just copy the
# built binary to the host's current directory bind-mounted inside the
# container at /host/.
mkdir --parents "opt/bin/"
docker run --rm -it -v ${PWD}:/host/ kmonad-builder bash -c 'cp -vfp /root/.local/bin/kmonad /host/opt/bin/'

# Clean up build image, since it is no longer needed.
docker rmi kmonad-builder
