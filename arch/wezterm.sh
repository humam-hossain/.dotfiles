set -xe

echo "[INSTALL] wezterm-git"
yay -Sy --noconfirm --needed wezterm-git

echo "[CONFIG]"
mkdir -p ~/.config/wezterm
cp -rf .config/wezterm/* ~/.config/wezterm/
