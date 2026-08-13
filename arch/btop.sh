#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] btop htop"
sudo pacman -Sy --noconfirm --needed btop htop
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ btop

