#! /bin/bash
set -e

DATADIR=$PWD/`dirname "$0"`

# Show tty shell in selection menu
sudo sed -i "s;include_tty_shell = false;include_tty_shell = true;" /etc/lemurs/config.toml

# Add i3 in selection menu
echo "#! /bin/sh
exec i3" | sudo tee /etc/lemurs/wms/i3
sudo chmod 755 /etc/lemurs/wms/i3

# Enable the systemd service
sudo systemctl disable display-manager.service
sudo systemctl enable lemurs.service
