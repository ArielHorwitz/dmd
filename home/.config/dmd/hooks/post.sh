#! /bin/bash
set -e

systemctl --user daemon-reload
systemctl --user enable --now check-updates.timer
