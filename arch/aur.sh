#!/usr/bin/env bash
set -euo pipefail
set -x

if ! command -v yay &> /dev/null; then
    echo "[DOWNLOAD] yay"
    git clone https://aur.archlinux.org/yay-bin "$HOME/yay-bin"

    echo "[INSTALL] yay"
    cd "$HOME/yay-bin"
    makepkg -si
else
    echo "[SKIP] yay is already installed."
fi

echo "[CHECK] yay version"
yay --version
