#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] alacritty"
sudo pacman -Sy --noconfirm --needed alacritty

echo "[CONFIG] alacritty"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ alacritty
