set -xe

echo "[INSTALL] rofi"
sudo apt install -y rofi

echo "[CONFIG] rofi"
mkdir -p ~/.config/rofi
cp -rf .config/rofi/* ~/.config/rofi/
