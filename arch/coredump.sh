#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[STOW] coredump dotfiles package"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ coredump

echo "[CONFIG] System symlink for /etc/systemd/coredump.conf.d/limit.conf"
sudo mkdir -p /etc/systemd/coredump.conf.d
sudo ln -sf "$HOME/.config/systemd/coredump.conf.d/limit.conf" /etc/systemd/coredump.conf.d/limit.conf

echo "[VERIFY] systemd-coredump configuration"
systemd-analyze cat-config systemd/coredump.conf
