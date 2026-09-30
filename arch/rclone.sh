#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[CHECK] Required packages"
MISSING_PKGS=()
for pkg in rclone fuse3 libnotify; do
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
    echo "[INSTALL] Installing missing packages: ${MISSING_PKGS[*]}"
    sudo pacman -Sy --noconfirm --needed "${MISSING_PKGS[@]}"
else
    echo "[CHECK] All required packages (rclone, fuse3, libnotify) already installed."
fi

echo "[STOW] Checking existing unlinked files"
if [[ -f "$HOME/.config/systemd/user/rclone@.service" && ! -L "$HOME/.config/systemd/user/rclone@.service" ]]; then
    echo "[BACKUP] Moving real file aside per stow procedure"
    mv "$HOME/.config/systemd/user/rclone@.service" "$HOME/.config/systemd/user/rclone@.service.aside"
fi

echo "[STOW] Stowing rclone package into ~"
cd "$(dirname "${BASH_SOURCE[0]}")/../stow" && stow --verbose=5 --no-folding -t ~ rclone

echo "[VERIFY] Verifying live symlinks"
test -L "$HOME/.config/systemd/user/rclone@.service"
test -L "$HOME/.config/systemd/user/rclone-notify-failure@.service"
test -L "$HOME/.local/bin/rclone-notify-failure"
test -L "$HOME/.local/bin/rclone-restart-all"

if [[ -f "$HOME/.config/systemd/user/rclone@.service.aside" ]]; then
    rm "$HOME/.config/systemd/user/rclone@.service.aside"
fi

echo "[SYSTEMD] Reloading systemd user units"
systemctl --user daemon-reload

echo "[STATUS] Checking rclone user services"
systemctl --user list-units 'rclone*' --all || true
