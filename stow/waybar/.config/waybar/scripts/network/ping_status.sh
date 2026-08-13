#!/usr/bin/env bash
set -euo pipefail

BIND_HOST="${BIND_HOST:-127.0.0.1}"
PORT="${PORT:-8765}"
API_URL="http://${BIND_HOST}:${PORT}/api/status"
FALLBACK='{"text":"ping down","class":"dead"}'

curl_args=(
  --silent
  --show-error
  --fail
  --max-time 2
)

if [[ $# -gt 0 && -n "${1:-}" && "${1:-}" != "_" ]]; then
  curl_args+=(--get --data-urlencode "format=$1")
fi

if ! response=$(curl "${curl_args[@]}" "$API_URL" 2>/dev/null); then
  printf '%s\n' "$FALLBACK"
  exit 0
fi

if ! printf '%s' "$response" | python3 -c 'import json, sys; json.load(sys.stdin)' >/dev/null 2>&1; then
  printf '%s\n' "$FALLBACK"
  exit 0
fi

printf '%s\n' "$response"
