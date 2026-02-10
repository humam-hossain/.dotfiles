#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] vscode"
yay -Sy --noconfirm --needed visual-studio-code-bin

echo "[INSTALL] vscode login libraries"
sudo pacman -Sy --noconfirm --needed gnome-keyring libsecret
