#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] kitty"
sudo pacman -Sy --noconfirm --needed kitty

echo "[CONFIG] kitty"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ kitty
