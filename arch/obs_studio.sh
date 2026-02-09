set -xe

echo "[INSTALL] obs studio"
sudo pacman -Sy --noconfirm --needed obs-studio qt6-wayland v4l2loopback-dkms

echo "[INSTALL] phn as webcam"
yay -Sy --noconfirm --needed droidcam

echo "[CONFIG] load the kernel module so Zoom can "see" the phone as a webcam device"
sudo modprobe videodev
sudo modprobe v4l2loopback-dc
