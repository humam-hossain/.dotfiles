set -xe

echo "[INSTALL] font awesome"
sudo apt install -y fonts-font-awesome 

echo "[INSTALL] fonts"
sudo apt install -y fonts-dejavu fonts-liberation fonts-cmu fonts-freefont-ttf fonts-noto-core fonts-noto-color-emoji texlive-fonts-extra

echo "[INSTALL] papirus-icon-theme"
sudo apt install -y papirus-icon-theme

echo "[INSTALL] microsoft fonts"
sudo add-apt-repository multiverse
sudo apt update -y
sudo apt install -y ttf-mscorefonts-installer fontconfig

echo "[INSTALL] JetBrains Mono Nerd Font (manual)"
mkdir -p "${HOME}/.local/share/fonts"
wget "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
unzip JetBrainsMono.zip -d "${HOME}/.local/share/fonts/"
rm -rf *.zip

echo "[SYNC] rebuild font cache"
fc-cache -fv

