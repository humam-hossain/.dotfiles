#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] node"
sudo apt install -y nodejs npm

echo "[INSTALL] gemini"
sudo npm install -g @google/gemini-cli
