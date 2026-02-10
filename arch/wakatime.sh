#!/usr/bin/env bash
set -euo pipefail
set -x


echo "[CONFIG] wakatime api"
rm "$HOME/.wakatime.cfg" || true

read -p "Enter your WakaTime API Key: " WAKATIME_API_KEY

echo "[settings]" >> "$HOME/.wakatime.cfg"
echo "api_url=https://wakapi.dev/api" >> "$HOME/.wakatime.cfg"
echo "api_key=$WAKATIME_API_KEY" >> "$HOME/.wakatime.cfg"

echo "[VERIFY] wakatime setup"
cat $HOME/.wakatime.cfg
