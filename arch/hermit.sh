#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] hermit-msg"
sudo pacman -Sy --noconfirm --needed python-pipx
pipx install git+https://github.com/MuTe43/hermit.git

echo "[SETUP] hermit-msg Playwright Chromium"
# Install playwright browser inside the hermit-msg virtual environment
"$HOME/.local/share/pipx/venvs/hermit-msg/bin/python" -m playwright install chromium

echo "Done! You can now run 'hermit login fb' or 'hermit login wa'."
