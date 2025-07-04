set -xe

echo "[INSTALL] hyprland"
sudo pacman -Sy --noconfirm --needed hyprland

echo "[INSTALL] hyprpaper hyprshot hyprlock swaync"
sudo pacman -Sy --noconfirm --needed hyprpaper hyprshot hyprlock swaync

echo "[INSTALL] ddcutil"
sudo pacman -Sy --noconfirm --needed ddcutil
sudo usermod -aG i2c $USER

echo "[INSTALL] cliphist"
sudo pacman -Sy --noconfirm --needed cliphist

echo "[CONFIG] Hyprland config"
mkdir -p ~/.config/hypr
cp -rf configs/hypr/* ~/.config/hypr/

