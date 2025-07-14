set -xe

echo "[INSTALL] kitty"
sudo apt install -y kitty

echo "[CONFIG] kitty"
mkdir -p ~/.config/kitty
cp -rf .config/kitty/* ~/.config/kitty/
