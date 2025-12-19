set -xe

echo "[INSTALL] bluetooth pkg"
sudo pacman -Sy --noconfirm --needed bluez bluez-utils blueman
