#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] Core File Manager & Virtual File Systems"
sudo pacman -Sy --noconfirm --needed nautilus gvfs gvfs-mtp gvfs-smb gvfs-nfs

echo "[INSTALL] Thumbnailers"
sudo pacman -Sy --noconfirm --needed tumbler ffmpegthumbnailer

echo "[INSTALL] GUI Customization Tool"
sudo pacman -Sy --noconfirm --needed nwg-look

echo "[INSTALL] Terminal Extension"
yay -Sy --noconfirm --needed nautilus-open-any-terminal

echo "[INSTALL] GTK & Cursor Themes"
yay -Sy --noconfirm --needed catppuccin-gtk-theme-mocha catppuccin-cursors-mocha

echo "[INSTALL] Icon Themes"
sudo pacman -Sy --noconfirm --needed tela-circle-icon-theme-black
yay -Sy --noconfirm --needed tela-circle-icon-theme-dracula papirus-folders-catppuccin-git reversal-icon-theme-git whitesur-icon-theme zafiro-icon-theme

echo "[CONFIG] Set as Default File Manager"
xdg-mime default org.gnome.Nautilus.desktop inode/directory

echo "[CONFIG] Force Dark Mode"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

echo "[CONFIG] Configure Open Terminal Here (kitty)"
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal kitty
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal new-tab true

echo "[LAUNCH] nwg-look (GUI tool to apply themes)"
nwg-look
