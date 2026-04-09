#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] font awesome"
sudo apt install -y fonts-font-awesome

echo "[INSTALL] fonts"
sudo apt install -y fonts-dejavu fonts-liberation fonts-freefont-ttf fonts-noto-core fonts-noto-color-emoji

echo "[INSTALL] papirus-icon-theme"
sudo apt install -y papirus-icon-theme

echo "[INSTALL] JetBrains Mono Nerd Font (manual download)"
mkdir -p "${HOME}/.local/share/fonts"
wget -O /tmp/JetBrainsMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
unzip /tmp/JetBrainsMono.zip -d "${HOME}/.local/share/fonts/"
rm -f /tmp/JetBrainsMono.zip

echo "[SYNC] rebuild font cache"
fc-cache -fv
