set -xe

echo "[DOWNLOAD] yay"
git clone https://aur.archlinux.org/yay-bin $HOME/yay-bin

echo "[INSTALL] yay"
cd ~/yay-bin
makepkg -si

echo "[CHECK] yay version"
yay --version
