set -xe

echo "[INSTALL] yazi"
sudo pacman -Sy --noconfirm --needed yazi

echo "[CONFIG] copying yazi config"
mkdir -p ~/.config/yazi
cp -rf configs/yazi/* ~/.config/yazi/