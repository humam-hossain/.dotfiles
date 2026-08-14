#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] Core Hyprland & Wayland Protocols"
sudo pacman -Sy --noconfirm --needed hyprland hyprland-protocols

echo "[INSTALL] XDG Desktop Portals"
sudo pacman -Sy --noconfirm --needed xdg-desktop-portal-hyprland xdg-desktop-portal-wlr xdg-desktop-portal-gtk

echo "[INSTALL] Hyprland Ecosystem (Wallpaper, Lock, Idle, Screen etc.)"
sudo pacman -Sy --noconfirm --needed hyprpaper hyprshot hyprlock hyprcursor hypridle hyprpicker hyprsunset

echo "[INSTALL] Utilities & Clipboard"
sudo pacman -Sy --noconfirm --needed cliphist wl-clipboard brightnessctl ddcutil

echo "[CONFIG] Setup i2c group for ddcutil"
sudo usermod -aG i2c "$USER"

echo "[INSTALL] Notifications, Bluetooth & Casting (Swaync dependencies)"
sudo pacman -Sy --noconfirm --needed swaync blueman dnsmasq
yay -Sy --noconfirm --needed gnome-network-displays

echo "[CONFIG] Hyprland Config"
mkdir -p ~/.config/hypr
cp -rf .config/hypr/* ~/.config/hypr/

echo "[CONFIG] Graphical Session Bootstrap (systemd xdg-desktop-portal fix)"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ systemd
systemctl --user daemon-reload || true

echo "[CONFIG] Swaync Config"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow -v=5 -t ~ swaync
