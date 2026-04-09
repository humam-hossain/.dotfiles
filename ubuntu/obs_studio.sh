#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] obs studio"
sudo add-apt-repository -y ppa:obsproject/obs-studio
sudo apt update
sudo apt install -y obs-studio v4l2loopback-dkms

echo "[INSTALL] droidcam (phone as webcam)"
cd /tmp
wget -O droidcam_latest.zip https://files.dev47apps.net/linux/droidcam_2.1.3.zip
unzip droidcam_latest.zip -d droidcam
cd droidcam
sudo ./install-client
cd /tmp && rm -rf droidcam droidcam_latest.zip

echo "[CONFIG] load kernel modules so Zoom/OBS can see the phone as a webcam"
sudo modprobe videodev
sudo modprobe v4l2loopback
