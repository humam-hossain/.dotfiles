set -xe

echo "[INSTALL] btop htop"
sudo pacman -Sy --noconfirm --needed btop htop
mkdir -p ~/.config/btop/
cp -rf .config/btop/* ~/.config/btop/

