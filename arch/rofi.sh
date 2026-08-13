#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] rofi"
sudo pacman -Sy --noconfirm --needed rofi

echo "[CONFIG] rofi"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ rofi
