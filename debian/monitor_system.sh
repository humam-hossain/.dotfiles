#!/usr/bin/env bash
set -euo pipefail
set -x

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WAYBAR_SRC="$REPO_ROOT/.config/waybar"
WAYBAR_DST="$HOME/.config/waybar"
SYSTEMD_SRC="$REPO_ROOT/.config/systemd/user/ping-viz.service"
SYSTEMD_DST="$HOME/.config/systemd/user/ping-viz.service"

PACKAGES=(
  curl
  jq
  bc
  python3
  python3-pip
  iputils-ping
)

MANAGED_FILES=(
  "monitor/server.py"
  "monitor/migrate_add_target_host.py"
  "monitor/migrate_csv_to_sqlite.py"
  "monitor/requirements.txt"
  "monitor/ping.config"
  "monitor/ping_plot.html"
  "scripts/network/ping_status.sh"
)

EXECUTABLE_FILES=(
  "scripts/network/ping_status.sh"
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
  echo "[INSTALL] ping-viz runtime dependencies"
  sudo apt install -y "${PACKAGES[@]}"
}

ensure_dirs() {
  echo "[CONFIG] create directories"
  mkdir -p \
    "$WAYBAR_DST/monitor" \
    "$WAYBAR_DST/data" \
    "$WAYBAR_DST/logs" \
    "$WAYBAR_DST/scripts/network" \
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

  echo "[CONFIG] sync managed ping-viz files"
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
  echo "[DONE] ping-viz files synced, service restarted, verification passed"
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
