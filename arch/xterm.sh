#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INFO] install xterm"
sudo pacman -Sy --noconfirm --needed xterm xorg-xrdb

echo "[INFO] copy config file"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ xterm
xrdb -merge ~/.Xresources
