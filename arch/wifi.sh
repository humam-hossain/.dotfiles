#!/usr/bin/env bash
set -euo pipefail
set -x



echo "[STEP] Install prerequisites"
sudo pacman -Sy --noconfirm --needed usbutils iw linux-firmware usb_modeswitch

echo "[STEP] Create udev rule for Realtek RTL8188GU (auto modeswitch)"
sudo tee /etc/udev/rules.d/90-realtek-rtl8188gu.rules > /dev/null <<'EOF'
# Automatically switch Realtek 0bda:1a2b (fake CD-ROM mode) into WiFi adapter mode (0bda:b711)
ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="1a2b", \
RUN+="/usr/sbin/usb_modeswitch -v 0bda -p 1a2b -R && logger 'Realtek RTL8188GU: switched to WiFi mode'"
EOF

echo "[STEP] Reload udev rules"
sudo udevadm control --reload
sudo udevadm trigger

echo "[STEP] Ensure WiFi driver module is loaded"
sudo modprobe rtl8xxxu || echo "rtl8xxxu driver not found — ensure kernel supports it."

echo "[STEP] Install and enable NetworkManager"
sudo pacman -Sy --noconfirm --needed wpa_supplicant networkmanager
sudo systemctl enable --now NetworkManager.service

echo "[STATUS] Check NetworkManager status"
sleep 5 # Give NetworkManager a moment to start up
systemctl --no-pager --full status NetworkManager.service || true

echo "[STEP] Verify WiFi interface"
iw dev || echo "No wireless interface found yet — replug the adapter if needed."

echo "[INFO] Use 'nmtui' or 'nmcli' to connect to WiFi"
echo "[INFO] Example: sudo nmtui"

echo "[STEP] Test network connection"
ping -c3 archlinux.org || echo "Ping failed — connect to WiFi and retry."

echo "[DONE] Setup complete."
echo "Check dmesg for:  Realtek RTL8188GU: switched to WiFi mode"

