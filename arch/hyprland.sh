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

echo "[CONFIG] Swaync config"
mkdir -p ~/.config/swaync
cp -rf .config/swaync/* ~/.config/swaync/

echo "[INSTALL] Swaync Config Dependencies"
sudo pacman -Sy --noconfirm --needed blueman xdg-desktop-portal-hyprland xdg-desktop-portal-gtk dnsmasq
yay -Sy --noconfirm --needed gnome-network-displays 

