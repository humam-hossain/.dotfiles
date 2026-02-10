#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] waybar"
sudo pacman -Sy --noconfirm waybar

echo "[INSTALL] jq bc"
sudo pacman -Sy --noconfirm --needed jq bc
yay -Sy --noconfirm --needed smem

echo "[CONFIG] waybar"
mkdir -p ~/.config/waybar
cp -rf .config/waybar/* ~/.config/waybar/
