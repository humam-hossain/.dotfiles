set -xe

echo "[DOWNLOAD] yay"
git clone https://aur.archlinux.org/yay-bin -d $HOME

echo "[INSTALL] yay"
cd ~/yay-bin
makepkg -si

echo "[CHECK] yay version"
yay --version
