set -xe

echo "[INSTALL] waybar"
sudo pacman -S --noconfirm waybar

echo "[INSTALL] jq bc"
sudo pacman -Sy --noconfirm --needed jq bc

echo "[CONFIG] waybar"
mkdir -p ~/.config/waybar
cp -rf .config/waybar/* ~/.config/waybar/

echo "[SETUP] plotting setup"
pushd ~/.config/waybar/
python3 -m venv .venv
pip3 install -r requirements.txt
popd
