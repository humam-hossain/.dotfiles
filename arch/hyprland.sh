#!/usr/bin/env bash
set -euo pipefail
set -x

# Resolved once, at the top, so that every path below is absolute and the
# script behaves identically however it was invoked. The two stow stanzas
# below each change directory; resolving the expression at the point of use
# would evaluate the second one from the directory the first had already
# moved to, which aborts the run under `set -e` after the package operations
# above have already mutated the system. This is the same idiom arch/waybar.sh
# already uses.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

# Hyprland configuration placement is deliberately absent here. Phase 20,
# requirement HYPR-01, owns it: once a stow package for the Hyprland
# configuration exists, its invocation belongs at exactly this point in the
# script. What stood here before was a recursive, forced copy of the
# repository's own pre-adopt configuration tree over the live session tree,
# which the Phase 14 adopt had deliberately moved away from; it also resolved
# its source only when the script happened to run from the repository root.

echo "[CONFIG] Graphical Session Bootstrap (systemd xdg-desktop-portal fix)"
cd "$REPO_ROOT/stow" && stow --verbose=5 --no-folding -t ~ systemd
systemctl --user daemon-reload || true
systemctl --user enable --now dotfiles-capture.timer || true
systemctl --user restart dotfiles-capture.timer || true

echo "[CONFIG] Swaync Config"
cd "$REPO_ROOT/stow" && stow --verbose=5 --no-folding -t ~ swaync
