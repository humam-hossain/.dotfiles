#!/usr/bin/env bash
set -euo pipefail
set -x
echo "[INSTALL] necessary packages"
sudo apt install -y git efibootmgr fzf build-essential curl
echo "[DONE]"
