set -xe

echo "[INSTALL] kitty"
sudo pacman -Sy --noconfirm --needed kitty

echo "[CONFIG] kitty"
mkdir -p ~/.config/kitty
cp -rf .config/kitty/* ~/.config/kitty/
