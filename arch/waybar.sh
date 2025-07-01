set -xe

echo "[INSTALL] waybar"
sudo pacman -S --noconfirm waybar

echo "[INSTALL] jq bc"
sudo pacman -Sy --noconfirm --needed jq bc

echo "[CONFIG] waybar"
mkdir -p ~/.config/waybar
cp -rf configs/waybar/* ~/.config/waybar/