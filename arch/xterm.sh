set -xe

echo "[INFO] install xterm"
sudo pacman -Sy --noconfirm --needed xterm xorg-xrdb

echo "[INFO] copy config file"
cp .config/.Xresources $HOME
xrdb -merge ~/.Xresources
