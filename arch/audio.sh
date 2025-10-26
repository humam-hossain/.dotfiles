set -xe

echo "[INSTALL] audio softwares"
sudo pacman -Sy --noconfirm --needed sof-firmware pipewire pipewire-pulse pipewire-alsa pavucontrol

echo "[CONFIG] enable and start pipewire services"
systemctl --user enable --now pipewire pipewire-pulse wireplumber

echo "[VERIFY] PipeWire is up"
systemctl --user status pipewire pipewire-pulse wireplumber
pactl list short sinks
pactl list short sources
