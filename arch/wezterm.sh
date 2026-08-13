#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] wezterm-git"
yay -Sy --noconfirm --needed wezterm-git

echo "[CONFIG]"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ wezterm
