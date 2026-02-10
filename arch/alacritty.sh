#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] alacritty"
sudo pacman -Sy --noconfirm --needed alacritty

echo "[CONFIG] alacritty"
mkdir -p ~/.config/alacritty
cp -rf ./.config/alacritty/* ~/.config/alacritty/
