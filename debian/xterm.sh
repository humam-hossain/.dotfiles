#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] xterm"
sudo apt install -y xterm

echo "[CONFIG] copy config file"
cp .config/.Xresources "$HOME"
xrdb -merge ~/.Xresources
