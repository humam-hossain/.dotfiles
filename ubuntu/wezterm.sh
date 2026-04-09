#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] wezterm (latest .deb from GitHub releases)"
WEZTERM_VERSION=$(curl -s https://api.github.com/repos/wez/wezterm/releases/latest | grep '"tag_name"' | cut -d'"' -f4)
curl -fLO "https://github.com/wez/wezterm/releases/download/${WEZTERM_VERSION}/wezterm-${WEZTERM_VERSION}.Ubuntu22.04.deb"
sudo dpkg -i "wezterm-${WEZTERM_VERSION}.Ubuntu22.04.deb"
rm -f "wezterm-${WEZTERM_VERSION}.Ubuntu22.04.deb"

echo "[CONFIG] wezterm"
mkdir -p ~/.config/wezterm
cp -rf .config/wezterm/* ~/.config/wezterm/
