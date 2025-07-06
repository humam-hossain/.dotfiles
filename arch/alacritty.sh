set -xe

echo "[INSTALL] alacritty"
sudo pacman -Sy --noconfirm --needed alacritty

echo "[CONFIG] alacritty"
mkdir -p ~/.config/alacritty
cp -rf ./.config/* ~/.config/alacritty/
