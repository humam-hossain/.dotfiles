#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] bluetooth pkg"
sudo pacman -Sy --noconfirm --needed bluez bluez-utils blueman

echo "[CONFIG] Enabling and starting bluetooth service"
sudo systemctl enable --now bluetooth

echo "[VERIFY] Bluetooth service status"
sudo systemctl status bluetooth
