#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] kitty"
sudo pacman -Sy --noconfirm --needed kitty

echo "[CONFIG] kitty"
cd "$(dirname "${BASH_SOURCE[0]}")/../restow" && stow --verbose=5 --no-folding -t ~ kitty
