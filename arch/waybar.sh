#!/usr/bin/env bash
set -euo pipefail
set -x

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WAYBAR_SRC="$REPO_ROOT/.config/waybar"
WAYBAR_DST="$HOME/.config/waybar"

PACKAGES=(
  waybar
  curl
  jq
  bc
  python
  iputils
  playerctl
  ddcutil
  pavucontrol
  networkmanager
  btop
  nautilus
  kitty
  swaync
)

MANAGED_FILES=(
  "config.jsonc"
  "style.css"
  "mocha.css"
  "scripts/alerts/earthquake.sh"
  "scripts/network/ping_status.sh"
  "scripts/system/memory.sh"
  "scripts/weather/curr_weather.sh"
  "scripts/weather/forcast_weather.sh"
  "scripts/weather/functions.sh"
)

EXECUTABLE_FILES=(
  "scripts/alerts/earthquake.sh"
  "scripts/network/ping_status.sh"
  "scripts/system/memory.sh"
  "scripts/weather/curr_weather.sh"
  "scripts/weather/forcast_weather.sh"
  "scripts/weather/functions.sh"
)

STALE_MANAGED_FILES=(
  "$WAYBAR_DST/scripts/network/ping.sh"
  "$WAYBAR_DST/analysis/server.py"
  "$WAYBAR_DST/analysis/migrate_add_target_host.py"
  "$WAYBAR_DST/analysis/migrate_csv_to_sqlite.py"
  "$WAYBAR_DST/analysis/requirements.txt"
  "$WAYBAR_DST/data/ping.config"
  "$WAYBAR_DST/data/ping_plot.html"
  "$WAYBAR_DST/data/pings.db"
  "$WAYBAR_DST/monitor/server.py"
  "$WAYBAR_DST/monitor/ping.config"
  "$WAYBAR_DST/monitor/ping_plot.html"
  "$WAYBAR_DST/monitor/requirements.txt"
  "$WAYBAR_DST/monitor/migrate_add_target_host.py"
  "$WAYBAR_DST/monitor/migrate_csv_to_sqlite.py"
  "$WAYBAR_DST/logs/ping.log"
  "$WAYBAR_DST/PRD.md"
  "$WAYBAR_DST/README.md"
)

STALE_MANAGED_DIRS=(
  "$WAYBAR_DST/analysis"
  "$WAYBAR_DST/monitor"
)

install_packages() {
  echo "[INSTALL] waybar and runtime dependencies"
  sudo pacman -Sy --noconfirm --needed "${PACKAGES[@]}"
}

ensure_dirs() {
  echo "[CONFIG] create directories"
  mkdir -p \
    "$WAYBAR_DST/scripts/alerts" \
    "$WAYBAR_DST/scripts/network" \
    "$WAYBAR_DST/scripts/system" \
    "$WAYBAR_DST/scripts/weather"
}

sync_file() {
  local rel="$1"
  local src="$WAYBAR_SRC/$rel"
  local dst="$WAYBAR_DST/$rel"
  local mode="0644"
  local exec_rel

  for exec_rel in "${EXECUTABLE_FILES[@]}"; do
    if [[ "$rel" == "$exec_rel" ]]; then
      mode="0755"
      break
    fi
  done

  install -Dm"$mode" "$src" "$dst"
}

sync_managed_files() {
  local rel

  echo "[CONFIG] sync managed waybar files"
  for rel in "${MANAGED_FILES[@]}"; do
    sync_file "$rel"
  done
}

cleanup_stale_files() {
  local path

  echo "[CLEANUP] remove stale managed files"
  for path in "${STALE_MANAGED_FILES[@]}"; do
    rm -f "$path"
  done

  echo "[CLEANUP] remove stale managed directories"
  for path in "${STALE_MANAGED_DIRS[@]}"; do
    rm -rf "$path"
  done
}

verify_file_presence() {
  local rel

  echo "[VERIFY] deployed files exist"
  for rel in "${MANAGED_FILES[@]}"; do
    [[ -f "$WAYBAR_DST/$rel" ]]
  done
  [[ -x "$WAYBAR_DST/scripts/network/ping_status.sh" ]]
}

print_summary() {
  echo "[DONE] waybar files synced and verified"
}

main() {
  install_packages
  ensure_dirs
  sync_managed_files
  cleanup_stale_files
  verify_file_presence
  print_summary
}

main "$@"
