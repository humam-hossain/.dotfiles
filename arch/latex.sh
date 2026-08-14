#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] Recommended LaTeX Packages & Fonts"
sudo pacman -Sy --noconfirm --needed texlive-latexrecommended texlive-fontsrecommended

echo "[INSTALL] Extra LaTeX Packages & Fonts"
sudo pacman -Sy --noconfirm --needed texlive-latexextra texlive-fontsextra

echo "[INSTALL] XeTeX Engine & Packages"
sudo pacman -Sy --noconfirm --needed texlive-xetex
