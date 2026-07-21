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

# ii / Quickshell chrome icons are Material Symbols font glyphs (MaterialSymbol.qml),
# not PNG assets — without this package bar icons render as missing/empty boxes.
echo "[INSTALL] material symbols (Quickshell ii icon font)"
sudo pacman -Sy --noconfirm --needed ttf-material-symbols-variable

echo "[SYNC] rebuild font cache"
fc-cache -fv

