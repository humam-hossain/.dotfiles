set -xe

echo "[INSTALL] unzip & tar"
sudo pacman -Sy --noconfirm --needed unzip tar

echo "[INSTALL] micro"
sudo pacman -Sy --noconfirm --needed micro

echo "[INSTALL] w3m viu"
sudo pacman -Sy --noconfirm --needed w3m viu

echo "[INSTALL] vlc"
sudo pacman -Sy --noconfirm --needed vlc

# echo "[INSTALL] gparted"
# sudo pacman -Sy --noconfirm --needed gparted

echo "[INSTALL] libre-office"
sudo pacman -Sy --noconfirm --needed libreoffice-fresh

echo "[INSTALL] fastfetch, neofetch, durdraw"
sudo pacman -Sy --noconfirm --needed fastfetch
yay -Sy --noconfirm --needed durdraw

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

echo "[INSTALL] zoom"
yay -Sy --noconfirm --needed zoom

echo "[INSTALL] taskwarrior"
sudo pacman -Sy --noconfirm --needed task

echo "[INSTALL] smartmontools"
sudo pacman -Sy --noconfirm --needed smartmontools

echo "[INSTALL] lazygit"
sudo pacman -Sy --noconfirm --needed lazygit

echo "[INSTALL] dysk (better than df)"
sudo pacman -Sy --noconfirm --needed dysk

echo "[INSTALL] webcamize"
yay -Sy --noconfirm --needed webcamize

echo "[INSTALL] disk burner caligula"
sudo pacman -Sy --noconfirm --needed caligula

echo "[INSTALL] pastel"
sudo pacman -Sy --noconfirm --needed pastel

echo "[INSTALL] wikiman"
sudo pacman -Sy --noconfirm --needed wikiman

echo "[INSTALL] feh"
sudo pacman -Sy --noconfirm --needed feh

echo "[INSTALL] memtester"
sudo pacman -Sy --noconfirm --needed memtester

echo "[INSTALL] qutebrowser"
sudo pacman -Sy --noconfirm --needed qutebrowser

echo "[INSTALL] torbrowser-launcher"
sudo pacman -Sy --noconfirm --needed torbrowser-launcher

echo "[INSTALL] distrobox"
sudo pacman -Sy --noconfirm --needed distrobox
