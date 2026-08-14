#!/usr/bin/env bash
set -euo pipefail
set -x

# NOTE: noto-fonts, ttf-jetbrains-mono-nerd, noto-fonts-emoji, ttf-font-awesome,
# woff2-font-awesome, and ttf-material-symbols-variable are handled by dots-hyprland

echo "[INSTALL] Additional Text & Language Fonts"
sudo pacman -Sy --noconfirm --needed noto-fonts-cjk
yay -Sy --noconfirm --needed ttf-ms-fonts

echo "[INSTALL] Additional Icon & Symbol Fonts"
yay -Sy --noconfirm --needed ttf-material-symbols-variable-git

echo "[INSTALL] Icon Themes"
sudo pacman -Sy --noconfirm --needed papirus-icon-theme

echo "[SYNC] Rebuild font cache"
fc-cache -fv
