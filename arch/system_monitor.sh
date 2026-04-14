#!/usr/bin/env bash
set -euo pipefail
set -x

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MONITOR_SRC="$REPO_ROOT/.config/system_monitor/ping"
MONITOR_DST="$HOME/.config/system_monitor/ping"
BIND_HOST="${BIND_HOST:-127.0.0.1}"
PORT="${PORT:-8765}"

PACKAGES=(
  docker
  docker-compose
  curl
)

MANAGED_FILES=(
  "server.py"
  "ping.config"
  "ping_plot.html"
  "requirements.txt"
  "migrate_add_target_host.py"
  "migrate_csv_to_sqlite.py"
  "Dockerfile"
  "docker-compose.yml"
  ".env"
)

install_packages() {
  echo "[INSTALL] ping-viz runtime dependencies"
  sudo pacman -Sy --noconfirm --needed "${PACKAGES[@]}"
}

ensure_dirs() {
  echo "[CONFIG] create directories"
  mkdir -p "$MONITOR_DST/data"
}

sync_managed_files() {
  local f

  echo "[CONFIG] sync managed ping-viz files"
  for f in "${MANAGED_FILES[@]}"; do
    install -Dm0644 "$MONITOR_SRC/$f" "$MONITOR_DST/$f"
  done
}

start_service() {
  echo "[CONFIG] enable docker and start ping-viz container"
  sudo systemctl enable --now docker
  cd "$MONITOR_DST"
  BIND_HOST="$BIND_HOST" PORT="$PORT" docker compose up -d --build --force-recreate
}

verify() {
  local status_json
  local attempt

  echo "[VERIFY] container is running"
  cd "$MONITOR_DST"
  docker compose ps | grep -q "running\|Up"

  echo "[VERIFY] status endpoint responds"
  status_json=""
  for attempt in {1..10}; do
    if status_json="$(curl --silent --show-error --fail --max-time 5 http://${BIND_HOST}:${PORT}/api/status 2>/dev/null)"; then
      break
    fi
    sleep 1
  done
  [[ -n "$status_json" ]]
  printf '%s' "$status_json" | python3 -c 'import json, sys; d=json.load(sys.stdin); assert "text" in d and "class" in d, f"missing keys: {d}"'

  echo "[VERIFY] today endpoint responds"
  curl --silent --fail --max-time 5 http://${BIND_HOST}:${PORT}/api/today \
    | python3 -c 'import json, sys; d=json.load(sys.stdin); assert "bars" in d, f"missing bars: {d}"'

  echo "[VERIFY] web UI served"
  curl --silent --fail --max-time 5 http://${BIND_HOST}:${PORT}/ | grep -q "<html\|<!DOCTYPE"

  echo "[VERIFY] ping.config accessible inside container"
  cd "$MONITOR_DST"
  docker compose exec -T ping-viz cat /app/ping.config > /dev/null

  echo "[VERIFY] waybar fetcher returns valid JSON"
  local fetcher="$HOME/.config/waybar/scripts/network/ping_status.sh"
  if [[ -x "$fetcher" ]]; then
    BIND_HOST="$BIND_HOST" PORT="$PORT" "$fetcher" | python3 -c 'import json, sys; json.load(sys.stdin)'
  else
    echo "[SKIP] waybar fetcher not deployed — run arch/waybar.sh first"
  fi
}

print_summary() {
  echo "[DONE] ping-viz running via Docker at http://${BIND_HOST}:${PORT}/"
}

main() {
  install_packages
  ensure_dirs
  sync_managed_files
  start_service
  verify
  print_summary
}

main "$@"
