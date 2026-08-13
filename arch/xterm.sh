#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INFO] install xterm"
sudo pacman -Sy --noconfirm --needed xterm xorg-xrdb

echo "[INFO] copy config file"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ xterm
xrdb -merge ~/.Xresources
