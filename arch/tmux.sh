#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] tmux"
sudo pacman -Sy --noconfirm --needed tmux

echo "[INSTALL] tpm"
if [ ! -d "${HOME}/.tmux/plugins/tpm" ]; then
	git clone git@github.com:tmux-plugins/tpm.git "${HOME}/.tmux/plugins/tpm"
else
	echo "tpm already installed, skipping clone."
fi

echo "[CONFIG] copying config file"
cp -f .config/.tmux.conf ~/.tmux.conf
