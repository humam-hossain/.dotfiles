#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] vulkan packages"
sudo pacman -Sy --noconfirm --needed lib32-vulkan-intel vulkan-intel vulkan-tools
