#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[INSTALL] Core Audio (Pipewire, Firmware, Session Manager)"
sudo pacman -Sy --noconfirm --needed sof-firmware pipewire pipewire-pulse pipewire-alsa wireplumber

echo "[INSTALL] Multilib Audio Support (32-bit)"
sudo pacman -Sy --noconfirm --needed lib32-alsa-lib lib32-alsa-plugins lib32-libpulse lib32-pipewire

echo "[INSTALL] Media Control & GUI"
sudo pacman -Sy --noconfirm --needed pavucontrol playerctl

echo "[INSTALL] Text-to-Speech (TTS) Engines"
sudo pacman -Sy --noconfirm --needed espeak-ng festival festival-english

echo "[INSTALL] MIDI Support & SoundFonts"
sudo pacman -Sy --noconfirm --needed timidity++ soundfont-fluid

echo "[CONFIG] enable and start pipewire services"
systemctl --user enable --now pipewire pipewire-pulse wireplumber

echo "[VERIFY] PipeWire is up"
systemctl --user status pipewire pipewire-pulse wireplumber
pactl list short sinks
pactl list short sources
