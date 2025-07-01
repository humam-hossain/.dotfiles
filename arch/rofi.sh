set -xe

echo "[INSTALL] rofi"
sudo pacman -Sy --noconfirm --needed rofi

echo "[CONFIG] rofi"
mkdir -p ~/.config/rofi
cp -rf configs/rofi/* ~/.config/rofi/