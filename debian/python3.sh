#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] pip"
sudo apt install -y python3-pip

echo "[INSTALL] tkinter"
sudo apt install -y python3-tk
