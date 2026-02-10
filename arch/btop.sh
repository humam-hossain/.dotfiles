#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] btop htop"
sudo pacman -Sy --noconfirm --needed btop htop
mkdir -p ~/.config/btop/
cp -rf .config/btop/* ~/.config/btop/

