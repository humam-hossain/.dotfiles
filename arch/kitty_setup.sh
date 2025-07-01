set -xe

echo "[INSTALL] kitty"
sudo pacman -Sy --noconfirm --needed kitty

echo "[CONFIG] kitty"
mkdir -p ~/.config/kitty
cp -rf configs/kitty/* ~/.config/kitty/