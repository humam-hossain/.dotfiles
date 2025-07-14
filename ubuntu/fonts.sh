set -xe

echo "[INSTALL] font awesome"
sudo apt install -y fonts-font-awesome 

echo "[INSTALL] noto fonts"
sudo apt install -y fonts-noto-core fonts-noto-color-emoji

echo "[INSTALL] papirus-icon-theme"
sudo apt install -y papirus-icon-theme

echo "[INSTALL] JetBrains Mono Nerd Font (manual)"
mkdir -p "${HOME}/.local/share/fonts"
wget "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
unzip JetBrainsMono.zip -d "${HOME}/.local/share/fonts/"
rm -rf JetBrainsMono.zip

echo "[SYNC] rebuild font cache"
fc-cache -fv

