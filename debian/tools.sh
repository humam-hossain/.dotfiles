#!/usr/bin/env bash
set -euo pipefail
set -x

# 0. Update package lists
echo "[SYNC] Updating package lists"
sudo apt update

# 1. Install core CLI tools & utilities (apt)
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
  curl \
  wget \
  taskwarrior \
  smartmontools \
  memtester \
  feh \
  qutebrowser \
  torbrowser-launcher \
  zathura \
  libreoffice \
  distrobox

# 2. fastfetch (via snap — no PPA on Debian)
echo "[INSTALL] fastfetch"
sudo snap install fastfetch

# 3. lazygit (via snap — no PPA on Debian)
echo "[INSTALL] lazygit"
sudo snap install lazygit --classic

# 4. Rust-based tools (cargo)
echo "[INSTALL] Rust-based tools via cargo"
cargo install viu
cargo install dysk
cargo install pastel
cargo install caligula

# 5. Copy btop config
echo "[CONFIG] Copying btop config"
mkdir -p "${HOME}/.config/btop"
cp -rf .config/btop/* "${HOME}/.config/btop/"

# 6. Install socials via snap
echo "[INSTALL] Socials via snap"
sudo snap install discord
sudo snap install zoom-client --classic
sudo snap install caprine
sudo snap install whatsie
sudo snap install telegram-desktop

# NOTE: wikiman — not available via apt/snap/cargo. Install manually:
#   https://github.com/filipdutescu/wikiman/releases
# NOTE: webcamize — AUR only. No Debian/Ubuntu equivalent available.

echo "[DONE] All packages installed!"
