#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] yazi"
sudo pacman -Sy --noconfirm --needed yazi

echo "[CONFIG] copying yazi config"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ yazi
