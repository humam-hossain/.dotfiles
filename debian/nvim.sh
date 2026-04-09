#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] pynvim"
sudo apt install -y python3-pynvim

echo "[INSTALL] luarocks"
sudo apt install -y luarocks

echo "[INSTALL] tree-sitter-cli"
sudo apt install -y tree-sitter-cli

echo "[INSTALL] neovim (via snap)"
sudo snap install nvim --classic

echo "[CONFIG] copying .config"
mkdir -p ~/.config/nvim/
cp -rf .config/nvim/* ~/.config/nvim/
