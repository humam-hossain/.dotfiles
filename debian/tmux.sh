#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] tmux"
sudo apt install -y tmux

echo "[INSTALL] tpm"
if [ ! -d "${HOME}/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm.git "${HOME}/.tmux/plugins/tpm"
else
  echo "[SKIP] tpm already installed."
fi

echo "[CONFIG] copying config file"
cp .config/.tmux.conf ~/.tmux.conf
