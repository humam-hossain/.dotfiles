#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] font awesome"
sudo pacman -Sy --noconfirm --needed ttf-font-awesome

echo "[INSTALL] jetbrains mono nerd font"
sudo pacman -Sy --noconfirm --needed ttf-jetbrains-mono-nerd

echo "[INSTALL] noto fonts"
sudo pacman -Sy --noconfirm --needed noto-fonts

echo "[INSTALL] papirus-icon-theme"
sudo pacman -Sy --noconfirm --needed papirus-icon-theme

echo "[INSTALL] noto-fonts-emoji"
sudo pacman -Sy --noconfirm --needed noto-fonts-emoji

echo "[SYNC] rebuild font cache"
fc-cache -fv

