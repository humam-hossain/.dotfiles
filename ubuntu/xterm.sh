set -xe

echo "[INFO] install xterm"
sudo apt install xterm

echo "[INFO] copy config file"
cp .config/.Xresources $HOME
xrdb -merge ~/.Xresources
