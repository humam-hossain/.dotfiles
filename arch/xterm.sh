#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INFO] install xterm"
sudo pacman -Sy --noconfirm --needed xterm xorg-xrdb

echo "[INFO] copy config file"
cp -f .config/.Xresources $HOME
xrdb -merge ~/.Xresources
