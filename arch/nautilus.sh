set -xe

echo "[INSTALL] nautilus"
sudo pacman -Sy --noconfirm --needed nautilus gvfs gvfs-mtp gvfs-smb gvfs-nfs tumbler ffmpegthumbnailer nwg-look

echo "[CONFIG] Force Dark Mode"
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

echo "[CONFIG] Open Terminal Here"
yay -Sy --noconfirm --needed nautilus-open-any-terminal
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal kitty
gsettings set com.github.stunkymonkey.nautilus-open-any-terminal new-tab true

echo "[CONFIG] Set as Default File Manager"
xdg-mime default org.gnome.Nautilus.desktop inode/directory

echo "[INSTALL] Themes"
yay -Sy --noconfirm --needed catppuccin-gtk-theme-mocha tela-circle-icon-theme-dracula catppuccin-cursors-mocha

nwg-look
