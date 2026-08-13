#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] pynvim"
# NOTE: caller must run `pacman -Syu` first; -Sy without -u is intentional here
# to avoid an unattended full-system upgrade in a targeted install script.
sudo pacman -Sy --noconfirm --needed python-pynvim fd

echo "[INSTALL] luarocks"
sudo pacman -Sy --noconfirm --needed luarocks

echo "[INSTALL] tree-sitter-cli"
sudo pacman -Sy --noconfirm --needed tree-sitter-cli

echo "[INSTALL] neovim"
sudo pacman -Sy --noconfirm --needed neovim

echo "[CONFIG] syncing .config"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ nvim
