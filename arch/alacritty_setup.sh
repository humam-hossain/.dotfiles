set -xe

echo "[INSTALL] alacritty"
sudo pacman -Sy --noconfirm --needed alacritty

echo "[CONFIG] alacritty"
mkdir -p ~/.config/alacritty
cp -f ./config/alacritty.yml ~/.config/alacritty/alacritty.yml
