#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] qbittorrent"
sudo pacman -Sy --noconfirm --needed qbittorrent

echo "[CONFIG] qbittorrent"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ qbittorrent
