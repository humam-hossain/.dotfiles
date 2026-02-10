#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] pip"
sudo pacman -Sy --noconfirm --needed python-pip

echo "[INSTALL] tkinter"
sudo pacman -Sy --noconfirm --needed tk
