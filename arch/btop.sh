#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] btop htop"
sudo pacman -Sy --noconfirm --needed btop htop
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ btop

