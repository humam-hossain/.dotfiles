#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] Python Core & Package Managers"
sudo pacman -Sy --noconfirm --needed python python-pip python-pipx

echo "[INSTALL] Python UI & Visualization Tools (Tkinter, Tensorboard)"
sudo pacman -Sy --noconfirm --needed tk tensorboard
