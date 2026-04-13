#!/usr/bin/env bash
set -euo pipefail
set -x

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WAYBAR_SRC="$REPO_ROOT/.config/waybar"
WAYBAR_DST="$HOME/.config/waybar"
SYSTEMD_SRC="$REPO_ROOT/.config/systemd/user/ping-viz.service"
SYSTEMD_DST="$HOME/.config/systemd/user/ping-viz.service"

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
  "monitor/server.py"
  "monitor/migrate_add_target_host.py"
  "monitor/migrate_csv_to_sqlite.py"
  "monitor/requirements.txt"
  "monitor/ping.config"
  "monitor/ping_plot.html"
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
)

install_packages() {
  echo "[INSTALL] waybar and runtime dependencies"
  sudo pacman -Sy --noconfirm --needed "${PACKAGES[@]}"
}

ensure_dirs() {
  echo "[CONFIG] create directories"
  mkdir -p \
    "$WAYBAR_DST/monitor" \
    "$WAYBAR_DST/data" \
    "$WAYBAR_DST/logs" \
    "$WAYBAR_DST/scripts/alerts" \
    "$WAYBAR_DST/scripts/network" \
    "$WAYBAR_DST/scripts/system" \
    "$WAYBAR_DST/scripts/weather" \
    "$HOME/.config/systemd/user"
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

  echo "[CONFIG] sync ping-viz systemd unit"
  install -Dm0644 "$SYSTEMD_SRC" "$SYSTEMD_DST"
}

cleanup_stale_files() {
  local path

  echo "[CLEANUP] remove stale managed files"
  for path in "${STALE_MANAGED_FILES[@]}"; do
    rm -f "$path"
  done
}

restart_ping_viz() {
  echo "[CONFIG] enable and restart ping-viz"
  systemctl --user daemon-reload
  systemctl --user enable --now ping-viz
  systemctl --user restart ping-viz
}

verify_file_presence() {
  local rel

  echo "[VERIFY] deployed files exist"
  for rel in "${MANAGED_FILES[@]}"; do
    [[ -f "$WAYBAR_DST/$rel" ]]
  done
  [[ -f "$SYSTEMD_DST" ]]
  [[ -x "$WAYBAR_DST/scripts/network/ping_status.sh" ]]
}

verify_ping_viz() {
  local status_json
  local attempt

  echo "[VERIFY] ping-viz is active"
  systemctl --user is-active --quiet ping-viz

  echo "[VERIFY] status endpoint responds"
  status_json=""
  for attempt in {1..10}; do
    if status_json="$(curl --silent --show-error --fail --max-time 5 http://127.0.0.1:8765/api/status 2>/dev/null)"; then
      break
    fi
    sleep 1
  done
  [[ -n "$status_json" ]]
  printf '%s' "$status_json" | python3 -c 'import json, sys; json.load(sys.stdin)'
}

print_summary() {
  echo "[DONE] waybar files synced, ping-viz restarted, verification passed"
}

main() {
  install_packages
  ensure_dirs
  sync_managed_files
  cleanup_stale_files
  restart_ping_viz
  verify_file_presence
  verify_ping_viz
  print_summary
}

main "$@"
