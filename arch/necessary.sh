#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] System Base & Kernel"
sudo pacman -Sy --noconfirm --needed base base-devel linux coreutils sudo

echo "[INSTALL] Bootloader & Microcode"
sudo pacman -Sy --noconfirm --needed efibootmgr intel-ucode limine

echo "[INSTALL] Hardware, Drivers & Media (Intel & Multilib)"
# Note: sof-firmware is handled in audio.sh
sudo pacman -Sy --noconfirm --needed intel-media-driver libva-intel-driver libva-utils lib32-gnutls lib32-libglvnd lib32-mesa

echo "[INSTALL] Networking & SSH"
sudo pacman -Sy --noconfirm --needed networkmanager wpa_supplicant openssh iputils net-tools wireless-regdb

echo "[INSTALL] Disk & File Systems"
sudo pacman -Sy --noconfirm --needed dosfstools hdparm nvme-cli ntfs-3g ntfsprogs

echo "[INSTALL] Core Utilities & System Tools"
sudo pacman -Sy --noconfirm --needed stow vim fzf man-db man-pages at bc calc memtest86+-efi reflector rsync xdg-user-dirs usbmuxd

echo "[DONE] Necessary packages installed"
