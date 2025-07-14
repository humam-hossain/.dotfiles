set -xe

echo "[INSTALL] yazi"
sudo snap install yazi --classic

echo "[CONFIG] copying yazi config"
mkdir -p ~/.config/yazi
cp -rf .config/yazi/* ~/.config/yazi/
