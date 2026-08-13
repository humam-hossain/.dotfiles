#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[INSTALL] hyprland"
sudo pacman -Sy --noconfirm --needed hyprland hyprland-protocols xdg-desktop-portal-hyprland xdg-desktop-portal-wlr

echo "[INSTALL] hyprpaper hyprshot hyprlock swaync"
sudo pacman -Sy --noconfirm --needed hyprpaper hyprshot hyprlock swaync

echo "[INSTALL] ddcutil"
sudo pacman -Sy --noconfirm --needed ddcutil
sudo usermod -aG i2c $USER

echo "[INSTALL] cliphist"
sudo pacman -Sy --noconfirm --needed cliphist

echo "[CONFIG] Hyprland config"
mkdir -p ~/.config/hypr
cp -rf .config/hypr/* ~/.config/hypr/

echo "[CONFIG] graphical-session.target bootstrap (xdg-desktop-portal / screen-share fix)"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ systemd
systemctl --user daemon-reload || true

echo "[CONFIG] Swaync config"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ swaync

echo "[INSTALL] Swaync Config Dependencies"
sudo pacman -Sy --noconfirm --needed blueman xdg-desktop-portal-hyprland xdg-desktop-portal-gtk dnsmasq
yay -Sy --noconfirm --needed gnome-network-displays 

