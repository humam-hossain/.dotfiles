#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] pynvim"
sudo apt install -y python3-pynvim

echo "[INSTALL] luarocks"
sudo apt install -y luarocks

echo "[INSTALL] tree-sitter-cli"
sudo apt install -y tree-sitter-cli

echo "[INSTALL] neovim (latest tarball from GitHub releases)"
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
tar -xzf nvim-linux-x86_64.tar.gz
sudo mv nvim-linux-x86_64 /opt/nvim
sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
rm nvim-linux-x86_64.tar.gz

echo "[CONFIG] copying .config"
mkdir -p ~/.config/nvim/
cp -rf .config/nvim/* ~/.config/nvim/
