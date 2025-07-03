set -xe

echo "[INSTALL] unzip & tar"
sudo pacman -Sy --noconfirm --needed unzip tar

echo "[INSTALL] micro"
sudo pacman -Sy --noconfirm --needed micro

echo "[INSTALL] w3m viu"
sudo pacman -Sy --noconfirm --needed w3m viu

echo "[INSTALL] vlc"
sudo pacman -Sy --noconfirm --needed vlc

echo "[INSTALL] gparted"
sudo pacman -Sy --noconfirm --needed gparted

echo "[INSTALL] libre-office"
sudo pacman -Sy --noconfirm --needed libreoffice-fresh

echo "[INSTALL] btop"
sudo pacman -Sy --noconfirm --needed btop

echo "[INSTALL] fastfetch"
sudo pacman -Sy --noconfirm --needed fastfetch

echo "[INSTALL] curl"
sudo pacman -Sy --noconfirm --needed curl

echo "[INSTALL] wget"
sudo pacman -Sy --noconfirm --needed wget

echo "[INSTALL] docker"
sudo pacman -Sy --noconfirm --needed docker
sudo systemctl enable --now docker.service
sudo usermod -aG docker $USER

echo "[INSTALL] discord from yay"
yay -Sy --noconfirm --needed discord

echo "[INSTALL] ferdium"
yay -Sy --noconfirm --needed ferdium-bin

echo "[INSTALL] zoom"
yay -Sy --noconfirm --needed zoom

echo "[INSTALL] taskwarrior"
sudo pacman -Sy --noconfirm --needed task

echo "[INSTALL] smartmontools"
sudo pacman -Sy --noconfirm --needed smartmontools