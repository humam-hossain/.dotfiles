set -xe

echo "[STEP] Install prerequisites"
sudo pacman -Sy --noconfirm --needed usbutils iw linux-firmware

echo "[STEP] Create usb-storage quirk for 0bda:b711"
sudo tee /etc/modprobe.d/usb-storage-quirks.conf > /dev/null <<EOF
# Prevent Realtek RTL8188GU (0bda:b711) from ever binding as a CD-ROM
options usb-storage quirks=0bda:b711:u
EOF

echo "[STEP] Rebuild initramfs (so quirk is applied early)"
sudo mkinitcpio -P

echo "[STEP] Reload modules"
# Unload usb-storage so the new quirk takes effect immediately
sudo modprobe -r usb-storage
sudo modprobe usb-storage

echo "[DONE] Plug in your adapter now (or re-plug)."
echo "Then check for your wireless interface with:  iw dev  and  ip link"

echo "[INSTALL] wpa_supplicant networkmanager"
sudo pacman -Sy --noconfirm --needed wpa_supplicant networkmanager

echo "[CONFIG] enable NetworkManager.service"
sudo systemctl enable --now NetworkManager.service

echo "[STATUS] check NetworkManager status"
systemctl status NetworkManager.service

echo "[CONFIG] connect to wifi"
nmtui

echo "[STATUS] check network connection"
ping -c3 archlinux.org
