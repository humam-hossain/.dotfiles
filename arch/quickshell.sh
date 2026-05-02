#!/usr/bin/env bash
set -euo pipefail

# arch/quickshell.sh — Install Quickshell + ddcutil + i2c-tools, configure i2c, symlink config.
# Pattern: mirrors arch/waybar.sh (REPO_ROOT, PACKAGES array, main dispatcher, [LABEL] echos).
# Divergence from waybar.sh: uses a single directory symlink instead of per-file copies (D-17).

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
QS_SRC="$REPO_ROOT/.config/quickshell"
QS_DST="$HOME/.config/quickshell"

PACKAGES=(
  quickshell
  ddcutil
  i2c-tools
)

install_packages() {
  echo "[INSTALL] quickshell and runtime dependencies (${PACKAGES[*]})"
  sudo pacman -Sy --noconfirm --needed "${PACKAGES[@]}"
}

setup_i2c() {
  echo "[CONFIG] i2c kernel module and group membership"
  sudo modprobe i2c-dev
  sudo usermod -aG i2c "$USER"
  echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c.conf > /dev/null
  echo "[CONFIG] /etc/modules-load.d/i2c.conf written (i2c-dev will load on every boot)"
}

symlink_config() {
  echo "[CONFIG] symlink $QS_DST -> $QS_SRC"
  mkdir -p "$(dirname "$QS_DST")"
  rm -rf "$QS_DST"
  ln -s "$QS_SRC" "$QS_DST"
}

verify_install() {
  echo "[VERIFY] checking install state"
  command -v quickshell >/dev/null || { echo "[VERIFY] FAIL: quickshell not in PATH"; exit 1; }
  command -v ddcutil    >/dev/null || { echo "[VERIFY] FAIL: ddcutil not in PATH";    exit 1; }
  test -L "$QS_DST"                 || { echo "[VERIFY] FAIL: $QS_DST is not a symlink"; exit 1; }
  test -f "$QS_DST/shell.qml"       || { echo "[VERIFY] FAIL: $QS_DST/shell.qml not reachable through symlink"; exit 1; }
  test -f /etc/modules-load.d/i2c.conf || { echo "[VERIFY] FAIL: /etc/modules-load.d/i2c.conf missing"; exit 1; }
  echo "[VERIFY] OK"
}

print_summary() {
  echo "[DONE] Quickshell installed and configured."
  echo "[DONE] Run \`quickshell\` from a terminal to launch the bar (Hyprland exec-once is intentionally not modified in Phase 12)."
  echo ""
  echo "Log out and back in for i2c group to take effect (required for ddcutil)"
}

main() {
  install_packages
  setup_i2c
  symlink_config
  verify_install
  print_summary
}

main "$@"
