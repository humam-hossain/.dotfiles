#!/usr/bin/env bash
set -euo pipefail
set -x

echo "[CONFIG] wakatime api"
rm -f "$HOME/.wakatime.cfg"
echo "[settings]" >> "$HOME/.wakatime.cfg"
echo "api_url=https://wakapi.dev/api" >> "$HOME/.wakatime.cfg"
echo "api_key=REDACTED" >> "$HOME/.wakatime.cfg"

echo "[VERIFY] wakatime setup"
cat "$HOME/.wakatime.cfg"
