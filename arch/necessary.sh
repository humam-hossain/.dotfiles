set -xe
echo "[INSTALL] necessary packages"
sudo pacman -Syu --needed --noconfirm base-devel nano networkmanager intel-ucode sof-firmware efibootmgr fzf man-db man-pages openssh wpa_supplicant
echo "[DONE]"
