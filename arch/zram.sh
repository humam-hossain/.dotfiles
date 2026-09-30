#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] zram-generator"
sudo pacman -Sy --noconfirm --needed zram-generator

echo "[STOW] zram dotfiles package"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ zram

echo "[CONFIG] System symlink for /etc/systemd/zram-generator.conf"
sudo mkdir -p /etc/systemd
sudo ln -sf "$HOME/.config/systemd/zram-generator.conf" /etc/systemd/zram-generator.conf

echo "[START] Reload systemd generator and activate zram swap"
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service dev-zram0.swap

echo "[VERIFY] zram and swap status"
zramctl
swapon --show
free -h
