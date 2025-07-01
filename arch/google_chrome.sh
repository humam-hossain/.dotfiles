set -xe

echo "[INSTALL] google-chrome-stable"
yay -Sy --noconfirm --needed google-chrome

echo "[CHECK] version"
google-chrome-stable --version

echo "[INSTALL] libraries to set default browser"
sudo pacman -Sy --noconfirm --needed xdg-utils xdg-desktop-portal xdg-desktop-portal-hyprland

echo "[CONFIG] set default browser"
xdg-settings set default-web-browser google-chrome-stable.desktop
xdg-mime default google-chrome-stable.desktop x-scheme-handler/http
xdg-mime default google-chrome-stable.desktop x-scheme-handler/https

echo "[VERIFY] default browser"
xdg-settings get default-web-browser
xdg-mime query default x-scheme-handler/http
xdg-mime query default x-scheme-handler/https
