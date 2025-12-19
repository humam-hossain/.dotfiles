set -xe

echo "[INSTALL] waybar"
sudo pacman -S --noconfirm waybar

echo "[INSTALL] jq bc"
sudo pacman -Sy --noconfirm --needed jq bc
yay -Sy --noconfirm --needed smem

echo "[CONFIG] waybar"
mkdir -p ~/.config/waybar
cp -rf .config/waybar/* ~/.config/waybar/
