set -xe

echo "[INSTALL] pip"
sudo pacman -Sy --noconfirm --needed python-pip

echo "[INSTALL] tkinter"
sudo pacman -Sy --noconfirm --needed tk
