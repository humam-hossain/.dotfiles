#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] rofi"
sudo pacman -Sy --noconfirm --needed rofi

echo "[CONFIG] rofi"
mkdir -p ~/.config/rofi
cp -rf .config/rofi/* ~/.config/rofi/
