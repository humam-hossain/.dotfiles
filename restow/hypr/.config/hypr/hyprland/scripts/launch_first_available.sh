#!/usr/bin/env bash
# launch_first_available.sh — run the first available command from args
# Usage: launch_first_available.sh "pavucontrol-qt" "pavucontrol"
# Exits non-zero if none found on PATH.

for cmd in "$@"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        exec "$cmd"
    fi
done

echo "ERROR: none of [$*] found on PATH" >&2
exit 1
