#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] yazi"
sudo pacman -Sy --noconfirm --needed yazi

echo "[CONFIG] copying yazi config"
mkdir -p ~/.config/yazi
cp -rf .config/yazi/* ~/.config/yazi/
