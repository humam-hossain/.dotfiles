#!/usr/bin/env bash
set -xeuo pipefail

# 0. Update package lists
echo "[SYNC] Updating package lists"
sudo apt update

# 1. Install core CLI tools, fonts & utilities
echo "[INSTALL] Core packages"
sudo apt install -y \
  btop \
  htop \
  unzip \
  tar \
  micro \
  w3m \
  vlc \
  gparted \
  neofetch \
  durdraw \
  curl \
  wget \
  taskwarrior \
  smartmontools \
  memtester \
  feh \
  qutebrowser \
  torbrowser-launcher \
  zathura \

# 2. Copy btop config
echo "[CONFIG] Copying btop config"
mkdir -p "${HOME}/.config/btop"
cp -rf .config/btop/* "${HOME}/.config/btop/"

# 4. Install “Discord” and “Zoom” via Snap
echo "[INSTALL] Socials: Whatsie, caprine, telegram, Discord & Zoom via snap"
sudo snap install discord
sudo snap install zoom-client --classic
sudo snap install caprine
sudo snap install whatsie
sudo snap install telegram-desktop

echo "[DONE] All packages installed!"

